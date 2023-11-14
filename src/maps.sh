#!/bin/bash

set -e

# Define variables
BASE_PATH=$(dirname "$0")
IMAGE_NAME="skyfire-maps"
DOCKERFILE_PATH="maps.Dockerfile"
DOCKERFILE_CONTEXT="$BASE_PATH/.."
CONTAINER_NAME="skyfire-maps-container"
BIN_DIR=$(realpath "$BASE_PATH"/../dist/skyfire-server/bin)

LOCAL_DBC_FOLDER="$(dirname "$0")/../dbc"
LOCAL_MAPS_FOLDER="$(dirname "$0")/../maps"

ENV_FILE="$BASE_PATH/../.env"

# Check if .env file exists

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found!"
    exit 1
fi

# Load .env file
export "$(cat "$ENV_FILE" | grep -v '^#' | xargs)"

# Check if a container with the same name already exists and remove it
if docker ps -a | grep -q $CONTAINER_NAME; then
    echo "A container with the name $CONTAINER_NAME already exists. Removing it..."
    if ! docker rm -f $CONTAINER_NAME; then
        echo "Failed to remove existing container."
        exit 1
    fi
fi

# Build the Docker image for map creation
echo "Building the map creation image..."
docker build -f src/$DOCKERFILE_PATH -t $IMAGE_NAME "$DOCKERFILE_CONTEXT"

# Run the container to initialize the database
docker run -i --env-file "$ENV_FILE" --name $CONTAINER_NAME \
    -v "$WOW_CLIENT_DIR:/wow_client" \
    -v "$BIN_DIR:/root/skyfire/bin/" \
    $IMAGE_NAME /bin/bash <<'DEOF'
chmod +x ~/skyfire/bin/mapextractor
chmod +x ~/skyfire/bin/vmap4extractor
# chmod +x ~/skyfire/bin/mmaps_generator
# chmod +x ~/skyfire/bin/vmap4assembler


# Run the extractor and check for successful execution
if ! ~/skyfire/bin/mapextractor; then
    echo "mapextractor failed"
fi

# if ! ~/skyfire/bin/vmap4extractor; then
#     echo "vmap4extractor failed"
# fi
DEOF

# Copy the dbc from the container to the local dbc folder
if ! docker cp $CONTAINER_NAME:/wow_client/dbc "$LOCAL_DBC_FOLDER"; then
    echo "Failed to copy binaries from /wow_client/dbc."
    exit 1
fi

# Copy the maps from the container to the local maps folder
if ! docker cp $CONTAINER_NAME:/wow_client/maps "$LOCAL_MAPS_FOLDER"; then
    echo "Failed to copy binaries from /wow_client/maps."
    exit 1
fi
