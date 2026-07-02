# Velero

> **Purpose:** Back up and restore Kubernetes cluster resources and persistent volumes to object storage.

Velero is the industry-standard tool for Kubernetes backup and disaster recovery. It captures both cluster resources (Deployments, Services, PVCs, Secrets) and PV data via CSI snapshots or `restic`/`kopia` file-level backups.

## Installation

```bash
# Install CLI (macOS)
brew install velero

# Install in-cluster components with S3-compatible storage
velero install \
  --provider aws \
  --bucket my-backup-bucket \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1 \
  --use-volume-snapshots=true \
  --plugins velero/velero-plugin-for-aws:v1.9
```

Supported providers: AWS, GCP, Azure, MinIO, DigitalOcean Spaces, Ceph RadosGW — any S3-compatible object store.

## Creating Backups

### On-Demand Backup

```bash
# Backup everything in a namespace
velero backup create daily-backup --include-namespaces default

# Backup specific resources
velero backup create specific-backup \
  --include-resources deployments,statefulsets,pvc \
  --include-namespaces default

# Backup with label selector
velero backup create label-backup --selector app=postgres
```

### Scheduled Backup

```bash
# Daily at 2am, retain 7 backups
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --include-namespaces default \
  --ttl 168h
```

## Excluding Resources

```bash
# Exclude specific resources
velero backup create no-temp \
  --exclude-resources pods \
  --exclude-namespaces kube-system

# Use a label selector to include only specific apps
velero backup create app-backup --selector app in (postgres, redis, mariadb)
```

## Restoring

```bash
# Restore from a backup
velero restore create --from-backup daily-backup

# Restore specific items
velero restore create --from-backup daily-backup \
  --include-resources pvc,deployment \
  --namespace-mappings default:restored-default

# Dry-run
velero restore create --from-backup daily-backup --dry-run
```

## Backup Storage Options

| Backend | Configuration | Use case |
|---------|--------------|----------|
| AWS S3 | `--provider aws` | Cloud production |
| MinIO | `--provider aws` (S3-compatible) | On-prem / lab |
| GCS | `--provider gcp` | GCP production |
| Azure Blob | `--provider azure` | Azure production |
| Local (NFS/volume) | `file://` backup location via restic | Small clusters |

## Restic / Kopia (File-Level Backups)

When CSI snapshots aren't available (e.g., `local-path` provisioner), Velero falls back to file-level backup via restic or kopia:

```bash
# Install with restic
velero install --use-restic ...

# Annotate pods to include in restic backup
kubectl -n default annotate pod/postgres-0 backup.velero.io/backup-volumes=data
```

## Monitoring

```bash
# List backups
velero backup get

# Describe a backup
velero backup describe daily-backup

# Check logs
velero backup logs daily-backup

# List schedules
velero schedule get
```

## Cleanup

```bash
# Delete a backup
velero backup delete daily-backup

# Delete all backups in a schedule
velero schedule delete daily-backup

# Uninstall Velero
velero uninstall
```
