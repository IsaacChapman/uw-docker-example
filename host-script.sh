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
  set +e # So all of the teardown commands run (may not be necessary)
  ls -la /var/run/
  kill -9 `cat /var/run/docker.pid`
  kill -9 `cat /var/run/docker-manually-set.pid`
  service docker stop # May require adding an init script
}
trap teardown EXIT

# Start docker
export DOCKER_GRAPH_PATH=/var/lib/docker-dind
mkdir -p $DOCKER_GRAPH_PATH
/usr/local/repos/wrapdocker /solano/agent/docker

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
