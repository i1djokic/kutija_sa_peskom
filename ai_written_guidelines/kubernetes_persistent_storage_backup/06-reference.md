# Reference

## Command Cheat Sheet

### Velero

| Command | Description |
|---------|-------------|
| `velero backup create NAME --include-namespaces NS` | Create an on-demand backup |
| `velero backup get` | List backups |
| `velero backup describe NAME` | Show backup details |
| `velero backup logs NAME` | Show backup logs |
| `velero backup delete NAME` | Delete a backup |
| `velero restore create --from-backup NAME` | Restore from backup |
| `velero schedule create NAME --schedule="0 2 * * *" --ttl 168h` | Schedule recurring backups |
| `velero install --provider aws --bucket BUCKET` | Install Velero in cluster |

### Longhorn

| Command | Description |
|---------|-------------|
| `helm install longhorn longhorn/longhorn -n longhorn-system` | Install Longhorn |
| `kubectl -n longhorn-system get volumes` | List volumes |
| `kubectl -n longhorn-system get backups` | List backups |
| `kubectl apply -f volumesnapshot.yaml` | Create CSI snapshot |
| `curl -X POST http://longhorn:8000/v1/volumes/ID?action=backup` | Trigger backup via API |

### etcd

| Command | Description |
|---------|-------------|
| `k3s etcd-snapshot save --name=NAME` | K3s on-demand snapshot |
| `k3s etcd-snapshot list --s3 --s3-bucket=BUCKET` | List K3s S3 snapshots |
| `etcdctl snapshot save /path/snapshot.db` | etcdctl on-demand snapshot |
| `etcdctl snapshot restore /path/snapshot.db --data-dir=RESTORED` | Restore etcd snapshot |
| `etcdctl snapshot status /path/snapshot.db` | Check snapshot integrity |

### Manual Backup

| Command | Description |
|---------|-------------|
| `kubectl cp NS/POD:PATH ./local` | Copy file from Pod |
| `kubectl exec POD -- pg_dump -U USER DB > dump.sql` | PostgreSQL dump |
| `kubectl exec POD -- mysqldump -u USER -pPASS DB > dump.sql` | MariaDB/MySQL dump |
| `kubectl run --rm -it POD --image=ubuntu` | Temp pod for rsync |

## Tool Comparison

| Tool | Volume data | Cluster resources | Schedule | Restore | Cross-cluster | Learning curve |
|------|-------------|-------------------|----------|---------|---------------|----------------|
| Velero | Yes (snapshot + file) | Yes | Yes | Yes | Yes | Medium |
| Longhorn | Yes (snapshot + backup) | No | Yes | Yes | Yes (S3) | Low |
| etcd snapshot | No | Yes | Via cron | Yes | Yes | Medium |
| CSI VolumeSnapshot | Yes | No | Via CronJob | Yes | No | Low |
| `kubectl cp` | Yes (file-level) | No | Via script | Yes | No | Low |
| Application dump | Yes (data only) | No | Via CronJob | Yes | Yes | Low |

## Storage Provisioner Snapshot Support

| Provisioner | CSI Snapshot | Longhorn Snapshot | Velero + restic |
|-------------|-------------|-------------------|-----------------|
| local-path | No | N/A | Yes (file-level) |
| Longhorn | Yes | Yes | Yes |
| AWS EBS | Yes | N/A | Yes (snapshot) |
| GCE PD | Yes | N/A | Yes (snapshot) |
| Azure Disk | Yes | N/A | Yes (snapshot) |
| Rook/Ceph | Yes | N/A | Yes (snapshot) |
| NFS | No | N/A | Yes (file-level) |

## Backup Frequency Recommendations

| Environment | Backup type | Frequency | Retention |
|-------------|-------------|-----------|-----------|
| Production (critical) | Volume snapshot + app dump | Every 2-4 hours | 7-30 days |
| Production (standard) | Volume snapshot | Daily | 7-14 days |
| Production (all) | Cluster state (etcd) | Every 2-6 hours | 7-30 days |
| Staging / QA | Volume snapshot | Daily | 3-7 days |
| Development | On-demand | As needed | 1-3 backups |

## Restore Checklist

- [ ] Ensure backup exists and is accessible (`velero backup get`, `k3s etcd-snapshot list`)
- [ ] Verify snapshot integrity (`etcdctl snapshot status`, check Longhorn UI)
- [ ] If restoring to a different cluster, check StorageClass compatibility
- [ ] For database backups, ensure target database version matches
- [ ] Test with a dry-run first (`velero restore create --dry-run`)
- [ ] After restore, verify application functionality
- [ ] Update DNS / ingress if cluster endpoint changed
