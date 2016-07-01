#!/bin/bash

set -e # Exit on error
set -x # Echo on for logging

# Debugging info
env
pwd
ifconfig
ls -la
ps afxu
ls -la /var/run/

# Ensure inner docker stops to prevent loopback device 
function teardown {
  kill -9 `cat /var/run/docker-in-docker.pid`
}
trap teardown EXIT

# Start docker (vfs necessary)
/solano/agent/docker daemon --storage-driver=vfs &>/var/log/docker.log &
sleep 2

# Pull docker image from registry
docker pull mysql:latest

# Start docker container and capture its id
CID=$(docker run -d -v /var/lib/docker.sock:/var/lib/docker.sock -v /usr/local/repos/map_vol:/src -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD mysql:latest)
DOCKER_PID=#!
echo $DOCKER_PID > /var/run/docker-manually-set.pid

# Give mysql a couple of seconds to startup
sleep 10

# Show databases
docker exec -it $CID bash -c mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'show databases'

# Execute script on host
/usr/local/repos/map_vol/hello.sh 'from host'

# Execute script on docker container
docker exec -it $CID bash -c /src/hello.sh 'from docker'
