#
# Copyright (c) 2018
# Cavium
#
# SPDX-License-Identifier: Apache-2.0
#

ARG BUILDER_BASE

FROM ${BUILDER_BASE} AS builder

LABEL stage=builder
RUN make cmd/sys-mgmt-agent/sys-mgmt-agent cmd/sys-mgmt-executor/sys-mgmt-executor

FROM alpine:3.14

RUN apk add --update --no-cache ca-certificates dumb-init

LABEL license='SPDX-License-Identifier: Apache-2.0' \
      copyright='Copyright (c) 2018: Cavium, Copyright (c) 2021: Intel Corporation'

ENV APP_PORT=58890
#expose system mgmt agent port
EXPOSE $APP_PORT

# Copy over the SMA executable bits.
COPY --from=builder /edgex-go/cmd/sys-mgmt-agent/sys-mgmt-agent /
COPY --from=builder /edgex-go/cmd/sys-mgmt-agent/res/configuration.toml /res/configuration.toml

# Copy over the golang "executor" executable.
COPY --from=builder /edgex-go/cmd/sys-mgmt-executor/sys-mgmt-executor /

ENTRYPOINT ["/sys-mgmt-agent"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry", "--confdir=/res"]

# Following (commented-out) line is a life-saving DEBUG statement.
# ENTRYPOINT tail -f /dev/null
