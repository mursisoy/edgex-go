#
# Copyright (c) 2018 Cavium
#
# SPDX-License-Identifier: Apache-2.0
#


.PHONY: build clean unittest hadolint lint test docker run

DOCKERS= \
	docker_core_data \
	docker_core_metadata \
	docker_core_command  \
	docker_support_notifications \
	docker_sys_mgmt_agent \
	docker_support_scheduler \
	docker_security_proxy_setup \
	docker_security_secretstore_setup \
	docker_security_bootstrapper

.PHONY: $(DOCKERS)

MICROSERVICES= \
	cmd/core-data/core-data \
	cmd/core-metadata/core-metadata \
	cmd/core-command/core-command \
	cmd/support-notifications/support-notifications \
	cmd/sys-mgmt-executor/sys-mgmt-executor \
	cmd/sys-mgmt-agent/sys-mgmt-agent \
	cmd/support-scheduler/support-scheduler \
	cmd/security-proxy-setup/security-proxy-setup \
	cmd/security-secretstore-setup/security-secretstore-setup \
	cmd/security-file-token-provider/security-file-token-provider \
	cmd/secrets-config/secrets-config \
	cmd/security-bootstrapper/security-bootstrapper



.PHONY: $(MICROSERVICES)

VERSION=$(shell cat ./VERSION 2>/dev/null || echo 0.0.0)
DOCKER_TAG?=$(VERSION)-dev
DOCKER_REPOSITORY?=edgexfoundry
DOCKER_PREFIX?=
DOCKER_IMAGE_NAME=$(DOCKER_REPOSITORY)/$(DOCKER_PREFIX)$(MICROSERVICE)

GOFLAGS=-ldflags "-X github.com/edgexfoundry/edgex-go.Version=$(VERSION)"
GOTESTFLAGS?=-race

GIT_SHA=$(shell git rev-parse HEAD)

ARCH=$(shell uname -m)
TARGET_ARCH?=$(shell uname -m)

BUILDER_BASE="$(DOCKER_REPOSITORY)/$(DOCKER_PREFIX)builder"

ifeq ($(TARGET_ARCH), arm32v6)
	GOARCH=arm
	GOARM=6
	CC=arm-linux-gnueabihf-gcc
	CXX=arm-linux-gnueabihf-g++
	HOST=arm-linux-gnueabihf
else ifeq ($(TARGET_ARCH), arm32v7)
	GOARCH=arm
	GOARM=7
	CC=arm-linux-gnueabihf-gcc
	CXX=arm-linux-gnueabihf-g++
	HOST=arm-linux-gnueabihf
else ifeq ($(TARGET_ARCH), arm64v8)
	GOARCH=arm64
	GOARM=
	CC=aarch64-linux-gnu-gcc
	CXX=aarch64-linux-gnu-g++
	HOST=aarch64-linux-gnu
else ifeq ($(TARGET_ARCH), x86_64)
	TARGET_ARCH=amd64
	HOST=x86_64-pc-linux-gnu
endif

GO=CGO_ENABLED=0 GO111MODULE=on GOARCH=$(GOARCH) GOARM=$(GOARM) CC=$(CC) CXX=$(CXX) go
GOCGO=CGO_ENABLED=1 GO111MODULE=on GOARCH=$(GOARCH) GOARM=$(GOARM) CC=$(CC) CXX=$(CXX) go


DOCKER_BUILD_PUSH=docker build \
		--build-arg CC=$(CC) \
		--build-arg CXX=$(CXX) \
		--build-arg GOARM=$(GOARM) \
		--build-arg GOARCH=$(GOARCH) \
		--build-arg TARGET_ARCH=$(TARGET_ARCH) \
		--build-arg HOST=$(HOST) \
		--build-arg BUILDER_BASE=$(BUILDER_BASE):$(GIT_SHA) \
	    --build-arg http_proxy \
	    --build-arg https_proxy \
		-f cmd/$(MICROSERVICE)/Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		-t $(DOCKER_IMAGE_NAME):$(GIT_SHA)-$(TARGET_ARCH) \
		-t $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)-$(TARGET_ARCH) \
		. \
		&& [ $${DOCKER_PUSH:=0} -eq 1 ] \
		&& docker push  $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)-$(TARGET_ARCH) \
		&& docker manifest create $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) --amend $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)-$(TARGET_ARCH) \
		&& docker manifest push $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) \
		|| echo "Not pushing image."

build: $(MICROSERVICES)

tidy:
	go mod tidy

cmd/core-metadata/core-metadata:
	GOOS=$(GOOS) GOARCH=$(GOARCH) CGOARM=$(GOARM) CC=$(CC) CXX=$(CXX) $(GO) build $(GOFLAGS) -o $@ ./cmd/core-metadata

