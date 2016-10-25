defmodule Stampery do
  @moduledoc """
  Behaviour implementing communication with Stampery API.
  """
  require Logger

  defmodule Proof do
    @moduledoc """
    Proof interface
    """
    defstruct [:version, :hash, :siblings, :root, :anchor]

    defmodule Anchor do
      @moduledoc """
      Anchor interface
      """
      defstruct [:chain, :tx_id]
    end
  end

  defmodule Tree do
    use Merkle, {&Merkle.Mixers.Bin.commutable_sha3_512/2, 64}
  end

  @endpoints %{
    prod: {:"api.stampery.com", 4000},
    beta: {:"api-beta.stampery.com", 4000}
  }
  @queues %{
    prod: "9FBln3UxOgwgLZtYvResNXE7@young-squirrel.rmq.cloudamqp.com/ukgmnhoi",
    beta: "9FBln3UxOgwgLZtYvResNXE7@young-squirrel.rmq.cloudamqp.com/beta"
  }

  @type error :: {:error, String.t}
  @type proof :: %Stampery.Proof{
    version: Integer.t,
    hash: String.t,
    siblings: [String.t],
    root: String.t,
    anchor: %Stampery.Proof.Anchor{
      chain: Integer.t,
      tx_id: String.t
    }
  }

  @doc """
  Tells your module that everything is ready to start stamping.
  """
  @callback on_ready() :: any

  @doc """
  Tells your module that something wrong happened.
  """
  @callback on_error(error) :: any
  @doc """

  Tells your module that there is a new proof ready.
  """
  @callback on_proof(proof) :: any

  @doc """
  This macro provides methods and callbacks for interacting with the Stampery API.
  """
  defmacro __using__(params) do
    quote do
      @behaviour Stampery
      @params unquote params
      require Logger

      @spec on_ready() :: any
      def on_ready() do
        Logger.info "[Stampery] API is ready"
      end

      @spec on_error(Stampery.error) :: any
      def on_error(error) do
        Logger.error "[Stampery] #{inspect error}"
      end

      @spec on_proof(Stampery.proof) :: any
      def on_proof(proof) do
        Logger.info "[Stampery] Received proof: \n#{inspect proof}"
      end

      def hash(data) do
        Stampery.hash(data)
      end

      def stamp(data) do
        Stampery.stamp(data, __MODULE__)
      end

      def start() do
        Stampery.start(@params, __MODULE__)
      end

      def prove(proof) do
        Stampery.prove(proof)
      end

      defoverridable [on_ready: 0, on_proof: 1, on_error: 1]
    end
  end

  @doc """
  Sends a callback to the user module that is using the macro.
  """
  @spec call_back(Module.t, Atom.t, List.t) :: {:ok, any} | error
  def call_back(mod, fun, args) do
    try do
      apply(mod, fun, args)
    catch
      :throw, val ->
        {:ok, val}
      :error, val ->
        Logger.error val
        {:error, {val, System.stacktrace}}
      :exit, val  ->
        {:error, val}
    else
      res -> {:ok, res}
    end
  end

  @doc """
  Start connection to API and Rabbit.
  """
  @spec start({String.t, Atom.t}, Module.t) :: any
  def start({secret, branch}, mod) do
    Agent.start_link(fn -> %{} end, name: mod)

    api = @endpoints
      |> Map.get(branch)
      |> api_login(secret)
    rabbit = if {:ok, _} = api do @queues
      |> Map.get(branch)
      |> rabbit_login(secret, mod)
    else
      {:error, "API Login error"}
    end

    if {{:ok, pid}, {:ok, chan}} = {api, rabbit} do
      Agent.update(mod, fn (_)-> %{pid: pid, chan: chan} end)
      call_back(mod, :on_ready, [])
    else
      call_back(mod, :on_error, [%{api: api, rabbit: rabbit}])
    end
  end

  @doc """
  Calculates the SHA-3 (FIPS-202) hash of the input data and returns a
  hexadecimal digest.
  """
  @spec hash(String.t) :: String.t
  def hash(data) do
    Logger.info "[Stampery] Hashing #{inspect data}"
    :sha3.hexhash(512, data)
  end

  @doc """
  Sends a hexadecimal hash digest to the API backend for stamping.
  """
  @spec stamp(String.t, Module.t) :: :ok | error
  def stamp(data, mod) do
    Logger.info "[Stampery] Stamping #{inspect data}"
    res = with pid <- Agent.get(mod, &Map.get(&1, :pid)),
         data <- String.upcase(data),
         res <- :msgpack_rpc_client.call(pid, :stamp, [data]),
    do: res
    case res do
      {:ok, true} ->
        :ok
      error ->
        call_back(mod, :on_error, [error])
        error
    end
  end

  @doc false
  @spec api_login({Atom.t, Integer.t}, String.t) :: {:ok, PID.t} | error
  defp api_login({host, port}, secret) do
    client_id = derive_client(secret)
    with {:ok, pid} <- :msgpack_rpc_client.connect(:tcp, host, port, []),
         {:ok, call_id} <- :msgpack_rpc_client.call_async(
          pid, :"stampery.3.auth", [client_id, secret]
         ),
         {:ok, auth} <- :msgpack_rpc_client.join(pid, call_id),
    do: auth && {:ok, pid}
  end

  @doc false
  @spec rabbit_login(String.t, String.t, Module.t) :: {:ok, any} | error
  defp rabbit_login(host, secret, mod) do
    host = "amqp://consumer:" <> host
    client_q = derive_client(secret) <> "-clnt"
    with {:ok, conn} <- AMQP.Connection.open(host),
         {:ok, chan} <- AMQP.Channel.open(conn),
         Stampery.RabbitConsumer.start_link({chan, client_q, mod}),
    do: {:ok, chan}
  end

  defp derive_client(secret) do
    :md5
    |> :crypto.hash(secret)
    |> Base.encode16
    |> String.slice(0..14)
    |> String.downcase
  end

  @doc """
  Verify a proof and therefore prove its validity and the integrity of the
  original data.
  """
  @spec prove(proof) :: :ok | error
  def prove(proof) do
    case Tree.prove(proof.hash, proof.siblings, proof.root) do
      :error -> {:error, 'Invalid proof'}
      :ok -> :ok
    end
  end

  @moduledoc """
  Rabbit consumer for receiving proofs asynchronously
  """
  defmodule RabbitConsumer do
    use GenServer
    use AMQP
    require Logger

    def start_link({chan, q, mod}) do
      GenServer.start_link(__MODULE__, {chan, q, mod}, [])
    end

    def init({chan, q, mod}) do
      Basic.consume(chan, q)
      {:ok, {chan, q, mod}}
    end

    def handle_info({:basic_consume_ok, _meta}, state) do
      {:noreply, state}
    end

    def handle_info({:basic_deliver, payload, meta}, {chan, q, mod}) do
      spawn fn -> consume(chan, payload, meta, mod) end
      {:noreply, {chan, q, mod}}
    end

    def consume(chan, payload, meta, mod) do
      {hash, [v, sib, root, [chain, tx_id]]} = with hash <- meta[:routing_key],
         {proof, _} <- :msgpack.unpack_stream(payload),
         do: {hash, proof}
      proof = %Stampery.Proof{
        version: v,
        hash: hash,
        siblings: if sib == "" do [] else sib end,
        root: root,
        anchor: %Stampery.Proof.Anchor{
          chain: chain,
          tx_id: tx_id
        }
      }
      Basic.ack(chan, meta[:delivery_tag])
      Stampery.call_back(mod, :on_proof, [proof])
    end
  end

end
