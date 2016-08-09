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
