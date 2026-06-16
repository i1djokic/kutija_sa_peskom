# Storage & Backup Improvements

## Current State

| PVC | Namespace | Size | StorageClass | Access Mode |
|---|---|---|---|---|
| floci-data | default | 5Gi | local-path | RWO |
| mariadb-pvc | default | 5Gi | local-path | RWO |
| wordpress-pvc | default | 5Gi | local-path | RWO |
| mariadb-pvc | demo | 5Gi | local-path | RWO |
| wordpress-pvc | demo | 5Gi | local-path | RWO |
| registry-pvc | registry | 50Gi | local-path | RWO |

Total PVC storage: **75 GiB**

## Issues & Improvements

### 1. local-path-provisioner — No Replication

**Problem**: All PVCs use `local-path` (hostPath backed). If the node fails, data is lost. No replication, no snapshots.

**Fix Options**:
| Option | Description |
|---|---|
| Longhorn | Replicated block storage on top of local disks. Supports snapshots, backups, multi-node |
| Rook/Ceph | Production-grade distributed storage. Complex to operate |
| NFS External | Simple, shared storage with external NFS server. No replication |

**Recommended**: Longhorn (built for K3s, lightweight, supports snapshots & backups)
```bash
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

### 2. No Volume Snapshots / Backups

**Fix**: Install the `volumesnapshots` CRDs and configure a backup schedule:

```bash
# After Longhorn is installed
kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta1
kind: VolumeSnapshotClass
metadata:
  name: longhorn-snapshot
driver: driver.longhorn.io
deletionPolicy: Delete
EOF
```

### 3. Registry PVC Size

**Observation**: The registry PVC is 50Gi — verify this is necessary. Overprovisioning wastes local disk space.

**Check**: `kubectl exec -n registry deploy/docker-registry -- du -sh /var/lib/registry`

### 4. No etcd Backup Strategy

K3s with embedded etcd stores all cluster state. No backup mechanism is visible.

**Fix**: Schedule periodic etcd snapshots:
```bash
k3s etcd-snapshot save --name=pre-upgrade-snapshot
```

Add to cron:
```bash
# /etc/cron.d/k3s-etcd-backup
0 */6 * * * root /usr/local/bin/k3s etcd-snapshot save --s3 \
  --s3-bucket=my-backup-bucket \
  --s3-endpoint=s3.amazonaws.com \
  --s3-access-key=... \
  --s3-secret-key=...
```

### 5. StorageClass — Allow Volume Expansion

**Problem**: `local-path` StorageClass has `allowVolumeExpansion: false`. If a PVC runs out of space, it cannot be resized.

**Fix**: Edit the StorageClass:
```bash
kubectl patch storageclass local-path -p '{"allowVolumeExpansion": true}'
```
