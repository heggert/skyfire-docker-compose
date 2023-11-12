# Use Ubuntu 18.04 LTS as the base image
FROM ubuntu:18.04

# Set environment variables to avoid interactive dialog during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && \
    apt-get install -y build-essential autoconf libtool gcc g++ make cmake subversion git patch wget links zip unzip openssl libssl-dev libreadline-gplv2-dev zlib1g-dev libbz2-dev git-core libace-dev libncurses5-dev libace-dev && \
    add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install -y gcc-9 g++-9 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 10 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 10 && \
    update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 10 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 10

# Set the user
ARG USER=skyfire
RUN useradd -ms /bin/bash ${USER}

# Change to the user
USER ${USER}
WORKDIR /home/${USER}

# Install OpenSSL
RUN wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz && \
    tar -xvf openssl-1.1.1k.tar.gz && \
    cd openssl-1.1.1k && \
    mkdir build && \
    cd build && \
    ../config shared && \
    make && \
    make install

# Install ACE
RUN wget http://github.com/DOCGroup/ACE_TAO/releases/download/ACE%2BTAO-6_5_6/ACE-6.5.6.tar.gz && \
    tar xvzf ACE-6.5.6.tar.gz && \
    cd ACE_wrappers/ && \
    mkdir build && \
    cd build && \
    ../configure --disable-ssl && \
    make -j5 && \
    make install

# Clone and compile SkyFire
RUN git clone -b trunk https://github.com/ProjectSkyfire/SkyFire_548.git && \
    cd SkyFire_548 && \
    mkdir build && \
    cd build && \
    cmake ../ -DCMAKE_INSTALL_PREFIX=$HOME/skyfire-server/ -DTOOLS=1 && \
    make -j$(nproc) && \
    make install

# Set a default command (this can be a no-op command, as binaries are the main goal)
CMD ["echo", "SkyFire binaries are ready in /home/skyfire/skyfire-server/"]