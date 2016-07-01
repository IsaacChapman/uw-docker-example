#!/bin/bash

set -e # Exit on error
set -x # Echo on for logging

# wrapdocker variables
DOCKER_DAEMON_ARGS="--storage-driver=vfs"
LOG="file"
DOCKER_GRAPH_PATH="/var/lib/docker/dind"
mkdir -p $DOCKER_GRAPH_PATH

# Ensure inner docker stops to prevent loopback device depletion
#function teardown {
#  set +e
#  kill -9 `cat /var/run/docker-in-docker.pid`
#  echo "### /var/log/docker.log ###"
#  cat /var/log/docker.log
#}
#trap teardown EXIT

# Start docker
/usr/local/repos/wrapdocker /solano/agent/docker
#/solano/agent/docker daemon --storage-driver=vfs &>/var/log/docker.log &
sleep 2

# Pull docker image from registry
docker pull mysql:latest

# Start docker container and capture its id
CID=$(docker run -d -v /usr/local/repos/map_vol:/src -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} mysql:latest)
DOCKER_PID=$!
echo $DOCKER_PID > /var/run/docker-in-docker.pid

# Give mysql a couple of seconds to startup
sleep 3

# Show databases
docker exec $CID bash -c mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'show databases'

# Execute script on host
/usr/local/repos/map_vol/hello.sh 'from host'

# Execute script on docker container
docker exec $CID bash -c /src/hello.sh 'from docker'
