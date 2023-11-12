#!/bin/bash

# Define variables
IMAGE_NAME="skyfire-server-build"
DOCKERFILE_PATH="."
CONTAINER_NAME="skyfire-temp"
BINARIES_PATH="/home/skyfire/skyfire-server/" # Path inside the container where binaries are located
LOCAL_DIST_FOLDER="dist"

# Create the dist folder if it doesn't exist
mkdir -p $LOCAL_DIST_FOLDER

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker to continue."
    exit 1
fi

# Build the Docker image
echo "Building the SkyFire server. This may take some time..."
docker build -t $IMAGE_NAME $DOCKERFILE_PATH

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "Build failed. Please check the output for errors."
    exit 1
fi

echo "Build completed successfully. Image is tagged as $IMAGE_NAME."

# Create a temporary container and immediately stop it (as we only need it for copying files)
docker create --name $CONTAINER_NAME $IMAGE_NAME
docker start $CONTAINER_NAME
docker stop $CONTAINER_NAME

# Copy the binaries from the container to the local dist folder
docker cp $CONTAINER_NAME:$BINARIES_PATH $LOCAL_DIST_FOLDER

# Check if the copy was successful
if [ $? -eq 0 ]; then
    echo "Binaries copied to $LOCAL_DIST_FOLDER."
else
    echo "Failed to copy binaries. Please check the output for errors."
    exit 1
fi

# Cleanup: Remove the temporary container
docker rm $CONTAINER_NAME

echo "Script completed successfully."