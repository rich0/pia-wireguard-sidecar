#!/bin/bash
ALPINE_RELEASE=3.22
docker build . --pull --no-cache --build-arg ALPINE_RELEASE=$ALPINE_RELEASE --tag ghcr.io/rich0/pia-wireguard-sidecar:$ALPINE_RELEASE --tag ghcr.io/rich0/pia-wireguard-sidecar:latest && docker push ghcr.io/rich0/pia-wireguard-sidecar:$ALPINE_RELEASE && docker push ghcr.io/rich0/pia-wireguard-sidecar:latest
