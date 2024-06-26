#!/bin/bash +e
#
#
# Note: if docker commands fail with "permission denied"; See
#       https://stackoverflow.com/questions/48957195/how-to-fix-docker-got-permission-denied-issue
set -e

# Following 3 values should come from a common file
# Project's Name
PROJECT=tesla_local_control_addon
# Projet's Version
VERSION=0.0.8
# Project's State (dev, prod?)
PROJECT_STATE=dev

# Docker Root Directory
DOCKER_ROOT_PATH=/volume/docker

# Project's Final Installation PATH
PROJECT_ROOT_PATH=${DOCKER_ROOT_PATH}/${PROJECT}

# create dir
[ ! -d $PROJECT_ROOT_PATH ] && mkdir $PROJECT_ROOT_PATH
cd $PROJECT_ROOT_PATH

# Clone tesla-local-control-addon repo
if [ ! -d tesla-local-control-addon ]; then
  echo "git clone tesla-local-control-addon repo"
  git clone https://github.com/tesla-local-control/tesla-local-control-addon
fi
cd tesla-local-control-addon \
  && git pull \
  && cd ..

# Backup files
###################################### BEFORE FINAL RELEASE WE REMOVE THE env FILE
BACKUP_TIME=$(date +%s)
BACKUP_LIST="build_image.sh Dockerfile docker-compose.yml install.sh"
for file in $BACKUP_LIST; do
  [ -f $file ] && mv $file $file.$BACKUP_TIME
  cp -p tesla-local-control-addon/standalone/$file .
done
# Copy once env
[ ! -f env ] && cp -p tesla-local-control-addon/standalone/env .

echo "Making sure we have a clean start; stop & delete docker container $PROJECT"
docker rm -f $PROJECT

[ ! -d data ] && mkdir data
[ ! -d share ] && mkdir share

# Pick docker-compose or docker compose
if [ type -a docker-compose > /dev/null ]; then
  DOCKER_CMD="docker-compose up -d"
else
  DOCKER_CMD="docker compose up -d"
fi
echo "Launching the docker container with $DOCKER_CMD"
$DOCKER_CMD
