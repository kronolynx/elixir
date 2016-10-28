# Stampery
Elixir client library for [Stampery API](https://stampery.com/api), the blockchain-powered, industrial-scale certification platform.

Seamlessly integrate industrial-scale data certification into your own Elixir apps. The Stampery API adds a layer of transparency, attribution, accountability and auditability to your applications by connecting them to Stampery's infinitely scalable [Blockchain Timestamping Architecture](https://stampery.com/tech).

## Installation

  1. Add stampery to your list of dependencies in mix.exs:

        def deps do
          [{:stampery, "~> 0.2.0"}]
        end

## Usage

```elixir
defmodule Mymodule do
  # Sign up and get your secret token at https://api-dashboard.stampery.com
  use Stampery, {"user-secret", :prod}
  require Logger

  def on_ready do
    "Hello, blockchain!"
    |> hash
    |> stamp
  end

  def on_proof(proof) do
    Logger.debug "Proof #{inspect proof}"
  end
end

Mymodule.start()
```


## Client libraries for other platforms
- [NodeJS](https://github.com/stampery/node)
- [PHP](https://github.com/stampery/php)
- [Ruby](https://github.com/stampery/ruby)
- [Python](https://github.com/stampery/python)
- [Java](https://github.com/stampery/java)
- [Go](https://github.com/stampery/go)

## Feedback

Ping us at [support@stampery.com](mailto:support@stampery.com) and we will more than happy to help you! 😃


## License

Code released under
[the MIT license](https://github.com/stampery/js/blob/master/LICENSE).

Copyright 2016 Stampery, Inc.
