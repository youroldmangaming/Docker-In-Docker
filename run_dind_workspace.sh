#!/bin/bash

# Default container name if not specified
CONTAINER_NAME=${1:-docker-dind-full}
PORT=${2:-2375}

echo "Starting Docker-in-Docker container: $CONTAINER_NAME on port $PORT"

# Create required directories if they don't exist
mkdir -p $(pwd)/docker-certs
mkdir -p $(pwd)/workspace-${CONTAINER_NAME}

echo "Created required directories"

# Check for the build directory
if [ ! -d "./build" ]; then
  echo "Error: ./build directory not found"
  exit 1
fi

# Copy and customize docker-compose.yml for this instance
if [ -f ./build/docker-compose.yml ]; then
  echo "Customizing docker-compose.yml for $CONTAINER_NAME"
  
  # Create a copy of the template in the workspace directory
  cp ./build/docker-compose.yml ./workspace-${CONTAINER_NAME}/docker-compose.yml
  
  # Update the container name, port, and volume mappings
  # Using different sed syntax for compatibility with both Linux and macOS
  sed -i.bak "s/container_name: docker-dind-full/container_name: ${CONTAINER_NAME}/" ./workspace-${CONTAINER_NAME}/docker-compose.yml
  sed -i.bak "s/\"2375:2375\"/\"${PORT}:2375\"/" ./workspace-${CONTAINER_NAME}/docker-compose.yml
  sed -i.bak "s/- docker-storage:/- ${CONTAINER_NAME}-storage:/" ./workspace-${CONTAINER_NAME}/docker-compose.yml
  sed -i.bak "s/- \.\/workspace:/- \.\/workspace-${CONTAINER_NAME}:/" ./workspace-${CONTAINER_NAME}/docker-compose.yml
  
  # Update the volumes section - simpler approach for better compatibility
  # Replace the volumes line and what follows with our new content
  awk -v name="${CONTAINER_NAME}" '{
    if ($0 ~ /volumes:/) {
      print "volumes:";
      print "  " name "-storage:";
      next;
    } else if ($0 ~ /docker-storage:/) {
      next;
    }
    print $0;
  }' ./workspace-${CONTAINER_NAME}/docker-compose.yml > ./workspace-${CONTAINER_NAME}/docker-compose.yml.new
  
  mv ./workspace-${CONTAINER_NAME}/docker-compose.yml.new ./workspace-${CONTAINER_NAME}/docker-compose.yml
  
  # Remove backup files
  rm ./workspace-${CONTAINER_NAME}/*.bak 2>/dev/null
  
  echo "Custom docker-compose.yml created in workspace-${CONTAINER_NAME}/"
else
  echo "Warning: Could not find ./build/docker-compose.yml template"
fi

# Check for Dockerfile in build directory
if [ -f ./build/Dockerfile ]; then
  echo "Using Dockerfile from build directory"
  DOCKERFILE_PATH="./build/Dockerfile"
else
  echo "Error: Dockerfile not found in build directory"
  exit 1
fi

# Stop and remove any existing container with the same name
docker rm -f $CONTAINER_NAME 2>/dev/null

# Build the image using the Dockerfile from build directory
echo "Building Docker image from $DOCKERFILE_PATH"
docker build -t docker-dind-full -f $DOCKERFILE_PATH ./build

# Run the container with the specified name
docker run -d \
  --name $CONTAINER_NAME \
  --privileged \
  -p $PORT:2375 \
  -v ${CONTAINER_NAME}-storage:/var/lib/docker \
  -v $(pwd)/docker-certs:/certs \
  -v $(pwd)/workspace-${CONTAINER_NAME}:/workspace \
  --restart unless-stopped \
  docker-dind-full

# Wait for container to be ready
echo "Waiting for $CONTAINER_NAME to start..."
WAIT_COUNT=0
until docker exec -i $CONTAINER_NAME docker info >/dev/null 2>&1; do
  sleep 1
  # Add timeout after 30 seconds
  WAIT_COUNT=$((WAIT_COUNT+1))
  if [ $WAIT_COUNT -gt 30 ]; then
    echo "Timeout waiting for Docker to start. Check container logs with: docker logs $CONTAINER_NAME"
    exit 1
  fi
done

# Enter the container
echo "$CONTAINER_NAME is ready! Connecting to container shell..."
docker exec -it $CONTAINER_NAME bash
