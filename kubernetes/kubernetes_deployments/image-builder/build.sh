#!/bin/bash
set -e

REGISTRY_PREFIX="registry.test:5000"
IMAGE_NAME="image-builder"
TAG="v1"
FULL_IMAGE="${REGISTRY_PREFIX}/${IMAGE_NAME}:${TAG}"

echo "==> Building: $FULL_IMAGE"
docker build -t "$FULL_IMAGE" api/

echo ""
echo "==> Pushing..."
docker push "$FULL_IMAGE"
echo "==> Done: $FULL_IMAGE"
