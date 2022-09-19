#  ----------------------------------------------------------------------------------
#  Copyright 2019 Dell Technologies, Inc.
#  Copyright 2020 Intel Corp.
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

RUN GOOS=${GOOS} GOARCH=${GOARCH} CGOARM=${GOARM} CC=${CC} CXX=${CXX} make cmd/security-proxy-setup/security-proxy-setup cmd/secrets-config/secrets-config

FROM ${TARGET_ARCH}/alpine:3.14

RUN apk add --update --no-cache curl

LABEL license='SPDX-License-Identifier: Apache-2.0' \
      copyright='Copyright (c) 2019: Dell Technologies, Inc.'

WORKDIR /edgex

COPY --from=builder /edgex-go/cmd/security-proxy-setup/res/configuration.toml res/configuration.toml
COPY --from=builder /edgex-go/cmd/security-proxy-setup/security-proxy-setup .
# Note that secrets-config shares the same configuration file as security-proxy-setup
# as we are splitting security-proxy-setup into two different utilities for ease-of-use.
COPY --from=builder /edgex-go/cmd/secrets-config/secrets-config .

ENTRYPOINT ["/edgex/security-proxy-setup"]
CMD ["--init=true"]
