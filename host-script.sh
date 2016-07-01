#!/bin/bash

set -e # Exit on error
set -x # For ease of viewing test results

# Docker daemon args
DOCKER_DAEMON_ARGS="--storage-driver=aufsext -g /var/lib/docker/dind"
mkdir -p /var/lib/docker/dind

# Ensure inner docker stops to prevent loopback device depletion
function teardown {
  set +e
  docker kill `cat /var/run/docker-in-docker.cid`
  kill -9 `cat /var/run/docker-in-docker.pid`
  echo "### /var/log/docker.log ###"
  cat /var/log/docker.log
}
trap teardown EXIT

# Install mysql client in case it isn't already installed
apt-get install -y mysql-client

# Start docker
docker daemon $DOCKER_DAEMON_ARGS &>/var/log/docker.log &
sleep 5

# Pull docker image from registry
docker pull mysql:5.7

# Show docker images
docker images

# Start docker container and capture its id, pid, and ip address
CID=$(docker run -d -v /usr/local/repos/map_vol:/src -p 3306:3306 -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} mysql:5.7)
DOCKER_PID=$!
echo $CID > /var/run/docker-in-docker.cid
echo $DOCKER_PID > /var/run/docker-in-docker.pid
IP_ADDR=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $CID)
echo $IP_ADDR > /var/run/docker-in-docker.ip

# Give mysql a couple of seconds to startup (the faster the host, the less it needs to sleep here)
sleep 20

# Connecting to docker container
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h `cat /var/run/docker-in-docker.ip` -P 3306 -e 'show databases'

# Connecting to host mounted port
mysql -u root -p${MYSQL_ROOT_PASSWORD} -h 127.0.0.1 -P 3306 -e 'show databases'

# Execute script on host
/usr/local/repos/map_vol/hello.sh 'from host'

# Execute script on docker container
docker exec -t $CID /src/hello.sh 'from docker'
