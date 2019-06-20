#!/usr/bin/env bash

CONTAINER_NAME=android-jenkins
result=$( docker images -q $CONTAINER_NAME )
if [[ -n "$result" ]]; then
   docker stop $CONTAINER_NAME
   docker rm $CONTAINER_NAME
   docker system prune --all --force --volumes
else
   echo "No such container"
fi

#docker build
docker build -t $CONTAINER_NAME . --no-cache

#Run jenkins
docker run --privileged -d \
--restart always \
--name $CONTAINER_NAME \
-p 9090:8080 -p 50000:50000 \
-v JENKINS_PATH:/var/jenkins_home \
-v /dev/bus/usb:/dev/bus/usb $CONTAINER_NAME