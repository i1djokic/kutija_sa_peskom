# Availability & Resilience Improvements

## Critical Issues

### 1. Single Node Cluster

**Problem**: Single control-plane node with no worker nodes. Any node failure leads to complete cluster outage.

**Fix**:
- Add 2+ additional nodes (control-plane or worker)
- Use `k3s server --cluster-init` for embedded etcd HA
- Minimum 3 nodes for etcd quorum

### 2. All Workloads at Single Replica

**Problem**: Every deployment runs exactly 1 replica. Restarts cause downtime.

**Fix**: Increase replicas to 2+ for stateless workloads (floci, wordpress, regui).

## Medium Issues

### 3. Missing Liveness/Readiness Probes

**Pods without probes:**

| Pod | Missing Probes |
|---|---|
| mariadb | Liveness, Readiness |
| wordpress | Liveness, Readiness |
| floci | Liveness, Readiness |
| docker-registry | Liveness, Readiness |
| regui | Liveness, Readiness |

**Impact**: Kubelet can't detect and restart hanging pods.

**Fix**: Add probes:
```yaml
livenessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 5
  periodSeconds: 5
```

### 4. metrics-server Readiness Probe Failing

**Observation**: Metrics-server readiness probe returns HTTP 500.

**Impact**: Metrics-server shows as not ready, potentially affecting `kubectl top` reliability.

**Check**:
```bash
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### 5. No Pod Anti-Affinity

**Problem**: Pods are scheduled without any anti-affinity rules. In a multi-node cluster this could lead to all replicas on the same node.

**Fix**:
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: wordpress
        topologyKey: kubernetes.io/hostname
```

### 6. No Horizontal Pod Autoscaler (HPA)

**Problem**: No HPAs configured for any workload — no auto-scaling under load.

**Fix**:
```bash
kubectl autoscale deployment wordpress -n demo --cpu-percent=70 --min=1 --max=5
```

## Low Issues

### 7. RollingUpdate Strategy Not Optimized

The default `maxSurge: 25%` / `maxUnavailable: 25%` with 1 replica means no room for rolling updates without disruption. Set `maxUnavailable: 0` and `maxSurge: 1` for zero-downtime.
