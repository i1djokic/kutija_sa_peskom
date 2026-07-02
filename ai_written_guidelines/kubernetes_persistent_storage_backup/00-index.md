# Kubernetes Persistent Storage Backup

A comprehensive guide to backing up Kubernetes persistent storage — covering tools, strategies, and procedures for protecting PVC data and cluster state.

## Contents

| File | Topic | Description |
|------|-------|-------------|
| [01-overview.md](./01-overview.md) | Backup Strategies | Why backup matters, types of backup, architecture decisions |
| [02-velero.md](./02-velero.md) | Velero | Industry-standard backup tool — PV snapshots, scheduled backups, S3 storage |
| [03-longhorn.md](./03-longhorn.md) | Longhorn Snapshots & Backups | Built-in snapshot/backup engine for Longhorn-backed PVCs |
| [04-etcd-backup.md](./04-etcd-backup.md) | etcd Backup | Protecting cluster state with etcd snapshots |
| [05-manual-methods.md](./05-manual-methods.md) | Manual PVC Backup | Direct methods — kubectl cp, rsync, volumesnapshots, CSI cloning |
| [06-reference.md](./06-reference.md) | Quick Reference | Command cheat sheet, comparison tables, common flags |

## Quick Start

```bash
# Velero — backup all PVCs in a namespace
velero backup create my-backup --include-namespaces default

# Longhorn — create volume snapshot
kubectl apply -f snapshot.yaml

# etcd snapshot (K3s)
k3s etcd-snapshot save --name=pre-upgrade-backup

# List snapshots
velero backup get
```

## Resources

- [Velero Documentation](https://velero.io/docs/)
- [Longhorn Backups](https://longhorn.io/docs/1.6.0/snapshots-and-backups/)
- [etcd Disaster Recovery](https://etcd.io/docs/latest/op-guide/recovery/)
