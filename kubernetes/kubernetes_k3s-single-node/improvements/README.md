# K3s Single-Node Cluster — Improvement Report

> **Cluster**: k3s-server (control-plane only)
> **Node**: CentOS Stream 10, arm64, 2 vCPU, 3.8 GiB RAM
> **Generated**: May 21, 2026

## Priority Matrix

| Priority | Category | Key Actions |
|---|---|---|
| 🔴 Critical | Security | Fix Docker socket mount, PSA labels, secrets in env vars |
| 🔴 Critical | Availability | Add HA nodes, increase replicas, add probes |
| 🟡 High | Observability | Fix metrics-server, install Prometheus + Grafana |
| 🟡 High | Backup | Schedule etcd snapshots, consider Longhorn for storage |
| 🟢 Medium | Networking | Configure Ingress, TLS, remove unnecessary LoadBalancers |
| 🟢 Medium | Deployments | Pin image versions, add resource limits, standardize labels |
| 🔵 Low | Housekeeping | Cleanup old RS, prune images, document procedures |

## Documents

| File | Description |
|---|---|
| [00-cluster-overview.md](./00-cluster-overview.md) | Current cluster inventory and topology |
| [01-security.md](./01-security.md) | Security issues and fixes (Docker socket, root containers, PSA, etc.) |
| [02-availability-and-resilience.md](./02-availability-and-resilience.md) | Single-node risks, probes, HPA, PDB |
| [03-observability.md](./03-observability.md) | Monitoring, logging, alerting, audit |
| [04-storage-and-backup.md](./04-storage-and-backup.md) | PVCs, etcd backups, volume snapshots |
| [05-deployment-practices.md](./05-deployment-practices.md) | Image tags, resource limits, init containers, labels |
| [06-networking-and-ingress.md](./06-networking-and-ingress.md) | Ingress, TLS, rate limiting, service types |
| [07-maintenance-and-housekeeping.md](./07-maintenance-and-housekeeping.md) | Update strategy, cleanups, restart investigation |

## Quick Wins (Can be done in < 30 min)

1. Add PSA labels to all namespaces — `01-security.md`
2. Pin WordPress image version — `05-deployment-practices.md`
3. Add ResourceQuota / LimitRange for each namespace — `01-security.md`
4. Change `revisionHistoryLimit` to 2-3 — `05-deployment-practices.md`
5. Add liveness/readiness probes to MariaDB, WordPress, Floci — `02-availability-and-resilience.md`
6. Schedule etcd snapshot cron — `04-storage-and-backup.md`
7. Remove unused LoadBalancer services, use Ingress — `06-networking-and-ingress.md`

## Medium-Term (1-2 days)

1. Replace Docker socket with K8s-native approach — `01-security.md`
2. Install Prometheus/Grafana — `03-observability.md`
3. Configure Ingress with TLS — `06-networking-and-ingress.md`
4. Add 2 more nodes for HA — `02-availability-and-resilience.md`
5. Migrate to Longhorn for replicated storage — `04-storage-and-backup.md`

## Long-Term (1+ weeks)

1. Full monitoring + alerting + logging stack — `03-observability.md`
2. Multi-node HA with etcd quorum — `02-availability-and-resilience.md`
3. Implement GitOps (ArgoCD / Flux) — future topic
4. Cluster autoscaling (Karpenter / Cluster Autoscaler) — future topic
5. Service mesh (Linkerd / Istio) — `06-networking-and-ingress.md`