cmd/core-data/core-data:
	$(GOCGO) build $(GOFLAGS) -o $@ ./cmd/core-data

cmd/core-command/core-command:
	$(GO) build $(GOFLAGS) -o $@ ./cmd/core-command

cmd/support-notifications/support-notifications:
	$(GO) build $(GOFLAGS) -o $@ ./cmd/support-notifications

cmd/sys-mgmt-executor/sys-mgmt-executor:
	$(GO) build $(GOFLAGS) -o $@ ./cmd/sys-mgmt-executor

cmd/sys-mgmt-agent/sys-mgmt-agent:
	$(GO) build $(GOFLAGS) -o $@ ./cmd/sys-mgmt-agent

cmd/support-scheduler/support-scheduler:
	$(GO) build $(GOFLAGS) -o $@ ./cmd/support-scheduler

cmd/security-proxy-setup/security-proxy-setup:
	$(GO) build $(GOFLAGS) -o ./cmd/security-proxy-setup/security-proxy-setup ./cmd/security-proxy-setup

cmd/security-secretstore-setup/security-secretstore-setup:
	$(GO) build $(GOFLAGS) -o ./cmd/security-secretstore-setup/security-secretstore-setup ./cmd/security-secretstore-setup

cmd/security-file-token-provider/security-file-token-provider:
	$(GO) build $(GOFLAGS) -o ./cmd/security-file-token-provider/security-file-token-provider ./cmd/security-file-token-provider

cmd/secrets-config/secrets-config:
	$(GO) build $(GOFLAGS) -o ./cmd/secrets-config ./cmd/secrets-config

cmd/security-bootstrapper/security-bootstrapper:
	$(GO) build $(GOFLAGS) -o ./cmd/security-bootstrapper/security-bootstrapper ./cmd/security-bootstrapper

clean:
	rm -f $(MICROSERVICES)

unittest:
	go mod tidy
	GO111MODULE=on go test $(GOTESTFLAGS) -coverprofile=coverage.out ./...

hadolint:
	if which hadolint > /dev/null ; then hadolint --config .hadolint.yml `find * -type f -name 'Dockerfile*' -print` ; elif test "${ARCH}" = "x86_64" && which docker > /dev/null ; then docker run --rm -v `pwd`:/host:ro,z --entrypoint /bin/hadolint hadolint/hadolint:latest --config /host/.hadolint.yml `find * -type f -name 'Dockerfile*' | xargs -i echo '/host/{}'` ; fi

lint:
	@which golangci-lint >/dev/null || echo "WARNING: go linter not installed. To install, run\n  curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b \$$(go env GOPATH)/bin v1.42.1"
	@if [ "z${ARCH}" = "zx86_64" ] && which golangci-lint >/dev/null ; then golangci-lint run --config .golangci.yml ; else echo "WARNING: Linting skipped (not on x86_64 or linter not installed)"; fi


test: unittest hadolint lint
	GO111MODULE=on go vet ./...
	gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")
	[ "`gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")`" = "" ]
	./bin/test-attribution-txt.sh
		.

docker: $(DOCKERS)


docker_prune:
	docker rmi $$(docker images --filter=label=stage=builder -q)


docker_builder:
	docker build \
		--build-arg CC=$(CC) \
		--build-arg CXX=$(CXX) \
		--build-arg TARGET_ARCH=$(TARGET_ARCH) \
		--build-arg HOST=$(HOST) \
		-f builder.Dockerfile \
		--label "git_sha=$(GIT_SHA)" \
		-t $(BUILDER_BASE):$(GIT_SHA)-$(TARGET_ARCH) \
		.

docker_core_metadata: MICROSERVICE=core-metadata
docker_core_metadata: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_core_data: MICROSERVICE=core-data
docker_core_data: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_core_command: MICROSERVICE=core-command
docker_core_command: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_support_notifications: MICROSERVICE=support-notifications
docker_support_notifications: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_support_scheduler: MICROSERVICE=support-scheduler
docker_support_scheduler: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_sys_mgmt_agent: MICROSERVICE=sys-mgmt-agent
docker_sys_mgmt_agent: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_security_proxy_setup: MICROSERVICE=security-proxy-setup
docker_security_proxy_setup: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_security_secretstore_setup: MICROSERVICE=security-secretstore-setup
docker_security_secretstore_setup: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_security_bootstrapper: MICROSERVICE=security-bootstrapper
docker_security_bootstrapper: docker_builder
	$(DOCKER_BUILD_PUSH)

docker_microservice_build:



vendor:
	$(GO) mod vendor
