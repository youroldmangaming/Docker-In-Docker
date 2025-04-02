# Build and start the container
#docker compose up -d
#docker compose up -d docker compose exec docker-in-docker sh



#!/bin/bash

# Stop and remove any existing container
docker rm -f docker-dind-full 2>/dev/null

# Build the image
docker build -t docker-dind-full .
