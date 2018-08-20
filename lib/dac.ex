
# distributed algorithms, n.dulay, 25 jan 18
# helper functions v2

defmodule DAC do

# ---------------------
def node_ip_addr do
  {:ok, interfaces} = :inet.getif()		# get interfaces
  {address, _gateway, _mask}  = hd interfaces	# get data for 1st interface
  {a, b, c, d} = address   			# get octets for address
  "#{a}.#{b}.#{c}.#{d}"
end

def lookup name do
  addresses = :inet_res.lookup name, :in, :a 
  {a, b, c, d} = hd addresses   # get octets for 1st ipv4 address
  :"#{a}.#{b}.#{c}.#{d}"
end

# ---------------------
def node_name(:single,  _,   _), do: node() 	# return local elixir node
def node_name(:docker, name, n), do: :'#{name}#{n}@#{name}#{n}.localdomain'
def node_name(:ssh, _, _n),      do: System.halt 1  # omitted

def node_spawn node, module, function, args do
  if Node.connect node do
    Process.sleep 5   	# in case Node needs time to load modules
    Node.spawn node, module, function, args
  else 
    Process.sleep 100	# retry in 100ms
    node_spawn node, module, function, args 
  end
end

# ---------------------
def random(n),            do: Enum.random 1..n
def random_seed(n),       do: :rand.seed(:exsplus, {n, n, n})
def random_seed(a, b, c), do: :rand.seed(:exsplus, {a, b, c})
def adler32(x),           do: :erlang.adler32(x)
def unzip3(triples),	  do: :lists.unzip3 triples

# ---------------------

def get_config do
  # get version of configuration given by 1st arg
  config = Configuration.version String.to_integer(Enum.at System.argv, 0)

  # add type of setup (single | docker | ssh)
  config = Map.put config, :setup, :'#{Enum.at System.argv, 1}'

  # add no. of servers and clients 
  config = Map.put config, :n_servers, String.to_integer(Enum.at System.argv, 2)
  config = Map.put config, :n_clients, String.to_integer(Enum.at System.argv, 3) 

  config
end

end # module -----------------------




