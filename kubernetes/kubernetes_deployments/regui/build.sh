#!/bin/bash
set -e

REGISTRY_PREFIX="registry.test:5000"
IMAGE_NAME="regui"
TAG="v7"

FULL_IMAGE="${REGISTRY_PREFIX}/${IMAGE_NAME}:${TAG}"

echo "==> Building image: $FULL_IMAGE"
docker build -t "$FULL_IMAGE" .

echo ""
echo "==> Image built and tagged successfully"
docker images "$FULL_IMAGE" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"

echo ""
echo "==> Pushing to registry..."
docker push "$FULL_IMAGE"
echo "==> Push complete"
