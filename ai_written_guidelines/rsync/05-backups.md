# Backups

Rsync is ideal for backups — it's incremental, can use hard links for deduplication, and preserves file attributes.

## --backup and --backup-dir

Save replaced or deleted files to a backup directory instead of removing them:

```bash
# Save backups of replaced files to a .backup directory in the destination
rsync -av --backup /src/ /dst/

# Save backups to a specific directory
rsync -av --backup --backup-dir=/backups/$(date +%Y-%m-%d) /src/ /dst/
```

## Incremental Backups with --link-dest

The most powerful backup technique. `--link-dest` creates hard links to unchanged files from a previous backup, so each backup is a full snapshot but only stores changed files.

```bash
# First backup
rsync -av /src/ /backups/2024-01-01/

# Second backup — files unchanged from 2024-01-01 become hard links
rsync -av --link-dest=/backups/2024-01-01 /src/ /backups/2024-01-02/

# Third backup
rsync -av --link-dest=/backups/2024-01-02 /src/ /backups/2024-01-03/
```

Each backup directory looks like a complete copy, but unchanged files share disk space via hard links.

### Backup Script

```bash
#!/bin/bash
# Usage: ./backup.sh /source/path

set -e
SOURCE="$1"
BACKUP_ROOT="/backups"
DATE=$(date +%Y-%m-%d)
LATEST=$(ls -1 "$BACKUP_ROOT" | tail -1)

LINK_DEST=""
if [ -n "$LATEST" ]; then
    LINK_DEST="--link-dest=$BACKUP_ROOT/$LATEST"
fi

rsync -avh --delete $LINK_DEST "$SOURCE" "$BACKUP_ROOT/$DATE/"
```

## Snapshot Rotation

Keep a rolling set of snapshots:

```bash
#!/bin/bash
# Rotate: keep daily backups for 7 days

BACKUP_ROOT="/backups"
SOURCE="/home/user/data"
DATE=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

# Create today's backup using yesterday's as link-dest
rsync -avh --delete \
    --link-dest="$BACKUP_ROOT/$YESTERDAY" \
    "$SOURCE" "$BACKUP_ROOT/$DATE/"

# Remove backups older than 7 days
find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
```

## Remote Backups

Back up a remote server to local storage:

```bash
# Pull backup from remote
rsync -avz --delete user@server:/important/data/ /local/backups/server-data/

# With link-dest for incrementals
rsync -avz --delete \
    --link-dest=/local/backups/server-data/previous \
    user@server:/important/data/ \
    /local/backups/server-data/$(date +%Y-%m-%d)/
```

## Backup Best Practices

1. **Always use `--dry-run`** before deleting anything
2. **Use `--link-dest`** for space-efficient snapshots
3. **Back up to a separate drive or server** (not the same disk)
4. **Verify backups** by doing a test restore periodically
5. **Compress for remote backups** with `-z`
6. **Combine with `--exclude`** to skip caches, logs, and temp files
