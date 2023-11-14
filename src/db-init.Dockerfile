FROM debian:stable-slim

ENV MYSQL_APT_VERSION=0.8.28-1

# Set environment variables to avoid interactive dialog during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies required for the operations
RUN apt-get update && \
    apt-get install -y apt-utils

# Install dependencies
RUN apt-get install -y \ 
    apt-utils \
    wget \
    curl \
    jq \
    unzip \
    lsb-release \
    gnupg \
    wget \
    curl \
    jq \
    unzip

# Add MySQL 8 repository and install client
RUN wget https://dev.mysql.com/get/mysql-apt-config_${MYSQL_APT_VERSION}_all.deb
RUN dpkg -i mysql-apt-config_${MYSQL_APT_VERSION}_all.deb

RUN apt-get update && \
    apt-get install -y mysql-client

# Set work directory
WORKDIR /root
COPY repos/SkyFire_548 ./SkyFire_548

# Fetch the latest release URL using GitHub API
RUN LATEST_RELEASE=$(curl -s https://api.github.com/repos/ProjectSkyfire/database/releases/latest | \
    jq -r '.assets[] | select(.name | contains("SFDB_full_548")) | .browser_download_url') && \
    wget "$LATEST_RELEASE" && \
    unzip -o "*.zip"

COPY src/linux_installer.sh linux_installer.sh
RUN chmod +x linux_installer.sh