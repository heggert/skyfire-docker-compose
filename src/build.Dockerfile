FROM debian:stable-slim

ENV INSTALL_PREFIX=/usr/local
ENV OPENSSL_VERSION=1.1.1w
ENV MYSQL_APT_VERSION=0.8.28-1
ENV CC=gcc
ENV CXX=g++

# Set environment variables to avoid interactive dialog during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y apt-utils

# Install dependencies
RUN apt-get install -y \
    wget \
    lsb-release \
    gnupg

RUN wget https://dev.mysql.com/get/mysql-apt-config_${MYSQL_APT_VERSION}_all.deb
RUN dpkg -i mysql-apt-config_${MYSQL_APT_VERSION}_all.deb

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    cmake \
    make \
    gcc \
    g++ \
    perl \
    libncurses5-dev \
    libace-dev \
    libmysqlclient-dev \
    libreadline6-dev \
    zlib1g-dev \
    libbz2-dev \
    git

# Install OpenSSL from source

RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -zxf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config --prefix=${INSTALL_PREFIX}/ssl --openssldir=${INSTALL_PREFIX}/ssl shared zlib && \
    make -j$(nproc) && make install && \
    cd .. && rm -rf openssl-${OPENSSL_VERSION}*.tar.gz openssl-${OPENSSL_VERSION} && \
    echo "${INSTALL_PREFIX}/ssl/lib" > /etc/ld.so.conf.d/openssl-${OPENSSL_VERSION}.conf && \
    ldconfig

# Update the path to include the OpenSSL binaries
ENV PATH="${INSTALL_PREFIX}/ssl/bin:${PATH}"

WORKDIR /root/src

# RUN ls -la /usr/local/ssl/

# ENV OPENSSL_ROOT_DIR=/usr/local/ssl
# ENV OPENSSL_LIBRARIES=/usr/local/ssl/lib
# ENV OPENSSL_INCLUDE_DIR=/usr/local/ssl/include

# ENV LD_LIBRARY_PATH=/usr/local/ssl/lib:$LD_LIBRARY_PATH

# Copy the SkyFire_548 folder from the host to the container
COPY repos/SkyFire_548 ./SkyFire_548

WORKDIR /root/src/SkyFire_548
RUN mkdir build
WORKDIR /root/src/SkyFire_548/build

# Output the commit hash
RUN git rev-parse HEAD

# Configure the build with the install prefix
RUN cmake ../ \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}/skyfire-server/ \
    -DSCRIPTS=1 \ 
    -DTOOLS=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENSSL_CRYPTO_LIBRARIES=${INSTALL_PREFIX}/ssl/lib/libcrypto.so \
    -DOPENSSL_SSL_LIBRARIES=${INSTALL_PREFIX}/ssl/lib/libssl.so \
    -DOPENSSL_ROOT_DIR=${INSTALL_PREFIX}/ssl \
    -DOPENSSL_INCLUDE_DIR=${INSTALL_PREFIX}/ssl/include
RUN make -j$(nproc)

RUN make install

# Set a default command
CMD echo "SkyFire binaries are ready in $INSTALL_PREFIX/skyfire-server/"