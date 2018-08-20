# Joseph KATSIOLOUDES (jk2714), Ben Sheng TAN(bst15)

defmodule Scout do
    
def start(config) do
    IO.puts ["          Starting scout ", DAC.node_ip_addr()]
    receive do
        {:bind, leader, acceptors, ballot_new} -> 
            for a <- acceptors, do: send a, {:p1a, self(), ballot_new}
            next(config, leader, acceptors, ballot_new, MapSet.new, acceptors) # 2nd occurence of 'acceptors' is to become the 'waitfor' list.
    end
end # start
    
def next(config, leader, acceptors, ballot_new, pvalues, waitfor) do
    receive do
        {:p1b, acceptor, ballot_rec, accepted} -> 
            if elem(ballot_rec, 0) == elem(ballot_new, 0) do 
                MapSet.put(pvalues, accepted)
                n_waitfor = waitfor -- [acceptor]
                if Enum.count(n_waitfor) < Enum.count(acceptors)/2 do
                    send leader, {:adopted, ballot_rec, pvalues}
                    Process.exit(self(), "End of scout responsibility")
                end
                next(config, leader, acceptors, ballot_new, pvalues, n_waitfor)
            else
                send leader, {:preempted, ballot_rec}
                Process.exit(self(), "End of scout responsibility")
            end    
    end
end # next
    
end # Scout