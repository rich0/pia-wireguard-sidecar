FROM alpine:3.20

# Install dependencies: wireguard-tools, iproute2, curl, jq
RUN apk add --no-cache \
    wireguard-tools \
    iproute2 \
    curl \
    jq

# Clone PIA manual-connections repo (scripts in root)
RUN mkdir -p /opt/piavpn-manual && \
    cd /tmp && \
    git clone https://github.com/pia-foss/manual-connections.git && \
    cp manual-connections/*.sh /usr/local/bin/ && \
    chmod +x /usr/local/bin/*.sh && \
    rm -rf /tmp/manual-connections

# Create state dir for tokens/configs
RUN mkdir -p /opt/piavpn-manual

# Copy custom wrapper script
COPY pia-sidecar-wrapper.sh /usr/local/bin/pia-sidecar-wrapper.sh
RUN chmod +x /usr/local/bin/pia-sidecar-wrapper.sh

CMD ["/usr/local/bin/pia-sidecar-wrapper.sh"]
