FROM soarinferret/iptablesproxy

WORKDIR /root

# Install prerequisities.
RUN apk update && apk upgrade && apk add bash

# Copy scripts for setting up the CCR for sandboxing.
COPY config/setup-iptables.sh setup-iptables.sh
