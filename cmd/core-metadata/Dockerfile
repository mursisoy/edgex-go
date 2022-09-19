#  ----------------------------------------------------------------------------------
#  Copyright 2018 Dell Technologies, Inc.
#  Copyright 2018 Cavium
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
# 
#  ----------------------------------------------------------------------------------

ARG BUILDER_BASE
ARG TARGET_ARCH

FROM ${BUILDER_BASE}-${TARGET_ARCH} AS builder
ARG CC
ARG CXX
ARG GOARCH
ARG GOARM
ARG GOOS=linux
ARG HOST
LABEL stage=builder

RUN GOOS=${GOOS} GOARCH=${GOARCH} CGOARM=${GOARM} CC=${CC} CXX=${CXX} make cmd/core-metadata/core-metadata

#Next image - Copy built Go binary into new workspace
FROM ${TARGET_ARCH}/alpine:3.14

RUN apk add --update --no-cache dumb-init

LABEL license='SPDX-License-Identifier: Apache-2.0' \
      copyright='Copyright (c) 2018: Dell, Cavium, Copyright (c) 2021: Intel Corporation'

ENV APP_PORT=59881
#expose meta data port
EXPOSE $APP_PORT

WORKDIR /
COPY --from=builder /edgex-go/Attribution.txt /
COPY --from=builder /edgex-go/cmd/core-metadata/core-metadata /
COPY --from=builder /edgex-go/cmd/core-metadata/res/configuration.toml /res/configuration.toml

ENTRYPOINT ["/core-metadata"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry", "--confdir=/res"]
