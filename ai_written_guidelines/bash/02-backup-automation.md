# Backup Automation

## File Backup with rsync

```bash
# Local backup
rsync -av --delete /home/user/ /backup/home/user/

# To remote host
rsync -avz --delete -e ssh /data/ backup@remote:/backup/data/

# Exclude patterns
rsync -av --delete \
    --exclude='*.tmp' \
    --exclude='.cache/' \
    --exclude='node_modules/' \
    /project/ /backup/project/

# Dry run (test before executing)
rsync -av --delete --dry-run /source/ /dest/

# Incremental backup with hard links (time machine style)
rsync -av --delete \
    --link-dest="../latest" \
    /source/ "/backup/$(date +%Y%m%d)/"
ln -snf "$(date +%Y%m%d)" /backup/latest
```

## Archive with tar

```bash
# Compress directory
tar czf "/backup/project-$(date +%Y%m%d).tar.gz" /path/to/project/

# Exclude patterns
tar czf backup.tar.gz \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='cache/' \
    /project/

# Pipe to remote
tar czf - /data/ | ssh backup@remote "cat > /backup/data-$(date +%Y%m%d).tar.gz"

# Split into chunks (for large files)
tar czf - /data/ | split -b 1G - "/backup/data-$(date +%Y%m%d).tar.gz.part"
```

## Database Backups

```bash
# PostgreSQL
pg_dump -Fc mydb > "mydb-$(date +%Y%m%d).dump"         # custom format (restore with pg_restore)
pg_dump mydb | gzip > "mydb-$(date +%Y%m%d).sql.gz"    # SQL + gzip

# MySQL/MariaDB
mysqldump --single-transaction mydb | gzip > "mydb-$(date +%Y%m%d).sql.gz"

# SQLite
sqlite3 /var/lib/mydb/data.db ".backup '/backup/data-$(date +%Y%m%d).db'"

# MongoDB
mongodump --db mydb --archive="mydb-$(date +%Y%m%d).archive" --gzip
```

## Backup Rotation

```bash
# Keep last 7 daily backups
find /backup/ -maxdepth 1 -type f -name "*.tar.gz" -mtime +7 -delete

# Keep: 7 daily, 4 weekly, 12 monthly
rotate_backups() {
    local dir="$1"

    # Daily: keep last 7
    find "$dir" -maxdepth 1 -type f -mtime +7 -delete

    # Weekly: keep last 4 weeks on Sundays
    # ... handled by naming convention or separate cron job
}
```

## Sync to Object Storage

```bash
# AWS S3
aws s3 sync /backup/ s3://my-backups/ --delete

# With server-side encryption
aws s3 sync /backup/ s3://my-backups/ --sse AES256

# Lifecycle policy for S3 (set via console or CLI)
# aws s3api put-bucket-lifecycle-configuration --bucket my-backups --lifecycle-configuration file://lifecycle.json

# S3 lifecycle rules: transition to Glacier after 30d, expire after 365d
```

## Backup Verification

```bash
# Check archive integrity
verify_backup() {
    local file="$1"
    case "$file" in
        *.tar.gz) gunzip -t "$file" && tar tzf "$file" > /dev/null ;;
        *.gz)     gunzip -t "$file" ;;
        *.dump)   pg_restore -l "$file" > /dev/null 2>&1 ;;
        *)        sha256sum -c "${file}.sha256" ;;
    esac
    echo "Backup verified: $file"
}

# Generate checksum alongside backup
sha256sum backup.tar.gz > backup.tar.gz.sha256

# Verify later
sha256sum -c backup.tar.gz.sha256
```

## Full Backup Script Template

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="/backup/$(date +%Y%m%d)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# Database
pg_dump -Fc mydb > "$BACKUP_DIR/mydb_${TIMESTAMP}.dump"

# Files
tar czf "$BACKUP_DIR/data_${TIMESTAMP}.tar.gz" /var/lib/myapp/data/

# Checksum
sha256sum "$BACKUP_DIR"/* > "$BACKUP_DIR/checksums.sha256"

# Rotate local (keep 7 days)
find /backup/ -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# Sync to remote
aws s3 sync /backup/ s3://my-backups/ --delete

echo "Backup complete: $BACKUP_DIR"
```
