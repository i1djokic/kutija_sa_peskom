# Maintenance & Housekeeping

## Current Issues

### 1. High Pod Restart Count

| Pod | Restarts | Age |
|---|---|---|
| traefik | 6 | 47h |
| svclb-traefik | 6 | 47h |
| mariadb (demo) | 3 | 41h |
| wordpress (demo) | 3 | 41h |
| coredns | 3 | 47h |
| local-path-provisioner | 3 | 47h |
| metrics-server | 3 | 47h |

Many system components have restarted multiple times in 2 days — investigate root cause.

### 2. `wordpress:latest` Tag

**Risk**: Unpredictable image updates. Pinning to `wordpress:6.7` (or similar) ensures controlled upgrades.

### 3. No Update Strategy

- No maintenance windows defined
- No pod disruption budgets
- No node drain/upgrade plan

## Improvements

### 1. Image Tag Policy

| Current | Recommended |
|---|---|
| `wordpress:latest` | `wordpress:6.7` |
| `floci/floci:latest` | `floci/floci:v1.2.3` |
| `127.0.0.1:5000/regui:v2` | OK (specific) |
| `mariadb:11` | `mariadb:11.4` (minor pin) |

### 2. Regular etcd Snapshot Schedule

```bash
# Take a snapshot every 6 hours, retain last 10
0 */6 * * * root k3s etcd-snapshot save \
  --snapshot-retention=10
```

### 3. Node Maintenance Procedure

1. `kubectl cordon k3s-server`
2. `kubectl drain k3s-server --ignore-daemonsets`
3. Perform maintenance
4. `kubectl uncordon k3s-server`

### 4. Cluster Update Plan

| Component | Current | Target | Priority |
|---|---|---|---|
| K3s | v1.35.4+k3s1 | Latest patch | Maintain |
| coredns | 1.14.2 | Latest | Medium |
| traefik | chart-installed | Latest | Medium |
| OS | CentOS Stream 10 | Keep updated | High |

Update K3s:
```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

### 5. Resource Cleanup

- Remove unused ReplicaSets (`floci-67d795f466` has 0 replicas but still exists)
- Remove old Helm release secrets if no longer needed
- Prune unused container images on node
- Check for orphaned PVCs

### 6. Monitoring Disk Usage

```bash
# Check container image disk usage
k3s crictl images

# Check etcd database size
kubectl exec -n kube-system etcd-k3s-server -- \
  du -sh /var/lib/rancher/k3s/server/db/etcd

# Check local-path provisioner storage
du -sh /var/lib/rancher/k3s/storage/
```
