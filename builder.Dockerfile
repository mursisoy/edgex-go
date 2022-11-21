ARG BASE=golang:1.16-alpine3.14
FROM ${BASE} AS builder

RUN sed -e 's/dl-cdn[.]alpinelinux.org/nl.alpinelinux.org/g' -i~ /etc/apk/repositories
RUN apk add --update --no-cache make git openssh gcc libc-dev zeromq-dev libsodium-dev

WORKDIR /edgex-go
COPY . .
RUN [ ! -d "vendor" ] && go mod download all || echo "skipping..."