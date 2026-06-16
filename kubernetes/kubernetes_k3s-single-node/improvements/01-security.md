# Security Improvements

## Critical Issues

### 1. Docker Socket Mounted in Floci Pod

**Problem**: `floci` pod mounts `/var/run/docker.sock` (host Docker socket). This gives the container root-level access to the Docker daemon on the host, effectively breaking container isolation.

**Impact**: Full host compromise if the container is breached.

**Fix**:
- Remove Docker socket mount
- Use Kubernetes-native APIs or rootless containers
- If Docker-in-Docker is required, use `sysbox` or `kaniko`

### 2. Containers Running as Root

| Pod | Container runs as root |
|---|---|
| floci | Yes (runAsUser: 0) |
| coredns | Yes (unset, defaults to 0) |
| svclb-\* | Yes (unset, defaults to 0) |
| traefik | Yes (unset, defaults to 0) |

**Fix**: Set `runAsNonRoot: true` and `runAsUser: <non-zero>` in securityContext. Use distroless or scratch images where possible.

### 3. No Pod Security Standards (PSA)

**Problem**: No `pod-security.kubernetes.io` labels on any namespace.

**Fix**:
```bash
kubectl label ns default pod-security.kubernetes.io/enforce=restricted
kubectl label ns default pod-security.kubernetes.io/audit=restricted
kubectl label ns default pod-security.kubernetes.io/warn=restricted
```
Start with `baseline` and iterate toward `restricted`.

### 4. WordPress Secrets in Plain Text

**Problem**: WordPress DB credentials (`demo`, `demo123`) are passed via environment variables directly in the Deployment manifest (plain text).

**Fix**: Use a Secret (already exists `mariadb-secret` in `default` ns) and reference via `envFrom` or `valueFrom.secretKeyRef`.

### 5. No Network Policies

**Problem**: Only 2 basic NetworkPolicies exist (`mariadb-restrict` in `default` and `demo`). No default deny-ingress/egress policies.

**Fix**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Medium Issues

### 6. No ResourceQuotas or LimitRanges

**Problem**: No resource caps per namespace — a single namespace can exhaust cluster resources.

**Fix**:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: default
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
```

### 7. No TLS for Internal Services

**Problem**: TLS secrets exist (`registry-tls`, `demo-tls`) but no services enforce HTTPS. Traefik handles external termination but internal traffic is plain HTTP.

**Fix**: Enable mTLS with Linkerd or Istio, or use Traefik's built-in middleware.

### 8. No Pod Disruption Budgets

**Problem**: All single-replica deployments can be disrupted during node maintenance.

**Fix**:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: wordpress-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: wordpress
```

## Low Issues

### 9. Secrets Data Size

The `mariadb-secret` has only 4 keys — ensure all DB connection parameters are in secrets, not in plain-text env vars.
