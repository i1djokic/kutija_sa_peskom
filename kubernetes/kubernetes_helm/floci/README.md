# Floci Helm Chart

[Floci](https://floci.io/) — Fast, free, open-source AWS emulator built with Quarkus Native. Drop-in replacement for LocalStack.

## Quick Start

```bash
helm install floci ./floci

# Get the LoadBalancer IP
kubectl get svc floci
```

Configure AWS CLI:

```bash
export AWS_ENDPOINT_URL=http://<loadbalancer-ip>:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
aws s3 mb s3://my-bucket
```

## Configuration

### Service Type

Default is `LoadBalancer`. Change to `ClusterIP` or `NodePort`:

```bash
helm upgrade floci ./floci --set service.type=ClusterIP
```

For ClusterIP, port-forward:

```bash
kubectl port-forward svc/floci 4566:4566
```

### Docker Socket (for Lambda, ECS, EKS, EC2, RDS, etc.)

Services that launch real Docker containers require the Docker socket:

```bash
helm upgrade floci ./floci --set dockerSocket.enabled=true
```

### Persistence

```bash
helm upgrade floci ./floci \
  --set persistence.enabled=true \
  --set config.storageMode=hybrid
```

### Ingress

```bash
helm upgrade floci ./floci \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=aws.local.test
```

## Fix: CrashLoopBackOff due to `FLOCI_PORT` env var

### Problem

The pod crashed on startup with:

```
Configuration validation failed:
  java.lang.IllegalArgumentException: SRCFG00039: The config property floci.port
  with the config value "tcp://10.43.7.85:4566" threw an Exception whilst being
  converted SRCFG00029: Expected an integer value, got "tcp://10.43.7.85:4566"
```

**Root cause:** Kubernetes injects `<SERVICE_NAME>_PORT` environment variables into pods for every service in the namespace. When the service is named `floci`, Kubernetes sets `FLOCI_PORT=tcp://<cluster-ip>:4566`. Floci (built on Quarkus) reads `FLOCI_PORT` as the config property `floci.port`, which expects an integer, not a protocol-prefixed string like `tcp://10.43.7.85:4566`.

### Fix

Two changes in `templates/deployment.yaml`:

1. **`enableServiceLinks: false`** — disables Kubernetes from injecting service environment variables into the pod, preventing `FLOCI_PORT` from being set automatically.

2. **Explicit `FLOCI_PORT: "4566"`** — sets the port explicitly as a safety override.

## Values

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | `1` | Number of replicas |
| `image.repository` | `floci/floci` | Image repository |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `image.tag` | `""` (chart appVersion) | Image tag |
| `service.type` | `LoadBalancer` | Kubernetes service type |
| `service.port` | `4566` | Service port |
| `service.nodePort` | `""` | Node port (when type is NodePort) |
| `service.annotations` | `{}` | Service annotations |
| `config.storageMode` | `memory` | Storage mode: `memory`, `filesystem`, or `hybrid` |
| `config.hostname` | `aws.local.test` | Hostname for `AWS_ENDPOINT_URL` |
| `config.tlsEnabled` | `false` | Enable TLS/HTTPS |
| `config.logLevel` | `INFO` | Log level |
| `config.localstackCompat` | `true` | Translate LocalStack env vars |
| `dockerSocket.enabled` | `false` | Mount Docker socket |
| `persistence.enabled` | `false` | Enable persistent volume |
| `persistence.size` | `5Gi` | PV size |
| `ingress.enabled` | `false` | Enable ingress |
| `ingress.hosts` | `[{host: aws.local.test}]` | Ingress hosts |
| `resources.limits.memory` | `512Mi` | Memory limit |
| `resources.requests.cpu` | `100m` | CPU request |
| `resources.requests.memory` | `128Mi` | Memory request |
| `autoscaling.enabled` | `false` | Enable HPA |
| `extraEnv` | `[]` | Additional environment variables |
