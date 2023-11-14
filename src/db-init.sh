#!/bin/bash

set -e

# Define variables
BASE_PATH=$(dirname "$0")
COMPOSE_FILE="$BASE_PATH/../docker-compose.yml"
COMPOSE_VOLUME=skyfire-docker-compose_skyfire_mysql_data
IMAGE_NAME="skyfire-db-init"
DOCKERFILE_PATH="db-init.Dockerfile"
DOCKERFILE_CONTEXT="$BASE_PATH/.."

ENV_FILE="$BASE_PATH/../.env"

# Function for user confirmation
function confirm_execution {
    echo "WARNING: You are about to perform a database wipe/reset."
    echo "This action is IRREVERSIBLE and will result in the loss of all data within the specified database."
    echo "Before proceeding, ensure that you have verified backups and are aware of the recovery process."
    echo "This operation should only be conducted with explicit authorization and during a designated maintenance period."
    echo

    # Loop until the user provides a valid response
    while true; do
        read -rp "Type 'yes' to confirm that you understand the implications and wish to proceed: " yn
        case $yn in
        [Yy][Ee][Ss])
            echo "Confirmed. Proceeding with the operation..."
            break
            ;;
        *)
            echo "Operation aborted. No actions were taken."
            exit 1
            ;;
        esac
    done
}

# Function to safely remove a Docker volume
function safe_remove_volume {
    echo "Removing volume: $COMPOSE_VOLUME..."
    docker-compose -f "$COMPOSE_FILE" down -v
}

# Function to stop the MySQL service
function stop_mysql_service {
    echo "Stopping MySQL service..."
    docker-compose -f "$COMPOSE_FILE" stop mysql
}

# Ask for confirmation
confirm_execution

# Trap EXIT signal to ensure MySQL service is stopped
trap stop_mysql_service EXIT

# Check if .env file exists

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found!"
    exit 1
fi

# Load .env file
export "$(cat "$ENV_FILE" | grep -v '^#' | xargs)"

safe_remove_volume

# Start MySQL service using Docker Compose
echo "Starting MySQL service..."
docker-compose -f "$COMPOSE_FILE" up -d mysql

# Wait for MySQL to be fully ready
until docker exec "$(docker-compose -f "$COMPOSE_FILE" ps -q mysql)" mysqladmin ping -h mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
    echo "Waiting for database connection..."
    sleep 2
done

# Build the Docker image for database initialization
echo "Building the database initialization image..."
docker build -f src/$DOCKERFILE_PATH -t $IMAGE_NAME "$DOCKERFILE_CONTEXT"

# Run the container to initialize the database
echo "Running database initialization container..."

docker run --rm -i --env-file "$ENV_FILE" --network="host" --name skyfire-db-init-container $IMAGE_NAME /bin/bash <<'DEOF'

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --protocol=TCP -h localhost -P 3306 <<EOF
CREATE USER IF NOT EXISTS 'skyfire'@'localhost' IDENTIFIED BY 'password';
ALTER USER 'skyfire'@'localhost'
  WITH MAX_QUERIES_PER_HOUR 0
  MAX_CONNECTIONS_PER_HOUR 0
  MAX_UPDATES_PER_HOUR 0;

CREATE DATABASE world DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE characters DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE auth DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

GRANT ALL PRIVILEGES ON world.* TO 'skyfire'@'localhost';
GRANT ALL PRIVILEGES ON characters.* TO 'skyfire'@'localhost';
GRANT ALL PRIVILEGES ON auth.* TO 'skyfire'@'localhost';
FLUSH PRIVILEGES;
EOF

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --protocol=TCP -h localhost -P 3306 auth < ~/SkyFire_548/sql/base/auth_database.sql
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" --protocol=TCP -h localhost -P 3306 characters < ~/SkyFire_548/sql/base/characters_database.sql

./linux_installer.sh i
DEOF

echo "Script completed successfully."
