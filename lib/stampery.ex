defmodule Stampery do
    require Logger

    defp start_link do
        Agent.start_link(fn -> %{} end, name: :ENV)
    end

    def on event_type, callback do
        put_element event_type, callback
    end

    defp emit event_type, args \\ [] do
        callback = get_element event_type
        if is_function callback do
            callback.(args)
        else
            IO.puts "#{event_type} not a callback"
        end
    end

    def init secret, branch \\ :prod do
        start_link
        put_element :branch, branch
        put_element :client_secret, secret
        put_element :client_id, :crypto.hash(:md5, secret) |> Base.encode16 |> String.slice(0..14) |> String.downcase
    end

    def start do
        branch = get_element :branch
        api_login (if branch == :prod, do: ["api.stampery.com" , 4000], else: ["api-beta.stampery.com" ,4000])
        amqp_login (if branch == :prod, do: "amqp://consumer:9FBln3UxOgwgLZtYvResNXE7@young-squirrel.rmq.cloudamqp.com/ukgmnhoi",
                                    else: "amqp://consumer:9FBln3UxOgwgLZtYvResNXE7@young-squirrel.rmq.cloudamqp.com/beta")
    end

    def hash data do
        :sha3.hexhash(512, data)
    end

    def stamp data do
        IO.puts "\nStamping \n#{data}"
        case :msgpack_rpc_client.call(get_element(:msg_pack_pid), :"stamp", [String.upcase(data)]) do
            {:ok, _} -> :ok
            {:error, err} -> emit :error, err
        end
    end

    defp api_login end_point do
        [host , port] = end_point
        client_id = get_element(:client_id)
        {:ok, pid} = :msgpack_rpc_client.connect(:tcp, String.to_atom(host), port, [])
        {:ok, call_id} = :msgpack_rpc_client.call_async(pid, :'stampery.3.auth', [client_id, get_element(:client_secret)])
        {:ok, auth} = :msgpack_rpc_client.join(pid, call_id)
        put_element :auth , auth
        put_element :msg_pack_pid , pid
        IO.puts "logged #{client_id}"
    end

    defp amqp_login host do
        {:ok, connection} = AMQP.Connection.open host
        IO.puts "[QUEUE] Connected to Rabbit!"
        {:ok, channel} = AMQP.Channel.open(connection)
        emit :ready
        client = get_element(:client_id) <> "-clnt"
        AMQP.Basic.consume(channel, client, nil, no_ack: true)
        handle_queue_consuming_for_hash channel
    end

    defp handle_queue_consuming_for_hash channel do
        receive do
          {:basic_deliver, payload, meta} ->
            routing_key = meta[:routing_key]
            {proof, _} = :msgpack.unpack_stream(payload)
            emit :proof, [routing_key, proof]
            handle_queue_consuming_for_hash(channel)
        end
    end

    defp get_element(key) do
        Agent.get(:ENV, &Map.get(&1, key))
    end

    defp put_element(key, value) do
        Agent.update(:ENV, &Map.put(&1, key, value))
    end

end
