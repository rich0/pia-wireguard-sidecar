#!/bin/sh
set -euo pipefail

# Env vars from Kubernetes (injected via Deployment)
: "${PIA_USER:?Required}"
: "${PIA_PASS:?Required}"
: "${PREFERRED_REGION:=}"  # Optional: e.g., "123" for specific region
: "${PIA_PF:=false}"       # Port forwarding (disabled by default)
: "${PIA_DNS:=true}"       # Use PIA DNS
: "${VPN_PROTOCOL:=wireguard}"
: "${AUTOCONNECT:=true}"   # Auto-select lowest latency server
: "${PIA_CONF_PATH:=/opt/piavpn-manual/wg0.conf}"
: "${PIA_CONNECT:=false}"  # Generate config only; we run wg-quick manually

export DISABLE_IPV6=yes  # Disable IPv6 to avoid leaks
export MAX_LATENCY=200   # Max ping latency for server selection (ms)

echo "=== Starting PIA WireGuard Sidecar ==="

cd /usr/local/bin

# Step 1: Get authentication token
#echo "Fetching PIA token..."
#get_token.sh

run_setup.sh

# Step 5: Rewrite routes (delete CNI default, add via wg0)
#echo "Configuring routes..."
#DEFAULT_GW=$(ip route | awk '/default via/ {print $3; exit}')
#[ -n "$DEFAULT_GW" ] && ip route del default via "$DEFAULT_GW" || true
#ip route add default dev wg0

# Step 6: (Optional) Enable port forwarding
#if [ "$PIA_PF" = "true" ]; then
#  echo "Enabling port forwarding..."
#  port_forwarding.sh
#fi

#echo "=== Tunnel ready! All egress now via PIA. ==="

# Keep alive (monitor tunnel health if needed)
exec sleep infinity
