#!/bin/bash

# distributed algorithms, n.dulay 25 jan 18
# coursework 2, create docker-compose.yml file

MAIN=$1
CONFIG=$2
SETUP=$3
SERVERS=$4
CLIENTS=$5

FILE=docker-compose.yml

# ----------------------------------------------------------
cat > $FILE << ENDHEADER

# distributed algorithms, n.dulay, 2 feb 18
# coursework 2 - paxos made moderately complex

# docker-compose.yml v1  

version: "3.4"

x-common:
  &defaults
    image: elixir:alpine
    volumes:
      - .:/project
    working_dir: /project
    networks:
      - network

networks:
  network:
    driver: bridge

services:
  paxos.localdomain:
    container_name: paxos
    command: > 
      elixir --name paxos@paxos.localdomain --cookie pass 
             -S mix run --no-halt -e ${MAIN} ${CONFIG} ${SETUP} ${SERVERS} ${CLIENTS} 
    <<: *defaults

ENDHEADER

# ----------------------------------------------------------
for k in $(seq 1 $SERVERS)
do 
  cat >> $FILE << ENDSERVERS
  server${k}.localdomain:
    container_name: server${k}
    command: > 
      elixir --name server${k}@server${k}.localdomain --cookie pass 
             -S mix run --no-halt 
    <<: *defaults

ENDSERVERS
done

# ----------------------------------------------------------
for k in $(seq 1 $CLIENTS)
do 
  cat >> $FILE << ENDCLIENTS
  client${k}.localdomain:
    container_name: client${k}
    command: > 
      elixir --name client${k}@client${k}.localdomain --cookie pass 
             -S mix run --no-halt 
    <<: *defaults

ENDCLIENTS
done

echo >> $FILE << ENDFOOTER
# MISC
# - anchors only available in version 3.5, ditto x- services
# - macvlan network driver also works
# - tabs are a no-no, use spaces

ENDFOOTER


