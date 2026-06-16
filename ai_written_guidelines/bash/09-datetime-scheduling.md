# Datetime & Scheduling

## date — The Swiss Army Knife

```bash
# Current time
date                          # Thu Jun 4 12:34:56 UTC 2026
date +%Y-%m-%d                # 2026-06-04
date +%Y-%m-%dT%H:%M:%S%z    # 2026-06-04T12:34:56+0000 (ISO 8601)

# Past/future
date -d "yesterday" +%F
date -d "7 days ago" +%F
date -d "next Monday" +%F
date -d "@1717500000" +%F     # convert epoch to date

# Epoch
date +%s                      # current epoch
date -d "2026-01-01" +%s      # epoch of specific date

# Cross-platform (macOS uses different flags)
# Linux:
date -d "@$epoch" +%Y-%m-%d
# macOS:
date -r "$epoch" +%Y-%m-%d

# Timestamp for filenames/backups
backup_name="backup-$(date +%Y-%m-%d_%H%M%S).tar.gz"
```

## cron — Scheduled Tasks

```bash
# Crontab format: minute hour day month weekday command
# Edit crontab
crontab -e

# Common patterns
*/5 * * * * /opt/scripts/healthcheck.sh       # every 5 minutes
0 * * * * /opt/scripts/hourly-rotate.sh       # every hour
0 2 * * * /opt/scripts/daily-backup.sh        # 2 AM daily
0 0 * * 0 /opt/scripts/weekly-cleanup.sh      # midnight Sunday
0 0 1 * * /opt/scripts/monthly-report.sh      # 1st of month

# Redirect output (always!)
0 * * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1

# Environment in cron is minimal — set PATH explicitly
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 2 * * * /opt/scripts/backup.sh

# List current crontab
crontab -l

# Remove crontab
crontab -r

# Install from file
crontab mycron.txt
```

## systemd Timers (Modern Replacement for cron)

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Daily backup

[Service]
Type=oneshot
ExecStart=/opt/scripts/backup.sh
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"

# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily at 2am

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload
systemctl enable backup.timer
systemctl start backup.timer
systemctl list-timers
```

## at — One-Time Jobs

```bash
at now + 1 hour -f /opt/scripts/deploy.sh
at 10:00 tomorrow -f /opt/scripts/cleanup.sh
atq                           # list pending jobs
atrm 5                        # remove job 5
```

## Time Math

```bash
# Duration between two dates (seconds)
start=$(date +%s)
# ... do work ...
end=$(date +%s)
elapsed=$(( end - start ))
echo "Took ${elapsed}s"

# Days between dates
d1="2026-01-01"
d2="2026-06-04"
secs=$(( $(date -d "$d2" +%s) - $(date -d "$d1" +%s) ))
days=$(( secs / 86400 ))
```

## Log File Rotation (Manual)

```bash
# Keep 7 days of logs
logdir="/var/log/myapp"
find "$logdir" -name "*.log" -mtime +7 -delete

# Archive current log with timestamp
mv "$logdir/app.log" "$logdir/app-$(date +%Y%m%d).log"
gzip "$logdir/app-$(date +%Y%m%d).log"
> "$logdir/app.log"  # truncate (not delete)
```
