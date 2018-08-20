# Joseph KATSIOLOUDES (jk2714), Ben Sheng TAN(bst15)

defmodule Leader do

def start(config) do
    IO.puts ["          Starting leader ", DAC.node_ip_addr()]
    receive do
        {:bind, acceptors, replicas} -> 
            scout = spawn Scout, :start, [config]
            send scout, {:bind, self(), acceptors, {0, self()}}            
            next(config, acceptors, replicas, {0, self()}, false, []) 
    end
end # start
    
def next(config, acceptors, replicas, {bnum, bself}, active, proposals) do    
    receive do
        { :propose, s, c } ->
            if Enum.empty?(proposals) do   
                n_proposals = proposals ++ [{ s, c }]
                if active do
                    commander = spawn Commander, :start, [config]
                    send commander, {:bind, self(), acceptors, replicas, {{bnum, bself}, s, c}}
                end
                next config, acceptors, replicas, {bnum, bself}, active, n_proposals
                    
            else
                for { sp, _ } <- proposals do
                    if s == sp do
                        next(config, acceptors, replicas, {bnum, bself}, active, proposals)
                    else
                        n_proposals = proposals ++ [{ s, c }]
                        if active do
                            commander = spawn Commander, :start, [config]
                            send commander, {:bind, self(), acceptors, replicas, {{bnum, bself}, s, c}}                                            
                        end
                        next config, acceptors, replicas, {bnum, bself}, active, n_proposals
                    end
                end # for
                    
            end # if
                    
        { :adopted, {bnum, bself}, pvals } ->
            if pvals != [] do
                slots = for {{_, _}, slots, _} <- pvals, do: slots
                slotmax = pmax slots, pvals, []    
                sub_proposals = update slotmax, proposals
                n_proposals = sub_proposals ++ slotmax
            else
                n_proposals = proposals
            end # if
            
            for {s,c} <- n_proposals do
                commander = spawn Commander, :start, [config]
                send commander, {:bind, self(), acceptors, replicas, {{bnum, bself}, s, c}}                                            
            end
            next config, acceptors, replicas, {bnum, bself}, true, n_proposals
        
        { :preempted, { r, v }} ->
            if { r, v } > { bnum, bself } do
                n_active = false
                {n_bnum, n_bself} = { bnum + 1, bself }
                spawn Scout, :start, [config, self(), acceptors, { n_bnum, n_bself}]
                next config, acceptors, replicas, { n_bnum, n_bself}, n_active, proposals
            else
                next config, acceptors, replicas, { bnum, bself }, active, proposals
            end # if
    end # receive
end # next
    
    
# ------- helper function --------------

def pmax([], _, max), do: max

def pmax([s | t], pvals, slotsmax) do
  sub_pvals = for {{ bip, bis }, st, ct} <- pvals, do: {{ bip, bis}, s == st, ct}
  { {_, _}, ss, cc } = Enum.max(sub_pvals)
  n_slotsmax = slotsmax ++ [{ss, cc}]
  pmax t, pvals, n_slotsmax
end # pmax

def update([], proposals), do: proposals

def update([{s, _} | t ], proposals) do
  n_proposals = for {sp, cp} <- proposals, do: { sp != s , cp}
  update t, n_proposals
end # update    
    
end # Leader