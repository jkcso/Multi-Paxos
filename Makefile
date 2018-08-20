
# distributed algorithms, n.dulay, 1 feb 18
# coursework 2, paxos made moderately complex
# Makefile, v2

SERVERS = 3
CLIENTS = 2

CONFIG  = 1

# ----------------------------------------------------------------------

MAIN         = Paxos.main
SINGLE_SETUP = single
DOCKER_SETUP = docker
SSH_SETUP    = ssh

PROJECT     = da347
NETWORK     = $(PROJECT)_network

# run all clients, servers and top-level component in a single node
SINGLE	 = mix run --no-halt -e $(MAIN) $(CONFIG) $(SINGLE_SETUP) $(SERVERS) $(CLIENTS)

# run each client, server and top-level component in its own Docker container
GEN_YML	 = ./gen_yml.sh $(MAIN) $(CONFIG) $(DOCKER_SETUP) $(SERVERS) $(CLIENTS)
DOCKER   = docker-compose -p $(PROJECT)

# run each client, server and top-level component on real hosts via ssh
SSH      = MAIN=$(MAIN) CONFIG=$(CONFIG) SETUP=$(SSH_SETUP) SERVERS=$(SERVERS) CLIENTS=$(CLIENTS) ./ssh.sh

compile:
	mix compile

clean:
	mix clean

run:
	$(SINGLE)
	@echo ----------------------

gen:
	$(GEN_YML)

up:
	@make gen
	$(DOCKER) up

down:
	$(DOCKER) down
	make show

ssh_up:
	$(SSH) up

ssh_down:
	$(SSH) down

ssh_show:
	$(SSH) show

show:
	@echo ----------------------
	@make ps
	@echo ----------------------
	@make network

show2:
	@echo ----------------------
	@make ps2
	@echo ----------------------
	@make network

ps:
	docker ps -a --format 'table {{.Names}}\t{{.Image}}'

ps2:
	docker ps -a -s

network net:
	docker network ls

inspect:
	docker network inspect $(NETWORK)

netrm:
	docker network rm $(NETWORK)
conrm:
	docker rm $(ID)

kill:
	docker rm -f `docker ps -a -q`
	docker network rm $(NETWORK)
