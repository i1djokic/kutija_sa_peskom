# etcd Backup

> **Purpose:** Protect Kubernetes cluster state — all API objects (Deployments, ConfigMaps, Secrets, PVCs as API resources, RBAC) are stored in etcd. Without an etcd backup, you cannot recover the cluster control plane after a disaster.

etcd backups do **not** include PVC data — they back up the resource definitions only. Combine with Velero or volume backups for full recovery.

## etcd in Different Kubernetes Distributions

| Distribution | etcd type | Backup command |
|--------------|-----------|----------------|
| kubeadm | External etcd static pod | `etcdctl snapshot save` |
| K3s | Embedded etcd | `k3s etcd-snapshot save` |
| RKE2 | Embedded etcd | `rke2 etcd-snapshot save` |
| Managed (EKS/AKS/GKE) | Managed by provider | Cloud provider backup |

## K3s Embedded etcd

### On-Demand Snapshot

```bash
k3s etcd-snapshot save --name=pre-upgrade-snapshot
```

Snapshots are stored in `/var/lib/rancher/k3s/server/db/snapshots/`.

### Scheduled Backup via Cron

```bash
cat > /etc/cron.d/k3s-etcd-backup << 'EOF'
0 */6 * * * root /usr/local/bin/k3s etcd-snapshot save \
  --s3 \
  --s3-bucket=my-backup-bucket \
  --s3-endpoint=s3.amazonaws.com \
  --s3-access-key=AKIA... \
  --s3-secret-key=...
EOF
```

K3s also supports built-in recurring snapshots:

```bash
# Enable automatic snapshots (every 12 hours, retain 5)
# In /etc/rancher/k3s/config.yaml:
etcd-snapshot-schedule-cron: "0 */12 * * *"
etcd-snapshot-retention: 5
etcd-s3: true
etcd-s3-bucket: my-backup-bucket
etcd-s3-endpoint: s3.amazonaws.com
etcd-s3-access-key: AKIA...
etcd-s3-secret-key: ...
```

### Restore from Snapshot

```bash
# Stop K3s
systemctl stop k3s

# Restore from snapshot
k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=/var/lib/rancher/k3s/server/db/snapshots/<snapshot-file>

# Start K3s
systemctl start k3s
```

## kubeadm / External etcd

### Install etcdctl

```bash
# Download etcd client
ETCD_VER=v3.5.13
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzf etcd-${ETCD_VER}-linux-amd64.tar.gz
sudo cp etcd-${ETCD_VER}-linux-amd64/etcdctl /usr/local/bin/
```

### Create Snapshot

```bash
# With etcd pod running
kubectl -n kube-system exec etcd-master -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db
```

### Restore Snapshot

```bash
# Restore to a new data directory
etcdctl snapshot restore /var/lib/etcd/snapshot.db \
  --data-dir=/var/lib/etcd-restored \
  --name=master \
  --initial-cluster=master=https://127.0.0.1:2380 \
  --initial-cluster-token=etcd-cluster

# Point etcd to the restored data directory
# Edit /etc/kubernetes/manifests/etcd.yaml → update hostPath
```

## Managed Kubernetes (EKS / AKS / GKE)

| Provider | Backup method |
|----------|---------------|
| EKS | etcd is managed by AWS — no direct access. Use Velero for resource backup |
| AKS | etcd is managed by Azure — no direct access. Use Velero |
| GKE | etcd is managed by GCP — no direct access. Use Velero |

For managed clusters, use **Velero** to back up Kubernetes resources (which are the etcd data in managed environments).

## Best Practices

- **Schedule**: Every 2-6 hours for production
- **Retention**: Keep at least 7 daily snapshots
- **Storage**: Store off-cluster (S3, object storage) — a snapshot on the same node is useless if the node dies
- **Test restores**: Regularly verify that snapshots can be restored to a working cluster
- **Before upgrades**: Always take a manual snapshot before upgrading Kubernetes

## Monitoring

```bash
# K3s: list local snapshots
ls -lh /var/lib/rancher/k3s/server/db/snapshots/

# K3s: list S3 snapshots
k3s etcd-snapshot list --s3 --s3-bucket=my-backup-bucket

# etcdctl: check snapshot integrity
etcdctl snapshot status /path/to/snapshot.db
```
