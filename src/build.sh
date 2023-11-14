#!/bin/bash

set -e

# Define variables
IMAGE_NAME="skyfire-server-build"
DOCKERFILE_PATH="build.Dockerfile"
DOCKERFILE_CONTEXT="$(dirname "$0")/.."
CONTAINER_NAME="skyfire-temp"
REPOS_PATH="$(dirname "$0")/../repos"
BINARIES_PATH_SKYFIRE="/usr/local/skyfire-server"
BINARIES_PATH_SSL="/usr/local/ssl"

LOCAL_DIST_FOLDER="$(dirname "$0")/../dist"

# Create the folders if it doesn't exist
mkdir -p "$LOCAL_DIST_FOLDER"

# Clear the contents of the dist folder
echo "Clearing $LOCAL_DIST_FOLDER..."
rm -rf "${LOCAL_DIST_FOLDER:?}"/*

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    echo "Docker could not be found. Please install Docker to continue."
    exit 1
fi

# Check if REPOS_PATH contains SkyFire_548
if [[ ! -d "$REPOS_PATH/SkyFire_548" ]]; then
    echo "The repository path $REPOS_PATH does not contain SkyFire_548. Please check the directory."
    exit 1
fi

# Build the Docker image
echo "Building the SkyFire server. This may take some time..."
if ! docker build -f src/$DOCKERFILE_PATH -t $IMAGE_NAME "$DOCKERFILE_CONTEXT"; then
    echo "Build failed. Please check the output for errors."
    exit 1
fi

echo "Build completed successfully. Image is tagged as $IMAGE_NAME."

# Check if a container with the same name already exists and remove it
if docker ps -a | grep -q $CONTAINER_NAME; then
    echo "A container with the name $CONTAINER_NAME already exists. Removing it..."
    if ! docker rm -f $CONTAINER_NAME; then
        echo "Failed to remove existing container."
        exit 1
    fi
fi

# Create a temporary container
if ! docker create --name $CONTAINER_NAME $IMAGE_NAME; then
    echo "Failed to create a temporary container."
    exit 1
fi

# Start and then immediately stop the container
docker start $CONTAINER_NAME
docker stop $CONTAINER_NAME

# Copy the binaries from the container to the local dist folder
if ! docker cp $CONTAINER_NAME:$BINARIES_PATH_SKYFIRE "$LOCAL_DIST_FOLDER"; then
    echo "Failed to copy binaries from $BINARIES_PATH_SKYFIRE."
    exit 1
fi

if ! docker cp $CONTAINER_NAME:$BINARIES_PATH_SSL "$LOCAL_DIST_FOLDER"; then
    echo "Failed to copy binaries from $BINARIES_PATH_SSL."
    exit 1
fi

echo "Binaries copied to $LOCAL_DIST_FOLDER."

echo "Script completed successfully."
