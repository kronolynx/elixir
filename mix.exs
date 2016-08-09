defmodule Stampery.Mixfile do
  use Mix.Project

  def project do
    [app: :stampery,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :sha3, :msgpack_rpc, :amqp]]
  end

  defp deps do
    [
        {:amqp, "~> 0.1.4"},
        {:sha3, "~> 1.0.0", override: true, compile: "make"},
        # msgpackrpc was overriding msgpack proper so I had to override it again to disambiguate
        {:proper, ~r/.*/, [env: :prod, git: "git://github.com/manopapad/proper.git", branch: "master", manager: :rebar, override: true]},
        {:msgpack_rpc, github: "stampery/msgpack-rpc-erlang", tag: "fix/latest-otp"}
    ]
  end

  defp description do
    """
    Stampery API for Elixir. Notarize all your data using the blockchain! 
    """
  end

  defp package do
    [maintainer: ["Johann Ortiz"],
     links: %{"Stampery" => "https://stampery.com",
              "GitHub" => "https://github.com/stampery/elixir"}]
  end
end
