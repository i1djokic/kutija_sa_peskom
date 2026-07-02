# Longhorn Snapshots & Backups

> **Purpose:** Built-in snapshot and backup engine for Longhorn-managed PVCs. Supports recurring snapshots, backup to S3/NFS, and restore to any cluster.

Longhorn is a lightweight, replicated block storage system for Kubernetes. Unlike `local-path`, Longhorn provides native snapshot and backup capabilities without external tools.

## Installation

```bash
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --set defaultSettings.replicaCount=2
```

## Volume Snapshots

Snapshots are instant, space-efficient point-in-time copies stored on the same node.

### Create a Snapshot via UI

1. Open Longhorn UI (`http://<node-ip>:30080`)
2. Navigate to **Volume** → select a volume
3. Click **Take Snapshot**

### Create a Snapshot via CLI

```bash
# Install longhornctl or use kubectl + Longhorn API
kubectl -n longhorn-system exec -it deploy/longhorn-manager -- \
  longhorn-manager -d snapshot create --volume pvc-abc123
```

### Create a Snapshot via Kubernetes CSI

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: longhorn-snapshot
driver: driver.longhorn.io
deletionPolicy: Delete
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-pvc-snapshot
spec:
  volumeSnapshotClassName: longhorn-snapshot
  source:
    persistentVolumeClaimName: my-pvc
```

## Backups to Remote Storage

Backups are snapshots exported to a remote target (S3, NFS, or S3-compatible).

### Configure Backup Target

Via Longhorn UI:
1. **Setting** → **General** → **Backup Target**
2. Set to e.g. `s3://my-bucket@us-east-1/`
3. Set **Backup Target Credential Secret**

Or via kubectl:

```bash
kubectl -n longhorn-system create secret generic backup-secret \
  --from-literal=AWS_ACCESS_KEY_ID=xxx \
  --from-literal=AWS_SECRET_ACCESS_KEY=yyy

kubectl -n longhorn-system patch settings backup-target \
  --type merge \
  -p '{"value":"s3://my-bucket@us-east-1/"}'
```

### Create a Backup

From the Longhorn UI: **Volume** → select volume → **Backup**.

From CLI (via Longhorn API):

```bash
# Trigger backup via Longhorn API
curl -X POST http://longhorn-frontend.longhorn-system/v1/volumes/pvc-abc123?action=backup
```

## Recurring Snapshots & Backups

Longhorn supports cron-based recurring jobs:

```yaml
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: daily-backup
  namespace: longhorn-system
spec:
  cron: "0 2 * * *"
  task: "snapshot"  # or "backup"
  retain: 7
  concurrency: 1
  labels:
    schedule: daily
```

Apply to a volume:

```bash
kubectl -n longhorn-system label volume pvc-abc123 recurring-job-group.longhorn.io/default=daily-backup
```

Or create a recurring job via UI: **Recurring Job** → **Create**.

## Restoring

From a snapshot (in-cluster, instant):

```bash
# Create a new volume from a snapshot
# Longhorn UI: Volume → snapshot → Revert
```

From a backup (cross-cluster restore):

```bash
# Longhorn UI: Backup → select backup → Restore
# Creates a new PV/PVC from the backup
```

## Backup Comparison

| Feature | Snapshot | Backup |
|---------|----------|--------|
| Location | Same node | Remote (S3/NFS) |
| Speed | Instant | Network-bound |
| Space | Space-efficient (differential) | Full + incremental |
| Survives node loss | No | Yes |
| Cross-cluster restore | No | Yes |
| Retention policy | Recurring job | Recurring job |

## Monitoring

```bash
# List all backups
kubectl -n longhorn-system get backups

# List all snapshots for a volume
kubectl -n longhorn-system get volumes -o yaml

# Longhorn UI dashboard
# http://<node-ip>:30080
```
