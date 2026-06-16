# Log Management

## Log Rotation with logrotate

```bash
# /etc/logrotate.d/myapp
/var/log/myapp/*.log {
    daily                    # rotate daily
    missingok                # no error if missing
    rotate 14                # keep 14 days
    compress                 # gzip old logs
    delaycompress            # compress on next cycle
    notifempty               # skip if empty
    copytruncate             # copy & truncate (app keeps writing)
    postrotate
        systemctl reload myapp > /dev/null 2>&1 || true
    endscript
}

# Test configuration
logrotate -d /etc/logrotate.d/myapp   # dry run

# Force rotation
logrotate -f /etc/logrotate.d/myapp
```

## Manual Log Rotation

```bash
# For apps that don't use logrotate
rotate_log() {
    local logfile="$1" max="${2:-5}"

    # Remove oldest
    [[ -f "${logfile}.${max}" ]] && rm -f "${logfile}.${max}"

    # Shift
    for i in $(seq "$max" -1 1); do
        prev=$((i - 1))
        [[ -f "${logfile}.${prev}" ]] && mv "${logfile}.${prev}" "${logfile}.${i}"
    done

    # Rotate current
    [[ -f "$logfile" ]] && mv "$logfile" "${logfile}.1"

    # Signal app to reopen log
    kill -USR1 "$(pidof myapp)" 2>/dev/null || true
}
```

## Real-Time Log Tail & Filter

```bash
# Basic tail
tail -f /var/log/syslog
tail -f /var/log/nginx/access.log | cut -d' ' -f1,7

# Filter in real time
tail -F /var/log/syslog | grep --line-buffered -E "ERROR|CRIT" | while read -r line; do
    # Alert or trigger action
    echo "$line" | mail -s "CRITICAL on $HOSTNAME" ops@example.com
done

# Multiple logs
tail -F /var/log/nginx/{access,error}.log

# Colored output
tail -f /var/log/syslog | grep --color=always -E "ERROR|CRIT|$"
```

## Log Archival

```bash
# Archive by date
archive_date=$(date -d "yesterday" +%Y%m%d)
tar czf "/backup/logs/syslog-${archive_date}.tar.gz" /var/log/syslog*
gzip /var/log/syslog
> /var/log/syslog  # truncate

# Archive to S3
tar czf - /var/log/myapp/ | aws s3 cp - "s3://my-logs/$(hostname)/$(date +%Y/%m/%d)/logs.tar.gz"
```

## Centralized Log Collection

```bash
# Ship logs via syslog
logger -n logserver.example.com -P 514 -p user.info "Application started"

# Using netcat (if no logger)
tail -F /var/log/myapp/app.log | nc -u logserver.example.com 514
```

## Log Analysis on the Fly

```bash
# Recent errors
journalctl -u myapp --since "1 hour ago" -p err

# Top 10 errors in last 24h
journalctl -u myapp --since "24 hours ago" | grep ERROR | sort | uniq -c | sort -rn | head -10

# Request rate from access log
awk '{print $4}' access.log | cut -d: -f2 | sort | uniq -c | sort -rn | head -5

# Slow requests (>2s)
awk '{if ($NF > 2) print $0}' access.log

# Geo stats from IPs (requires external db)
awk '{print $1}' access.log | sort -u | while read -r ip; do
    whois "$ip" | grep -i country | head -1
done | sort | uniq -c | sort -rn
```
