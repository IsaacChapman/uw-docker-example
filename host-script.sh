#!/bin/bash

set -e # Exit on error
set -x # Echo on for logging

# Debugging info
env
pwd
ifconfig
ls -la
ps afxu

# Start docker
/usr/local/repos/wrapdocker /solano/agent/docker

# Pull docker image from registry
docker pull mysql:latest

# Start docker container and capture its id
CID=$(docker run -d -v /usr/local/repos/map_vol:/src -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD mysql:latest)

# Give mysql a couple of seconds to startup
sleep 10

# Show databases
docker exec -it $CID bash -c mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'show databases'

# Execute script on host
/usr/local/repos/map_vol/hello.sh 'from host'

# Execute script on docker container
docker exec -it $CID bash -c /src/hello.sh 'from docker'
