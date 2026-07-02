# Backup Strategies Overview

## Why Backup Persistent Storage?

Kubernetes persistent storage (PVCs) holds critical application data — databases, file stores, registry contents, and application state. Unlike stateless Pods, data in PVCs survives Pod restarts but is vulnerable to:

- Node failure (especially with `local-path` / `hostPath` storage)
- Accidental PVC deletion
- Application-level corruption or misconfiguration
- Cluster-wide disaster

## Types of Backup

| Type | What it protects | Tooling |
|------|-----------------|---------|
| **Volume snapshots** | PV data at a point in time | CSI `VolumeSnapshot`, Velero, Longhorn |
| **Application-level backup** | Consistent data (e.g., DB dump) | `pg_dump`, `mysqldump`, `mongodump` |
| **Cluster state backup** | Kubernetes resources (PVCs, Deployments, Secrets) | Velero, etcd snapshot, `kubectl get --all-namespaces` |
| **Full disaster recovery** | Entire cluster + data | Velero + etcd snapshot + Infrastructure-as-Code |

## Storage Provisioner Considerations

| Provisioner | Replication | Snapshots | Backups | Recommended for |
|-------------|-------------|-----------|---------|-----------------|
| `local-path` (hostPath) | None | No | No | Dev / learning only |
| Longhorn | Yes (1-3 replicas) | Yes | Yes (S3/NFS) | K3s, edge, on-prem |
| Rook/Ceph | Yes | Yes | Yes (via Rados GW) | Production on-prem |
| Cloud CSI (EBS, EFS, GCE PD) | Provider-managed | Yes | Via Velero | Cloud production |
| NFS | None | No | Filesystem-level | Shared RWX workloads |

## Key Decisions

- **Backup frequency** — how much data can you afford to lose? (RPO)
- **Restore time** — how fast must you recover? (RTO)
- **Backup storage location** — same cluster, separate cluster, or off-site (S3, NFS)?
- **Consistency** — crash-consistent vs application-consistent backups

## Common Toolchain

```bash
# 1. Application-level dump (example: PostgreSQL)
kubectl exec -n db deploy/postgres -- pg_dump -U admin mydb > dump.sql

# 2. Volume snapshot (CSI)
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-pvc-snapshot
spec:
  volumeSnapshotClassName: csi-snapshot-class
  source:
    persistentVolumeClaimName: my-pvc
EOF

# 3. Cluster resources backup
kubectl get all --all-namespaces -o yaml > cluster-resources.yaml
```
