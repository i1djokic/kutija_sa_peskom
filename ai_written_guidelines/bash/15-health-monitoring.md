# Health Checks & Monitoring

## Service Health Checks

```bash
# Basic
systemctl is-active --quiet nginx && echo "nginx is running" || echo "nginx is down"

# With auto-recovery
ensure_service() {
    local svc="$1"
    if ! systemctl is-active --quiet "$svc"; then
        echo "$svc is down — restarting"
        systemctl restart "$svc" || {
            echo "[CRIT] Failed to restart $svc" >&2
            return 1
        }
    fi
}

# Retry restart
ensure_service_retry() {
    local svc="$1" retries="${2:-3}"
    for i in $(seq 1 "$retries"); do
        if systemctl is-active --quiet "$svc"; then
            echo "$svc running (attempt $i)"
            return 0
        fi
        echo "Restarting $svc (attempt $i/$retries)"
        systemctl restart "$svc" 2>/dev/null || true
        sleep 2
    done
    echo "[CRIT] $svc restart failed after $retries attempts" >&2
    return 1
}

# Wait for service to become ready
wait_for_service() {
    local svc="$1" timeout="${2:-30}"
    for i in $(seq 1 "$timeout"); do
        if systemctl is-active --quiet "$svc"; then
            echo "$svc ready after ${i}s"
            return 0
        fi
        sleep 1
    done
    return 1
}
```

## HTTP Health Check

```bash
# Simple
curl -sf http://localhost:8080/health > /dev/null

# With status code
http_check() {
    local url="$1" expect="${2:-200}"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [[ "$code" -eq "$expect" ]]; then
        echo "OK ($code)"
        return 0
    else
        echo "FAIL ($code, expected $expect)" >&2
        return 1
    fi
}
```

## Disk Usage Monitoring

```bash
# Check disk usage percentage (integer)
disk_usage() {
    local mount="${1:-/}"
    df "$mount" | awk 'NR==2 {gsub(/%/,""); print $5}'
}

# Alert if above threshold
check_disk() {
    local mount="${1:-/}" threshold="${2:-85}"
    local pct
    pct=$(disk_usage "$mount")
    if (( pct > threshold )); then
        echo "WARNING: $mount at ${pct}% (threshold ${threshold}%)"
        return 1
    fi
}

# Inode usage (often fills up before disk)
check_inodes() {
    local mount="${1:-/}" threshold="${2:-90}"
    local pct
    pct=$(df -i "$mount" | awk 'NR==2 {gsub(/%/,""); print $5}')
    if (( pct > threshold )); then
        echo "WARNING: $mount inodes at ${pct}%"
        return 1
    fi
}
```

## Memory Monitoring

```bash
# Memory usage percentage
memory_usage() {
    free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}'
}

# Available memory in MB
memory_available() {
    free -m | awk '/^Mem:/ {print $7}'
}

# Check if OOM risk
check_memory() {
    local avail
    avail=$(memory_available)
    if (( avail < 500 )); then
        echo "WARNING: Only ${avail}MB available"
        return 1
    fi
}
```

## Load & Uptime

```bash
# Load average
load_avg() { uptime | awk -F'load average:' '{print $2}'; }

# CPU cores (for load average context)
cpu_cores() { nproc; }

# Check if load is too high
check_load() {
    local cores
    cores=$(cpu_cores)
    local one_min
    one_min=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
    local threshold=$(( cores * 2 ))
    if (( $(echo "$one_min > $threshold" | bc -l) )); then
        echo "WARNING: Load $one_min > ${threshold} (${cores} cores)"
        return 1
    fi
}
```

## Certificate Expiry Check

```bash
check_cert() {
    local domain="$1" port="${2:-443}"
    local expiry

    expiry=$(echo | openssl s_client -servername "$domain" -connect "${domain}:${port}" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2)

    if [[ -z "$expiry" ]]; then
        echo "FAIL: Could not get certificate for $domain"
        return 1
    fi

    local expiry_epoch
    expiry_epoch=$(date -d "$expiry" +%s)
    local now_epoch
    now_epoch=$(date +%s)
    local remaining_days=$(( (expiry_epoch - now_epoch) / 86400 ))

    echo "$domain: expires $expiry (${remaining_days} days)"
    if (( remaining_days < 14 )); then
        echo "WARNING: Certificate expires in ${remaining_days} days"
        return 1
    fi
}
```

## All-in-One Health Report

```bash
health_report() {
    echo "=== Health Report: $(hostname) ==="
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    echo "  Free: $(free -h | awk '/^Mem:/ {print $7}') available"
    echo "Disk:  $(df -h / | awk 'NR==2 {print $3"/"$2}')"
    echo "  Free: $(df -h / | awk 'NR==2 {print $4}')"
    echo "Load:  $(load_avg)"
    echo "--- Services ---"
    for svc in nginx postgresql redis; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "  $svc: running"
        else
            echo "  $svc: DOWN"
        fi
    done
}
```
