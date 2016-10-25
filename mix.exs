defmodule Stampery.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [app: :stampery,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     docs: [source_ref: "v#{@version}", main: "readme", extras: ["README.md"]],
     deps: deps]
  end

  def application do
    [applications: [:logger, :sha3, :msgpack_rpc, :amqp]]
  end

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev},
     {:amqp, "~> 0.1.5"},
     {:sha3, "~> 2.0.0"},
     {:merkle, "~> 0.2.0"},
     {:proper, ~r/.*/, [env: :prod, git: "git://github.com/manopapad/proper.git", branch: "master", manager: :rebar, override: true]},
     {:msgpack_rpc, github: "stampery/msgpack-rpc-erlang", tag: "fix/latest-otp"}]
  end

  defp description do
    """
    Elixir client library for Stampery API: the blockchain-powered, industrial-scale certification platform.
    """
  end

  defp package do
    [maintainers: ["Johann Ortiz", "Adán Sánchez de Pedro"],
     licenses: ["MIT"],
     links: %{"Stampery" => "https://stampery.com/api",
              "API signup" => "https://api-dashboard.stampery.com/signup",
              "GitHub" => "https://github.com/stampery/elixir"}]
  end
end
