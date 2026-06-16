# Hello World App

A simple Hello World web application deployed on Kubernetes via Helm.

## Prerequisites

- Kubernetes cluster (Minikube, kind, or any K8s cluster)
- Helm v3+
- Docker (for building the image locally)

## Build & Deploy

### 1. Build the Docker image

From the `apps/helloworld` directory:

```bash
docker build -t helloworld:latest .
```

If using Minikube, load the image into the cluster:

```bash
minikube image load helloworld:latest
```

If using kind, load the image into the cluster:

```bash
kind load docker-image helloworld:latest
```

### 2. Deploy with Helm

```bash
helm upgrade --install helloworld .
```

To deploy with a custom image tag:

```bash
helm upgrade --install helloworld . --set image.tag=latest
```

### 3. Access the app

**Port-forward** to your local machine:

```bash
kubectl port-forward svc/helloworld 8080:80
```

Visit http://localhost:8080 in your browser.

Or if you enabled ingress, add the host to `/etc/hosts` and access via the configured hostname.

## Configuration

Common values you can override:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Docker image repository | `helloworld` |
| `image.tag` | Docker image tag | `latest` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `ingress.enabled` | Enable ingress | `false` |
| `resources.limits.cpu` | CPU limit | `200m` |
| `resources.limits.memory` | Memory limit | `128Mi` |

Set values via `--set` or a custom values file:

```bash
helm upgrade --install helloworld . -f my-values.yaml
```

## Uninstall

```bash
helm uninstall helloworld
```

## Directory Structure

```
apps/helloworld/
├── app/              # Static web content
│   └── index.html    # Hello World page
├── templates/        # Helm templates
│   ├── _helpers.tpl  # Template helpers
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   └── ingress.yaml
├── Chart.yaml        # Chart metadata
├── values.yaml       # Default values
├── Dockerfile        # Container build
├── .helmignore       # Helm packaging ignore rules
└── README.md         # This file
```
