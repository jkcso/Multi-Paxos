# Joseph KATSIOLOUDES (jk2714), Ben Sheng TAN(bst15)

defmodule Replica do

def start(config, database, monitor) do
    IO.puts ["          Starting replica ", DAC.node_ip_addr()]
    receive do
        {:bind, leaders} ->
            next(config, leaders, 1, 1, 1, MapSet.new, MapSet.new, MapSet.new, database, monitor)
    end
end # start

def next(config, leaders, state, slotIn, slotOut, reqs, proposals, decisions, database, monitor) do
    receive do
        { :client_request, c } ->
            n_reqs = MapSet.put reqs, c
            n_decisions = MapSet.to_list decisions
            reqsList = MapSet.to_list n_reqs
            proposalsList = MapSet.to_list proposals
            propose config, leaders, state, slotIn, slotOut, reqsList, proposalsList, n_decisions, database, monitor
        { :decision, s, c } ->
            decisionsSet = MapSet.put decisions, {s,c}
            n_decisions = MapSet.to_list decisionsSet
            reqsList = MapSet.to_list reqs
            proposalsList = MapSet.to_list proposals
            decisionsList = for {sOc, c2} <- n_decisions, do: {sOc == slotOut, c2}
            {n_proposals, n_reqs, n_slotOut, n_state} = decide n_decisions, proposalsList, reqsList, slotOut, state, decisionsList, database, monitor
            propose config, leaders, n_state, slotIn, n_slotOut, n_reqs, n_proposals, n_decisions, database, monitor
    end # receive
end # next

def propose config, leaders, state, slotIn, slotOut, [], proposals, decisions, database, monitor do
    decisionsSet = MapSet.new decisions
  proposalsSet =  MapSet.new proposals
  reqsSet =  MapSet.new
  next config, leaders, state, slotIn, slotOut, reqsSet, proposalsSet, decisionsSet, database, monitor
end #propose

def propose config, leaders, state, slotIn, slotOut, [c | t], proposals, decisions, database, monitor do
  window_size = 5
  if slotIn < slotOut + window_size do
    if Enum.member?(decisions, slotIn) do
      n_slotIn = slotIn + 1
      propose config, leaders, state, n_slotIn, slotOut, [c | t], proposals, decisions, database, monitor
    else
      proposalsSet = MapSet.new proposals
      proposalsT = MapSet.put proposalsSet, {slotIn, c}
      n_proposals = MapSet.new proposalsT
      for l <- leaders, do: send l,  { :propose, slotIn, c }
      n_slotIn = slotIn + 1
      propose config, leaders, state, n_slotIn, slotOut, t, n_proposals, decisions, database, monitor
    end #if
  else
    decisionsSet = MapSet.new decisions
    proposalsSet =  MapSet.new proposals
    reqsSet =  MapSet.new [c | t]
    next config, leaders, state, slotIn, slotOut, reqsSet, proposalsSet, decisionsSet, database, monitor
  end #if
end #propose

# ------- helper function --------------

def decide([], proposals, reqs, slotOut, state, _, _, _), do: {proposals, reqs, slotOut, state}

def decide [{_, c2} | t], proposals, reqs, slotOut, state, decisions, database, monitor do
  if Enum.member?(proposals, slotOut) do
      filtered_check = Enum.filter(proposals, fn({sO2, _}) -> sO2 == slotOut end )
      checked = for f <- filtered_check, do: List.delete(proposals, f)
      {sO2, c3} = List.last(checked)
      proposalsSet =  MapSet.new proposals
      proposalsT = MapSet.delete {sO2, c3}, proposalsSet
      n_proposals = MapSet.to_list proposalsT
      if c2 != c3 do
        reqsSet = MapSet.new reqs
        reqsT = MapSet.put reqsSet, c3
        n_reqs = MapSet.to_list reqsT
        perform c2, t, n_proposals, n_reqs, slotOut, state, decisions, database, monitor
      else
        perform c2, t, n_proposals, reqs, slotOut, state, decisions, database, monitor
      end #if
  else
      perform c2, t, proposals, reqs, slotOut, state, decisions, database, monitor
  end #if
end #decide

def perform {k, cid, op}, t, proposals, reqs, slotOut, state, decisions, database, monitor do
    filtered_cond = Enum.filter(decisions, fn({s, {k2, cid2, op2}}) -> s < slotOut and k == k2 and cid == cid2 and op == op2 end )
    cond = for f <- filtered_cond, do: List.delete(decisions, f)
  if cond != [] do
    n_slotOut = slotOut + 1
    decide t, proposals, reqs, n_slotOut, state, decisions, database, monitor
  else
    if elem(op, 0) == :move do
      n_state = state + 1
      n_slotOut = slotOut + 1
      send database, { :execute, op }
      send monitor, { :client_request, cid }
      send k, { :reply, cid, :ok }
      decide t, proposals, reqs, n_slotOut, n_state, decisions, database, monitor
    else
      decide t, proposals, reqs, slotOut, state, decisions, database, monitor
    end #if
  end #if
end #perform
    
def check(condSet, slotOut, s, k, k2, cid, cid2, op, op2) do
    if s < slotOut and k == k2 and cid == cid2 and op == op2 do 
        MapSet.put condSet, {s, { k2, cid2, op2}}
    end
end # check

end # Replica
