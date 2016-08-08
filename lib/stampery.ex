defmodule Stampery do
    require Logger

    defp start_link do
        Agent.start_link(fn -> %{} end, name: :ENV)
    end
    

    def init secret, branch \\ :prod do
        start_link
        put_element :branch, branch
        put_element :client_secret, secret
        put_element :client_id, :crypto.hash(:md5, secret) |> Base.encode16 |> String.slice(0..15) |> String.downcase
    end


    def start do
        branch = get_element :branch
        api_login (if branch == :prod, do: "api.stampery.com:4000", else: "api-beta.stampery.com:4000")
        amqp_login (if branch == :prod, do: "amqp://consumer:9FBln3UxOgwgLZtYvResNXE7@young-squirrel.rmq.cloudamqp.com/ukgmnhoi",
                                    else: "amqp://consumer:9FBln3UxOgwgLZtYvResNXE7@young-squirrel.rmq.cloudamqp.com/beta")
        emit :double, 5
    end



    defp get_element(key) do
        Agent.get(:ENV, &Map.get(&1, key))
    end

    defp put_element(key, value) do
        Agent.update(:ENV, &Map.put(&1, key, value))
    end

end
