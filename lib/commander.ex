defmodule Commander do

    def start(config) do
    # To enable better debugging with fewer output on screen    
    # IO.puts ["          Starting commander ", DAC.node_ip_addr()]
    receive do
        {:bind, leader, acceptors, replicas, pvalue} -> 
            for a <- acceptors, do: send a, {:p2a, self(), pvalue}
            next(config, leader, acceptors, replicas, pvalue, acceptors)
    end
end # start

def next(config, leader, acceptors, replicas, pvalue, waitfor) do
    receive do
        {:p2b, acceptor, ballot_num} ->

            if ballot_num == elem(pvalue, 0) do
                n_waitfor = waitfor -- [acceptor]
                if Enum.count(n_waitfor) < Enum.count(acceptors)/2 do
                    for r <- replicas, do: send r, {:decision, elem(pvalue, 1), elem(pvalue, 2)}
                    Process.exit(self(), "End of commander responsibility")
                end
                next(config, leader, acceptors, replicas, pvalue, n_waitfor)
            else
                send leader, {:preempted, ballot_num}
                Process.exit(self(), "End of commander responsibility")
            end
    end
end # next

end # Commander
