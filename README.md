# MultiPaxos

## Paxos
Paxos is a family of protocols for solving consensus in a network of unreliable processors. Consensus is the process of agreeing on one result among a group of participants. This problem becomes difficult when the participants or their communication medium may experience failures.

Consensus protocols are the basis for the state machine replication approach to distributed computing, as suggested by Leslie Lamport and surveyed by Fred Schneider.  State machine replication is a technique for converting an algorithm into a fault-tolerant, distributed implementation. Ad-hoc techniques may leave important cases of failures unresolved.  The principled approach proposed by Lamport et al. ensures all cases are handled safely.

The Paxos protocol was first published in 1989 and named after a fictional legislative consensus system used on the Paxos island in Greece. It was later published as a journal article in 1998.

The Paxos family of protocols includes a spectrum of trade-offs between the number of processors, number of message delays before learning the agreed value, the activity level of individual participants, number of messages sent, and types of failures.  Although no deterministic fault-tolerant consensus protocol can guarantee progress in an asynchronous network (a result proved in a paper by Fischer, Lynch and Paterson), Paxos guarantees safety (consistency), and the conditions that could prevent it from making progress are difficult to provoke.

Paxos is usually used where durability is required (for example, to replicate a file or a database), in which the amount of durable state could be large.  The protocol attempts to make progress even during periods when some bounded number of replicas are unresponsive.  There is also a mechanism to drop a permanently failed replica or to add a new replica.

Source: https://en.wikipedia.org/wiki/Paxos_(computer_science)

## MultiPaxos

### How to make sure the log is the same on all the nodes?  
The solution is to run basic-Paxos for every log entry (plus add some tweaks to solve some issues and improve performance).  First we need to identify for which log entry we’re choosing a value. Our first tweak is therefore to add a log-entry number to every propose and accept messages.  And that leads directly to our first problem:

### How to figure out which log entry to use?
Simply each server keeps an index of smallest available log entry number (entry with no chosen value) and try to propose the new value for this slot. It keeps proposing the same value on increasing entry number until the value is chosen.  Servers can handle multiple client requests simultaneously (for different log entries). However updating the state machine is sequential (because all the preceding commands must be applied before applying a new one).  Now that the biggest problem is solved in theory, it may not work well in practice because of contention – several servers propose different values for the same log entry. Choosing a value requires at least 2-phases and possibly more in case multiple values are proposed.  The next tweak aims at improving the performance by resorbing the contention:

### Pick a Leader

Let’s assume that we pick a leader and that this leader is the only one who can send “propose” requests.  It means that the leader accepts client requests and acts both as a  proposer and as an acceptor.  The other servers can’t propose values so they redirect clients to the leader and act as acceptors only.

### How to pick one?

One simple strategy is to use the server ids to determine who the leader is. Simply the leader is the server with highest id.  That means that each server needs to know the ids of the other servers. For this purpose each server sends heartbeat messages every T ms.  If  a server doesn’t receive any message with a higher id than its own for a long enough period (2 x T ms) then it becomes the leader.  This is probably the most simple strategy but other strategies are more efficient for that matter (e.g. leased-based approach).  With this strategy there might be 2 leaders in the system at the same time. This is still ok as Paxos supports it (with a little lack of efficiency).

### Replication of chosen values on all the servers

Remember that with basic-Paxos only the proposer (in this case the leader) knows about chosen values.  To improve replication the leader simply keeps sending “accepts” requests in the background until all servers respond. As the request are sent in the background it doesn’t influence the response-time to the clients. However it doesn’t ensure full replication either. (e.g. if leader crashes before full replication).

For that each server needs to track “chosen” entries. Each server marks the entries known to be chosen with an “acceptedProposal” value equals infinity. (This kind of makes sense because Paxos always keeps “acceptedProposal” with the greatest value – basically it just a way to say that this value won’t be overwritten).  Each server also maintains a “firstUnchosenIndex” to track the lowest log entry which value is not known to be chosen (i.e. a log entry with “acceptedProposal” != infinity).

The proposer (i.e. the leader) tells the other servers about its “firstUnchoosenIndex” in every “accept” request. The proposer is the only one to know when a value is chosen. Embedding its “firstUnchosenIndex” allows the acceptors to know which entries have already been chosen.  On the acceptor side when it receives an accept message, it checks if it has any past log entries older than the received “firstUnchosenIndex” with a proposal number matching the proposal number in the request. In this case it can mark these entries as accepted (i.e. set accepted proposal to infinity).

Paxos learning chosen valuesStill might be some not chosen values from previous leader in the acceptor log entries.  To solve this problem acceptors include their firstUnchosenIndex in the accept replies. When the proposer receives a reply with firstUnchosenIndex older than its own firstUnchosenIndex it sends a “Success” message containing the log entry and the chosen value.

It allows the acceptor to record the chosen value for this log entry. So it marks this log entry as chosen (acceptProposal = infinity) and update its firstUnchosenValue and it includes it in the response. (It allows the leader to send another Success message if needed).  Now our log is fully replicated (and so is the state machine). So let’s focus on the interaction with the client.

Source: https://www.beyondthelines.net/algorithm/multi-paxos/ 

## Compile and Run Options

`make compile	- compile`

`make clean	- remove compiled code`

`make run	- run in single node`

`make run SERVERS=n CLIENTS=m CONFIG=p
                - run with different numbers of servers, clients and 
                - version of configuration file, arguments are optional`

`make up		- make gen, then run in a docker network`

`make up SERVERS=<n> CLIENTS=<m> CONFIG=<p>`

`make gen	- generate docker-compose.yml file`

`make down	- bring down docker network`

`make kill	- use instead of make down or if make down fails`

`make show	- list docker containers and networks`

`make ssh_up	- run on real hosts via ssh (omitted)`

`make ssh_down	- kill nodes on real network (omitted)`

`make ssh_show	- show running nodes on real network (omitted)`
