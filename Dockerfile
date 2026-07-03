# syntax = docker/dockerfile:1.25
ARG ALPINE_RELEASE=3.24

FROM alpine:${ALPINE_RELEASE} AS builder

# Install git (only for cloning) + runtime deps
RUN apk add --no-cache \
    git \
    wireguard-tools \
    iproute2 \
    curl \
    jq \
    iptables \
    openresolv \
    ip6tables

# Clone the official PIA manual-connections repo
WORKDIR /tmp
RUN git clone https://github.com/pia-foss/manual-connections.git

# -------------------------------------------------
# Final stage – tiny image, no git
# -------------------------------------------------
FROM alpine:${ALPINE_RELEASE}

# Install only what is needed at runtime
RUN apk add --no-cache \
    wireguard-tools \
    iproute2 \
    curl \
    jq \
    iptables \
    openresolv \
    ip6tables

# Copy the PIA helper scripts from the builder stage
COPY --from=builder /tmp/manual-connections/*  /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# openresolv 3.17+ (Alpine 3.23+) rejects /etc/resolv.conf without its signature
# and tries to restart services via an init system that containers lack.
RUN printf '%s\n' \
    '# Container-friendly resolvconf config' \
    'libc_restart=":"' \
    >> /etc/resolvconf.conf

# Create a directory for tokens / generated config (mounted as emptyDir in the pod)
RUN mkdir -p /opt/piavpn-manual

# Copy the custom wrapper (you’ll add this file next to the Dockerfile)
COPY pia-sidecar-wrapper.sh /usr/local/bin/pia-sidecar-wrapper.sh
RUN chmod +x /usr/local/bin/pia-sidecar-wrapper.sh

# Default command
CMD ["/usr/local/bin/pia-sidecar-wrapper.sh"]
