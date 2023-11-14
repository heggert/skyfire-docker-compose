#!/bin/bash

set -e

REPO_URL="git@github.com:ProjectSkyfire/SkyFire_548.git"
REPOS_PATH="$(dirname "$0")/../repos"
# Default values
BRANCH="main"
TAG=""
COMMIT="latest"

# Assign arguments to variables if provided, otherwise use default
if [ -n "$1" ]; then BRANCH="$1"; fi
if [ -n "$2" ]; then TAG="$2"; fi
if [ -n "$3" ]; then COMMIT="$3"; fi

# Extract the name of the repo from the URL to use as directory name
REPO_NAME=$(basename "$REPO_URL" .git)

# Directory where the repo will be cloned
CLONE_DIR="$REPOS_PATH/$REPO_NAME"

# Ensure the clone directory exists
mkdir -p "$CLONE_DIR"

# Clone the repo
if [ -d "$CLONE_DIR" ]; then
    echo "Repository already exists in $CLONE_DIR"
else
    git clone "$REPO_URL" "$CLONE_DIR"
fi

# Checkout the specified branch, tag, or commit
cd "$CLONE_DIR" || return
git fetch --all
git reset --hard
git checkout "$BRANCH"
if [ -n "$TAG" ]; then git checkout "tags/$TAG"; fi
if [ "$COMMIT" != "latest" ]; then git checkout "$COMMIT"; fi
