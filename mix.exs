defmodule Stampery.Mixfile do
  use Mix.Project

  def project do
    [app: :stampery,
     version: "0.0.1",
     elixir: "~> 1.1-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
        mod: {Example, []},
        applications: [:logger, :sha3, :msgpack_rpc]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
        # {:amqp, "~> 0.1.4"},
        {:sha3, "~> 1.0.0", override: true, compile: "make"},
        # msgpackrpc was overriding proper in msgpack so I had to include proper here to fix it
        {:proper, ~r/.*/, [env: :prod, git: "git://github.com/manopapad/proper.git", branch: "master", manager: :rebar, override: true]},
        {:msgpack_rpc, github: "stampery/msgpack-rpc-erlang", tag: "fix/latest-otp"}
    ]
  end
end
