ARG TARGET_ARCH

FROM golang:1.19-bullseye as builder
ARG CC
ARG CXX
ARG HOST



ENV ZMQ_VERSION=4.2.5

# Build time options to avoid dpkg warnings and help with reproducible builds.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    TZ=UTC \
    TERM=xterm-256color \
    USER="root"

RUN apt-get update
RUN apt-get install -y build-essential \
                       libunwind-13-dev \
                       libzmq3-dev \
                       file

RUN [ "$HOST" = "arm-linux-gnueabihf" ] && apt-get install -y libc6-armhf-cross libc6-dev-armhf-cross binutils-arm-linux-gnueabihf gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf || :
RUN [ "$HOST" = "aarch64-linux-gnu" ] && apt-get install -y libc6-arm64-cross libc6-dev-arm64-cross binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu g++-aarch64-linux-gnu || :

RUN mkdir /deps
RUN  wget https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}/zeromq-${ZMQ_VERSION}.tar.gz -O - | tar xz -C /deps
WORKDIR /deps/zeromq-${ZMQ_VERSION}
RUN  ./configure --host=${HOST} CC=${CC} CXX=${CXX} --prefix=/lib/${CC%"-gcc"}/ && make && make install
ENV PKG_CONFIG_PATH=/lib/${HOST}/lib/pkgconfig

WORKDIR /edgex-go
COPY . .
RUN [ ! -d "vendor" ] && go mod download all || echo "skipping..."