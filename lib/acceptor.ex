# Joseph KATSIOLOUDES (jk2714), Ben Sheng TAN(bst15)

defmodule Acceptor do

def start(config) do
    IO.puts ["          Starting acceptor ", DAC.node_ip_addr()]
    next(config, -1, MapSet.new)
end # start

def next(config, ballot_num, accepted) do
    receive do
        {:p1a, scout, ballot_new} ->
            n_ballot = if elem(ballot_new, 0) > ballot_num, do: ballot_new, else: ballot_num
            send scout, {:p1b, self(), n_ballot, accepted}
            next(config, n_ballot, accepted)

        {:p2a, commander, {b, s, c}} ->
            if b == ballot_num do
                MapSet.put(accepted, {b, s, c})
            end
            send commander, {:p2b, self(), ballot_num}
            next(config, ballot_num, accepted)
    end
end # next

end # Acceptor
