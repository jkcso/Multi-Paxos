
# distributed algorithms, n.dulay 2 feb 17 
# coursework 2, paxos made moderately complex

defmodule Paxos do

def main do 
  config = DAC.get_config
  if config.debug_level >= 2, do: IO.inspect config
  if config.setup == :docker, do: Process.sleep config.docker_delay
  start config
end

defp start config do
  monitor = spawn Monitor, :start, [config] 
  for s <- 1 .. config.n_servers do 
    node_name = DAC.node_name config.setup, "server", s	
    DAC.node_spawn node_name, Server, :start, [config, s, self(), monitor] 
  end

  server_components = 
    for _ <- 1 .. config.n_servers do 
      receive do { :config, r, a, l } -> { r, a, l } end 
    end

  { replicas, acceptors, leaders } = DAC.unzip3 server_components

  for replica <- replicas, do: send replica, { :bind, leaders }
  for leader  <- leaders,  do: send leader,  { :bind, acceptors, replicas }

  for c <- 1 .. config.n_clients do 
    node_name = DAC.node_name config.setup, "client", c 	
    DAC.node_spawn node_name, Client, :start, [config, c, replicas] 
  end

end # start

end # Paxos

