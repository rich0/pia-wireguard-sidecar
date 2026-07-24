#!/bin/bash
set -euo pipefail
ALPINE_RELEASE=3.24
IMAGE=registry.rich0.org/public/pia-wireguard-sidecar
regctl image copy  "${IMAGE}:latest" "${IMAGE}:previous"
docker build . --pull --no-cache --build-arg ALPINE_RELEASE=$ALPINE_RELEASE \
  --tag "$IMAGE:$ALPINE_RELEASE" --tag "$IMAGE:latest"
docker push "$IMAGE:$ALPINE_RELEASE"
docker push "$IMAGE:latest"
