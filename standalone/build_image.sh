#!/bin/bash
#
set -e

# Following 3 values should come from a common file
PROJECT=tesla_local_control_addon
PROJECT_STATE=dev
VERSION=0.0.8

ALPINE_RELEASE=alpine:latest

cd "$(dirname "$0")"

## create dir
#[ ! -d $PROJECT ] && mkdir $PROJECT
#cd $PROJECT

## Clone tesla-local-control-addon repo
#echo "Clone tesla-local-control-addon repo"
#if [ ! -d tesla-local-control-addon ]; then
#  git clone https://github.com/tesla-local-control/tesla-local-control-addon
#fi

git pull

cd ../tesla_ble_mqtt

# Bulding docker image
docker build -t ${PROJECT}:${VERSION}${PROJECT_STATE} --build-arg BUILD_FROM=${ALPINE_RELEASE} .
