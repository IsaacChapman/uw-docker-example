#!/bin/bash

set -e # Exit on error
set -x # Echo on for logging

# Docker daemon args
DOCKER_DAEMON_ARGS="--storage-driver=aufsext -g /var/lib/docker/dind"
mkdir -p /var/lib/docker/dind

# Ensure inner docker stops to prevent loopback device depletion
function teardown {
  set +e
  kill -9 `cat /var/run/docker-in-docker.pid`
  echo "### /var/log/docker.log ###"
  cat /var/log/docker.log
}
trap teardown EXIT

# Install mysql client in case it isn't already installed
apt-get install -y mysql-client

# Start docker
/solano/agent/docker daemon $DOCKER_DAEMON_ARGS &>/var/log/docker.log &
sleep 5

# Pull docker image from registry
docker pull mysql:latest

# Start docker container and capture its id
CID=$(docker run -d -v /usr/local/repos/map_vol:/src -p 127.0.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} mysql:latest)
DOCKER_PID=$!
echo $DOCKER_PID > /var/run/docker-in-docker.pid

# Give mysql a couple of seconds to startup
sleep 5

# Show container databases from host
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h 127.0.0.1 -P 3306 -e 'show databases'

# Execute script on host
/usr/local/repos/map_vol/hello.sh 'from host'

# Execute script on docker container
docker exec -t $CID /src/hello.sh 'from docker'
