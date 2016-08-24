# Stampery

## Installation

  1. Add stampery to your list of dependencies in mix.exs:

        def deps do
          [{:stampery, github: "stampery/elixir"}]
        endgithub:

  2. Ensure stampery is started before your application:

        def application do
          [applications: [:stampery]]
        end


# Usage

```elixir
require Stampery

Stampery.init "2d4cdee7-38b0-4a66-da87-c1ab05b43768"

Stampery.on :ready , fn _ ->
    digest = Stampery.hash "Hello, blockchain!"
    Stampery.stamp digest
end
Stampery.on :error, fn err -> IO.puts err end
Stampery.on :proof, fn [hash, proof] ->
    IO.puts "\nReceived proof for \n#{hash} \n\nProof"
    IO.inspect proof
end

Stampery.start

```


# Official implementations
- [NodeJS](https://github.com/stampery/node)
- [PHP](https://github.com/stampery/php)
- [Ruby](https://github.com/stampery/ruby)
- [Python](https://github.com/stampery/python)
- [Elixir](https://github.com/stampery/elixir)

# Feedback

Ping us at support@stampery.com and we’ll help you! 😃


## License

Code released under
[the MIT license](https://github.com/stampery/js/blob/master/LICENSE).

Copyright 2016 Stampery
