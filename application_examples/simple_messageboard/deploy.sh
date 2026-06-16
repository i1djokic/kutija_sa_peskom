#!/bin/sh
set -e

IMAGE="registry.test:5000/simple_messageboard"
TAG="${1:-latest}"
FULL_IMAGE="${IMAGE}:${TAG}"

echo "=== Building image ${FULL_IMAGE} ==="
podman build --network=host -t "${FULL_IMAGE}" .

echo "=== Pushing image to registry ==="
podman push --tls-verify=false "${FULL_IMAGE}"

echo "=== Restarting Kubernetes deployment ==="
kubectl rollout restart deployment/messageboard

echo "=== Watching rollout status ==="
kubectl rollout status deployment/messageboard --timeout=120s

echo "=== Done ==="
