#!/bin/sh
set -e

NAMESPACE="smapp"
IMAGE="registry.test:5000/simple_messageboard"
TAG="${1:-latest}"
FULL_IMAGE="${IMAGE}:${TAG}"

echo "=== Creating namespace ${NAMESPACE} ==="
kubectl create namespace "${NAMESPACE}" 2>/dev/null || true

echo "=== Building image ${FULL_IMAGE} ==="
podman build --network=host -t "${FULL_IMAGE}" .

echo "=== Pushing image to registry ==="
podman push --tls-verify=false "${FULL_IMAGE}"

echo "=== Applying Kubernetes manifests from kubernetes/ ==="
kubectl apply -n "${NAMESPACE}" -f kubernetes/

echo "=== Waiting for MariaDB StatefulSet to be ready ==="
kubectl rollout status -n "${NAMESPACE}" statefulset/messageboard-db --timeout=180s

echo "=== Restarting application Deployment ==="
kubectl rollout restart -n "${NAMESPACE}" deployment/messageboard

echo "=== Watching application rollout status ==="
kubectl rollout status -n "${NAMESPACE}" deployment/messageboard --timeout=120s

echo "=== Done ==="
