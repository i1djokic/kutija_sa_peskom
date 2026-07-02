# Manual PVC Backup Methods

> **Purpose:** Direct, tool-agnostic methods to back up PVC data without Velero or Longhorn. Useful for ad-hoc backups, small clusters, or when no CSI snapshot support is available.

## 1. kubectl cp

For small amounts of data, copy files directly from a Pod:

```bash
# Single file
kubectl cp default/postgres-0:/var/lib/postgresql/data/dump.sql ./backup.sql

# Directory
kubectl cp default/postgres-0:/var/lib/postgresql/data ./postgres-data/

# Into a pod (restore)
kubectl cp ./backup.sql default/postgres-0:/var/lib/postgresql/data/
```

**Limitations**: Slow for large datasets, no incremental support, requires the Pod to be running.

## 2. rsync via Temporary Pod

Mount the PVC into a temporary Pod and use rsync for efficient transfers:

```bash
# Create a temp Pod that mounts the PVC
kubectl run --rm -it backup-pod --image=ubuntu --restart=Never -- bash

# Inside the Pod
apt update && apt install -y rsync
# rsync to/from external server
rsync -avz /mnt/data user@backup-server:/backups/pvc-name/

# Or use kubectl exec + rsync
kubectl exec -it backup-pod -- rsync -av /mnt/data /backup/destination
```

## 3. Application-Level Dump

Database-consistent backup via application tools:

```bash
# PostgreSQL
kubectl exec -n db deploy/postgres -- pg_dumpall -U postgres > pgdump.sql

# MariaDB / MySQL
kubectl exec -n db deploy/mariadb -- mysqldump -u root -p$PASS --all-databases > dump.sql

# MongoDB
kubectl exec -n db deploy/mongodb -- mongodump --archive > mongo.archive
```

**Restore:**

```bash
# PostgreSQL
kubectl exec -i -n db deploy/postgres -- psql -U postgres < pgdump.sql

# MariaDB
kubectl exec -i -n db deploy/mariadb -- mysql -u root -p$PASS < dump.sql
```

## 4. CSI VolumeSnapshot (No Velero)

If your cluster has a CSI driver with snapshot support, create and restore snapshots directly:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snapshot-class
driver: <your-csi-driver>  # e.g., ebs.csi.aws.com, pd.csi.storage.gke.io
deletionPolicy: Delete
---
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: my-backup-snapshot
spec:
  volumeSnapshotClassName: csi-snapshot-class
  source:
    persistentVolumeClaimName: my-pvc
```

Restore from the snapshot:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-restored
spec:
  dataSource:
    name: my-backup-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io/v1
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## 5. CSI Cloning

Clone a PVC in the same cluster (not a backup per se, but useful for migration):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-clone
spec:
  dataSource:
    name: my-pvc
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## 6. Backup via CronJob (In-Cluster)

Run scheduled backups entirely inside the cluster:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: pvc-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup
              image: alpine:3.19
              command:
                - sh
                - -c
                - |
                  apk add --no-cache rsync
                  rsync -avz /source/ user@backup-server:/backups/$(date +%Y%m%d)/
              volumeMounts:
                - name: data
                  mountPath: /source
          volumes:
            - name: data
              persistentVolumeClaim:
                claimName: my-pvc
```

## When to Use Each Method

| Method | Best for | Data size | Consistency |
|--------|----------|-----------|-------------|
| `kubectl cp` | Quick file copy | Small (<1GB) | Crash-consistent |
| rsync temp pod | Ad-hoc bulk backup | Medium (1-100GB) | Crash-consistent |
| Application dump | Databases | Any | Application-consistent |
| CSI VolumeSnapshot | Cloud CSI volumes | Any | Crash-consistent |
| CSI Clone | In-cluster copy/migration | Any | Crash-consistent |
| CronJob backup | Automated in-cluster | Small-medium | Crash-consistent |
