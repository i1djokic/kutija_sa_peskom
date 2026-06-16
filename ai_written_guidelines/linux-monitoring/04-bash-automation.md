# Bash Automation — Collectors, Cron Pipelines, Alerting

## Table of Contents
1. [Design Philosophy](#design-philosophy)
2. [Local Collector — CSV to Disk](#local-collector--csv-to-disk)
3. [SSH-Based Central Pull](#ssh-based-central-pull)
4. [Alerting with Bash](#alerting-with-bash)
5. [Cron Pipelines](#cron-pipelines)
6. [Self-Contained Monitoring Dashboard](#self-contained-monitoring-dashboard)
7. [Performance Considerations](#performance-considerations)

---

## Design Philosophy

Bash is ideal for scenarios where:
- You have 1-50 servers and no existing monitoring infrastructure
- You cannot (or won't) install any packages
- You need something working in 5 minutes
- You want to keep the entire monitoring codebase in a single directory

**Three patterns:**
1. **Local push** — each host runs a cron job, appends to a local CSV/file, then periodically ships via rsync/scp
2. **Central pull** — a central server SSHes into each host and grabs metrics
3. **HTTP push** — each host curls metrics to a central web endpoint

---

## Local Collector — CSV to Disk

### Complete Health Snapshot

```bash
#!/bin/bash
# /usr/local/bin/collect-health.sh
# Collects system health data every 5 minutes via cron
# Writes to /var/log/agentless/YYYY/MM/DD/HOST.csv

set -o errexit   # technically we don't want to exit on errors for all metrics
set -o pipefail

HOST=$(hostname -f 2>/dev/null || hostname)
EPOCH=$(date +%s)
DATE_DIR=$(date -d "@$EPOCH" +%Y/%m/%d)
CSV_DIR="/var/log/agentless/$DATE_DIR"
CSV_FILE="$CSV_DIR/$HOST.csv"

mkdir -p "$CSV_DIR"

# -- CPU load -----------------------------------------------------------------
LOAD_1=$(awk '{print $1}' /proc/loadavg)
LOAD_5=$(awk '{print $2}' /proc/loadavg)
LOAD_15=$(awk '{print $3}' /proc/loadavg)
PROCS_RUNNING=$(awk '{print $4}' /proc/loadavg | cut -d/ -f1)
PROCS_TOTAL=$(awk '{print $4}' /proc/loadavg | cut -d/ -f2)

# -- CPU utilization (1 second delta) ----------------------------------------
read -r CPU_USER CPU_NICE CPU_SYS CPU_IDLE CPU_IOWAIT CPU_IRQ CPU_SOFTIRQ CPU_STEAL <<< \
    $(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat)
sleep 1
read -r CPU_USER2 CPU_NICE2 CPU_SYS2 CPU_IDLE2 CPU_IOWAIT2 CPU_IRQ2 CPU_SOFTIRQ2 CPU_STEAL2 <<< \
    $(awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat)

TOTAL_DELTA=$(( (CPU_USER2 - CPU_USER) + (CPU_NICE2 - CPU_NICE) + (CPU_SYS2 - CPU_SYS) + \
                (CPU_IDLE2 - CPU_IDLE) + (CPU_IOWAIT2 - CPU_IOWAIT) + \
                (CPU_IRQ2 - CPU_IRQ) + (CPU_SOFTIRQ2 - CPU_SOFTIRQ) + \
                (CPU_STEAL2 - CPU_STEAL) ))

PCT_USER=$(( TOTAL_DELTA > 0 ? 100 * (CPU_USER2 - CPU_USER) / TOTAL_DELTA : 0 ))
PCT_SYS=$(( TOTAL_DELTA > 0 ? 100 * (CPU_SYS2 - CPU_SYS) / TOTAL_DELTA : 0 ))
PCT_IDLE=$(( TOTAL_DELTA > 0 ? 100 * (CPU_IDLE2 - CPU_IDLE) / TOTAL_DELTA : 0 ))
PCT_IOWAIT=$(( TOTAL_DELTA > 0 ? 100 * (CPU_IOWAIT2 - CPU_IOWAIT) / TOTAL_DELTA : 0 ))
PCT_STEAL=$(( TOTAL_DELTA > 0 ? 100 * (CPU_STEAL2 - CPU_STEAL) / TOTAL_DELTA : 0 ))

# -- Memory -------------------------------------------------------------------
eval $(awk '
    /MemTotal/     {mt=$2}
    /MemFree/      {mf=$2}
    /MemAvailable/ {ma=$2}
    /SwapTotal/    {st=$2}
    /SwapFree/     {sf=$2}
    /Cached/       {ca=$2}
    /Buffers/      {bu=$2}
    /SReclaimable/ {sr=$2}
    END { printf "MEM_TOTAL=%d MEM_FREE=%d MEM_AVAIL=%d SWAP_TOTAL=%d SWAP_FREE=%d CACHED=%d BUFFERS=%d SLAB_RECLAIM=%d", mt, mf, ma, st, sf, ca, bu, sr }
' /proc/meminfo)

MEM_PCT=$(( MEM_TOTAL > 0 ? (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL : 0 ))
SWAP_PCT=$(( SWAP_TOTAL > 0 ? (SWAP_TOTAL - SWAP_FREE) * 100 / SWAP_TOTAL : 0 ))

# -- Disk ---------------------------------------------------------------------
# Root partition
eval $(df / | awk 'NR==2 {printf "DISK_ROOT_PCT=%s DISK_ROOT_USED=%s DISK_ROOT_TOTAL=%s", $5, $3, $2}')
DISK_ROOT_PCT=${DISK_ROOT_PCT%\%}

# All mount points (skip pseudo-fs)
DISK_DATA=$(df -B1 --exclude-type=proc --exclude-type=sysfs --exclude-type=tmpfs \
    --exclude-type=devtmpfs --exclude-type=overlay \
    | awk 'NR>1 {printf "%s:%d:%d ", $6, $3, $2}')

# Inode usage
INODE_PCT=$(df -i / | awk 'NR==2 {print $5}' | tr -d '%')

# Per-disk I/O counters from /proc/diskstats
DISK_IO=$(awk '$3 ~ /^(sd|nvme|xvd|vd)[a-z]+$/ && $3 !~ /[0-9]$/ {
    printf "%s:rio=%s:wio=%s:rsect=%s:wsect=%s:io_ms=%s ", $3, $4, $8, $6, $10, $13
}' /proc/diskstats)

# -- Network ------------------------------------------------------------------
# Use /sys/class/net for per-interface stats (lighter weight)
NET_DATA=""
for iface in /sys/class/net/*; do
    name=$(basename "$iface")
    [ "$name" = "lo" ] && continue
    rx=$(cat "$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx=$(cat "$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
    rx_err=$(cat "$iface/statistics/rx_errors" 2>/dev/null || echo 0)
    tx_err=$(cat "$iface/statistics/tx_errors" 2>/dev/null || echo 0)
    rx_drop=$(cat "$iface/statistics/rx_dropped" 2>/dev/null || echo 0)
    tx_drop=$(cat "$iface/statistics/tx_dropped" 2>/dev/null || echo 0)
    speed=$(cat "$iface/speed" 2>/dev/null || echo 0)
    carrier=$(cat "$iface/carrier" 2>/dev/null || echo 0)
    NET_DATA+="${name}:rx=${rx}:tx=${tx}:rx_err=${rx_err}:tx_err=${tx_err}:rx_drop=${rx_drop}:tx_drop=${tx_drop}:speed=${speed}:carrier=${carrier} "
done

# -- Processes ----------------------------------------------------------------
PROC_TOTAL=$(ps -e --no-headers 2>/dev/null | wc -l)
PROC_RUNNING=$(ps -e --no-headers 2>/dev/null | awk '{ if (substr($0,28,1)=="R") count++ } END {print count+0}')
PROC_ZOMBIE=$(ps -e --no-headers 2>/dev/null | awk '{ if (substr($0,28,1)=="Z") count++ } END {print count+0}')
PROC_BLOCKED=$(awk '/procs_blocked/ {print $2}' /proc/stat)

# Open files (global)
OPEN_FILES=$(cat /proc/sys/fs/file-nr | awk '{print $1}')
FILE_MAX=$(cat /proc/sys/fs/file-nr | awk '{print $3}')

# -- Connections --------------------------------------------------------------
TCP_ESTAB=$(ss -t4 state established --no-header 2>/dev/null | wc -l)
TCP_TIME_WAIT=$(ss -t4 state time-wait --no-header 2>/dev/null | wc -l)
TCP_LISTEN=$(ss -t4ln --no-header 2>/dev/null | wc -l)
UDP_LISTEN=$(ss -u4ln --no-header 2>/dev/null | wc -l)

# -- Context switches & interrupts --------------------------------------------
CS=$(awk '/^ctxt / {print $2}' /proc/stat)
INTR=$(awk '/^intr / {print $2}' /proc/stat)

# -- Uptime -------------------------------------------------------------------
UPTIME=$(awk '{print int($1)}' /proc/uptime)
UPTIME_IDLE=$(awk '{print int($2)}' /proc/uptime)

# -- Temperature (if available) -----------------------------------------------
TEMP=""
for zone in /sys/class/thermal/thermal_zone*; do
    [ -e "$zone/temp" ] || continue
    ztype=$(cat "$zone/type" 2>/dev/null || echo "unknown")
    ztemp=$(cat "$zone/temp" 2>/dev/null || echo 0)
    TEMP+="${ztype}=${ztemp} "
done

# -- Write CSV ----------------------------------------------------------------
# CSV Header (written once if file is new)
if [ ! -f "$CSV_FILE" ]; then
    echo "epoch,host,load_1,load_5,load_15,procs_running,procs_total," \
         "cpu_user,cpu_sys,cpu_idle,cpu_iowait,cpu_steal," \
         "mem_total,mem_avail,mem_free,mem_pct," \
         "swap_total,swap_free,swap_pct," \
         "disk_root_pct,inode_pct," \
         "proc_total,proc_running,proc_zombie,proc_blocked," \
         "open_files,file_max," \
         "tcp_estab,tcp_time_wait,tcp_listen," \
         "context_switches,intr," \
         "uptime_secs" > "$CSV_FILE"
fi

echo "$EPOCH,$HOST,$LOAD_1,$LOAD_5,$LOAD_15,$PROCS_RUNNING,$PROCS_TOTAL," \
     "$PCT_USER,$PCT_SYS,$PCT_IDLE,$PCT_IOWAIT,$PCT_STEAL," \
     "$MEM_TOTAL,$MEM_AVAIL,$MEM_FREE,$MEM_PCT," \
     "$SWAP_TOTAL,$SWAP_FREE,$SWAP_PCT," \
     "$DISK_ROOT_PCT,$INODE_PCT," \
     "$PROC_TOTAL,$PROC_RUNNING,$PROC_ZOMBIE,$PROC_BLOCKED," \
     "$OPEN_FILES,$FILE_MAX," \
     "$TCP_ESTAB,$TCP_TIME_WAIT,$TCP_LISTEN," \
     "$CS,$INTR," \
     "$UPTIME" >> "$CSV_FILE"
```

**Cron entry:**
```bash
# /etc/cron.d/agentless-health
*/5 * * * * root /usr/local/bin/collect-health.sh
```

### Ship Logs to Central Server via rsync

```bash
#!/bin/bash
# /usr/local/bin/ship-logs.sh
# Run hourly via cron on each host
# Uses SSH key-based auth to central server

CENTRAL="backup@central.example.com"
REMOTE_PATH="/var/log/agentless/$(hostname)"
LOCAL_PATH="/var/log/agentless"

rsync -az --remove-source-files -e "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new" \
    "$LOCAL_PATH/" "$CENTRAL:$REMOTE_PATH/"
```

### Lightweight Alternative — Single File Append

When you want zero directory creation and simplest possible setup:

```bash
#!/bin/bash
# /usr/local/bin/push-metrics.sh
# Single-line output, pipe-friendly

HOST=$(hostname)
EPOCH=$(date +%s)
LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)
MEM=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.0f", (1-a/t)*100}' /proc/meminfo)
DISK=$(df / | awk 'NR==2{print $5}' | tr -d %)

echo "$EPOCH $HOST LOAD=$LOAD MEM=$MEM% DISK=$DISK%"
```

Cron writing to a central file via `>>`:
```bash
* * * * * root /usr/local/bin/push-metrics.sh >> /var/log/health.pipe
# This file can be tailed, rotated, or read by a daemon
```

---

## SSH-Based Central Pull

### Parallel Pull from 50 Hosts

```bash
#!/bin/bash
# /usr/local/bin/central-pull.sh — run on central server

# Configuration
HOSTS=(
    "web01.example.com"
    "web02.example.com"
    "db01.example.com"
    "cache01.example.com"
)
SSH_USER="monitor"
SSH_KEY="/home/monitor/.ssh/id_ed25519"
LOG_DIR="/var/log/pulled"
mkdir -p "$LOG_DIR"
DATE=$(date '+%Y-%m-%d-%H%M')
OUTFILE="$LOG_DIR/pull-$DATE.csv"

# Commands to run on each host (semicolon-separated, escaped for remote)
REMOTE_CMDS="
    echo -n \$(hostname),\$(date +%s),
    awk '{print \$1}' /proc/loadavg,
    awk '/MemAvailable/{a=\$2} /MemTotal/{t=\$2} END{printf \"%.1f\", (1-a/t)*100}' /proc/meminfo,
    df / | awk 'NR==2{printf \"%s\", \$5}' | tr -d %,
    ss -t4 state established --no-header | wc -l,
    uptime -p
"

pull_host() {
    local host="$1"
    local result
    result=$(ssh -i "$SSH_KEY" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        "$SSH_USER@$host" "$REMOTE_CMDS" 2>/dev/null || echo "FAILED,$host,$EPOCH,,,,,")
    echo "$result"
}

# Run pulls in parallel (up to 10 at a time)
echo "timestamp,host,load_1,mem_pct,disk_pct,tcp_estab,uptime" > "$OUTFILE"
for host in "${HOSTS[@]}"; do
    pull_host "$host" >> "$OUTFILE" &
    # Limit concurrency
    while [ "$(jobs -r | wc -l)" -ge 10 ]; do
        sleep 0.1
    done
done
wait

echo "Written $OUTFILE"
```

### Using a Host Inventory File

```bash
#!/bin/bash
# central-pull-file.sh — hosts from a text file
# hosts.txt format: group hostname user
#   web web01.example.com monitor
#   web web02.example.com monitor
#   db  db01.example.com  dba

INVENTORY="/etc/monitor/hosts.txt"
SSH_KEY="/home/monitor/.ssh/id_ed25519"
INTERVAL=${1:-60}  # seconds between pulls

while true; do
    DATE=$(date +%Y-%m-%d-%H%M)
    while IFS=' ' read -r group host user; do
        [[ "$group" =~ ^# ]] && continue
        [ -z "$host" ] && continue

        (
            data=$(ssh -i "$SSH_KEY" -o ConnectTimeout=5 "$user@$host" "
                echo -n \$(cat /proc/loadavg | cut -d' ' -f1),
                awk '/MemAvailable/{a=\$2} /MemTotal/{t=\$2} END{printf \"%.1f\", (1-a/t)*100}' /proc/meminfo,
                df / | awk 'NR==2{print \$5}' | tr -d %
            " 2>/dev/null || echo "FAIL,,")

            echo "$DATE,$group,$host,$data" >> "/var/log/pulled/by-group/$group.csv"
        ) &
    done < "$INVENTORY"
    wait
    sleep "$INTERVAL"
done
```

### SSH Command Caching (Avoid Repeating Work)

Multiple SSH commands per host = wasteful. Batch everything into one:

```bash
#!/bin/bash
# batch-remote.sh — single SSH, collect everything

SSH_CMD='cat /proc/loadavg /proc/meminfo /proc/uptime /proc/stat /proc/diskstats && df -h / && ss -t4 state established --no-header | wc -l'

data=$(ssh user@host "$SSH_CMD" 2>/dev/null)

# Parse locally
LOAD=$(echo "$data" | sed -n '1p' | awk '{print $1}')
MEM_TOTAL=$(echo "$data" | sed -n '2p' | awk '{print $2}')
MEM_AVAIL=$(echo "$data" | sed -n '5p' | awk '{print $2}')
MEM_PCT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))
UPTIME=$(echo "$data" | sed -n '7p' | awk '{print int($1)}')
TCP=$(echo "$data" | tail -1)

echo "$(date +%s),$host,$LOAD,$MEM_PCT,$TCP,$UPTIME"
```

---

## Alerting with Bash

### Threshold-Based Alert

```bash
#!/bin/bash
# /usr/local/bin/alert-check.sh
# Run via cron every minute

ALERT_EMAIL="ops@example.com"
ALERT_WEBHOOK="https://hooks.slack.com/services/T.../B.../xxx"

# --- Load ---
LOAD=$(awk '{print $1}' /proc/loadavg)
CPU_COUNT=$(nproc)
LOAD_THRESHOLD=$(echo "$CPU_COUNT * 0.9" | bc | cut -d. -f1)  # 90% of cores
if [ "$(echo "$LOAD > $LOAD_THRESHOLD" | bc)" -eq 1 ]; then
    echo "HIGH LOAD: $(hostname) — load=$LOAD (cores=$CPU_COUNT)" | \
        mail -s "ALERT: High load on $(hostname)" "$ALERT_EMAIL"
    curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\": \"HIGH LOAD on $(hostname): load=$LOAD\"}" \
        "$ALERT_WEBHOOK"
fi

# --- Memory ---
MEM_PCT=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.0f", (1-a/t)*100}' /proc/meminfo)
if [ "$MEM_PCT" -gt 90 ]; then
    echo "LOW MEMORY: $(hostname) — ${MEM_PCT}% used" | \
        mail -s "ALERT: Low memory on $(hostname)" "$ALERT_EMAIL"
fi

# --- Disk ---
DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
if [ "$DISK_PCT" -gt 85 ]; then
    echo "DISK FULL: $(hostname) — root ${DISK_PCT}% used" | \
        mail -s "ALERT: Disk on $(hostname)" "$ALERT_EMAIL"
fi

# --- Swap ---
SWAP_PCT=$(free | awk '/^Swap:/ {if ($2>0) printf "%.0f", $3/$2*100; else print "0"}')
if [ "$SWAP_PCT" -gt 50 ]; then
    echo "SWAP USAGE: $(hostname) — ${SWAP_PCT}% swapped" | \
        mail -s "ALERT: Swap usage on $(hostname)" "$ALERT_EMAIL"
fi

# --- OOM check ---
OOM=$(dmesg -T 2>/dev/null | grep -i "oom-killer" | tail -1)
if [ -n "$OOM" ]; then
    echo "OOM KILLER invoked on $(hostname): $OOM" | \
        mail -s "ALERT: OOM on $(hostname)" "$ALERT_EMAIL"
fi

# --- Service check ---
for svc in nginx postgresql sshd; do
    if ! systemctl is-active --quiet "$svc"; then
        echo "$svc is DOWN on $(hostname)" | \
            mail -s "ALERT: $svc down on $(hostname)" "$ALERT_EMAIL"
    fi
done
```

**Cron:**
```bash
* * * * * root /usr/local/bin/alert-check.sh
```

### Rate-Limited Alerting (Prevent Flood)

```bash
#!/bin/bash
# throttle-alert.sh — prevents alert storms

THROTTLE_FILE="/tmp/.alert-throttle"
THROTTLE_SECONDS=300  # 5 minutes between alerts
ALERT_NAME="${1:-generic}"
ALERT_MSG="$2"
ALERT_EMAIL="ops@example.com"
THROTTLE_DB="$THROTTLE_FILE.$ALERT_NAME"

# Check throttle
LAST_ALERT=0
[ -f "$THROTTLE_DB" ] && LAST_ALERT=$(cat "$THROTTLE_DB")
NOW=$(date +%s)

if [ $((NOW - LAST_ALERT)) -gt "$THROTTLE_SECONDS" ]; then
    echo "$ALERT_MSG" | mail -s "ALERT: $ALERT_NAME" "$ALERT_EMAIL"
    echo "$NOW" > "$THROTTLE_DB"
fi
```

### Anomaly Detection (Simple Baseline)

```bash
#!/bin/bash
# simple-anomaly.sh — compares current metrics to a rolling baseline

BASELINE_FILE="/var/lib/monitor/baseline-$(hostname).txt"
CURRENT_LOAD=$(awk '{print $1}' /proc/loadavg)

if [ ! -f "$BASELINE_FILE" ]; then
    echo "$CURRENT_LOAD" > "$BASELINE_FILE"
    exit 0
fi

# Read baseline average and stddev
BASELINE_AVG=$(awk '{s+=$1} END{print s/NR}' "$BASELINE_FILE")
BASELINE_STDDEV=$(awk -v avg="$BASELINE_AVG" '{sum+=($1-avg)^2} END{print sqrt(sum/NR)}' "$BASELINE_FILE")

# Alert if current > baseline + 3 * stddev
THRESHOLD=$(echo "$BASELINE_AVG + 3 * $BASELINE_STDDEV" | bc)
if [ "$(echo "$CURRENT_LOAD > $THRESHOLD" | bc)" -eq 1 ]; then
    echo "ANOMALY: load $CURRENT_LOAD vs baseline $BASELINE_AVG ± $BASELINE_STDDEV" | \
        mail -s "Anomaly on $(hostname)" ops@example.com
fi

# Append current to baseline (rolling window of 1000)
echo "$CURRENT_LOAD" >> "$BASELINE_FILE"
tail -n 1000 "$BASELINE_FILE" > "$BASELINE_FILE.tmp" && mv "$BASELINE_FILE.tmp" "$BASELINE_FILE"
```

---

## Cron Pipelines

### Standard Monitoring Pipeline

```
cron (every 5 min)
   │
   ├── collect-health.sh  ──────>  /var/log/agentless/YYYY/MM/DD/HOST.csv
   │
   ├── alert-check.sh     ──────>  Email / Slack on threshold breach
   │
   └── ship-logs.sh       ──────>  rsync to central.example.com
                                       │
                                       ▼
                                /var/log/agentless/<hostname>/
                                       │
                                       ▼
                               Parse/ingest into SQLite or TimescaleDB
```

### Robust Cron Job Wrapper

```bash
#!/bin/bash
# /usr/local/bin/cron-wrapper.sh
# Prevents overlapping runs, logs failures

LOCKFILE="/var/lock/$(basename $0).lock"
LOGFILE="/var/log/cronjobs/$(basename $0).log"
TIMEOUT=600  # 10 minutes

exec 200>"$LOCKFILE"
flock -n 200 || { echo "$(date): Previous job still running, skipped" >> "$LOGFILE"; exit 1; }

# Timeout protection
trap "echo '$(date): Timed out' >> '$LOGFILE'; exit 124" SIGALRM
( sleep "$TIMEOUT"; kill -ALRM $$ ) &
TIMER_PID=$!

# Actual work
/usr/local/bin/collect-health.sh 2>&1 >> "$LOGFILE"
EXIT_CODE=$?

kill "$TIMER_PID" 2>/dev/null
exit "$EXIT_CODE"
```

### Log Rotation for Collected Data

```bash
#!/bin/bash
# /etc/logrotate.d/agentless
/var/log/agentless/*/*/*/*.csv {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Self-Contained Monitoring Dashboard

### Terminal Dashboard (Bash + watch)

```bash
#!/bin/bash
# /usr/local/bin/dashboard.sh — simple terminal dashboard
# Run: watch -n 2 ./dashboard.sh

clear
echo "╔═════════════════════════════════════════════════════════╗"
echo "║  $(hostname) — $(date '+%Y-%m-%d %H:%M:%S')            ║"
echo "╚═════════════════════════════════════════════════════════╝"

echo ""
echo "── CPU ────────────────────────────────────────────────"
LOAD=$(awk '{printf "%.2f %.2f %.2f", $1, $2, $3}' /proc/loadavg)
CPUS=$(nproc)
echo " Load avg: $LOAD  |  Cores: $CPUS"
mpstat -P ALL 1 1 2>/dev/null | tail -n +4 | while read line; do
    echo " $line"
done | head -$((CPUS + 1))

echo ""
echo "── Memory ──────────────────────────────────────────────"
free -h | awk '
    /^Mem:/ {printf " Used: %s / %s (%.1f%%)\n", $3, $2, $3/$2*100}
    /^Swap:/ {printf " Swap: %s / %s (%.1f%%)\n", $3, $2, $3/$2*100}
'

echo ""
echo "── Disk ────────────────────────────────────────────────"
df -h / /var /tmp 2>/dev/null | awk 'NR>1 {printf " %-15s %s used (%s)\n", $6, $3, $5}'

echo ""
echo "── Network ─────────────────────────────────────────────"
for iface in /sys/class/net/*; do
    name=$(basename "$iface")
    [ "$name" = "lo" ] && continue
    rx=$(cat "$iface/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx=$(cat "$iface/statistics/tx_bytes" 2>/dev/null || echo 0)
    rx_h=$((rx / 1024 / 1024))
    tx_h=$((tx / 1024 / 1024))
    link=$(cat "$iface/carrier" 2>/dev/null || echo 0)
    [ "$link" = "1" ] && status="UP" || status="DOWN"
    echo " $name: $status | RX: ${rx_h}M | TX: ${tx_h}M"
done

echo ""
echo "── Connections ───────────────────────────────────────────"
echo " TCP: $(ss -t4 state established --no-header 2>/dev/null | wc -l) established"
echo "       $(ss -t4 state time-wait --no-header 2>/dev/null | wc -l) time-wait"
echo "       $(ss -t4n state listen --no-header 2>/dev/null | wc -l) listening"
echo " UDP: $(ss -u4n --no-header | wc -l) sockets"

echo ""
echo "── Services ────────────────────────────────────────────"
for svc in nginx postgresql sshd cron; do
    status=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
    printf " %-20s %s\n" "$svc" "$status"
done
```

### HTML Dashboard (Bash-Generated)

```bash
#!/bin/bash
# /usr/local/bin/gen-dashboard.sh — generates a static HTML page
# Run via cron, serve with any HTTP server

OUTPUT="/var/www/html/health.html"
HOSTNAME=$(hostname)

load=$(awk '{printf "%.2f", $1}' /proc/loadavg)
mem=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.1f", (1-a/t)*100}' /proc/meminfo)
disk=$(df / | awk 'NR==2{print $5}' | tr -d '%')
uptime_sec=$(awk '{print int($1)}' /proc/uptime)
uptime_d=$((uptime_sec / 86400))
uptime_h=$(( (uptime_sec % 86400) / 3600 ))

cat > "$OUTPUT" <<HTML
<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta http-equiv="refresh" content="60">
<title>Health - $HOSTNAME</title>
<style>
body { font-family: monospace; background: #1e1e2e; color: #cdd6f4; padding: 2em; }
h1 { color: #89b4fa; }
.metric { background: #313244; padding: 1em; margin: 0.5em 0; border-radius: 8px; }
.bar { height: 20px; background: #45475a; border-radius: 10px; overflow: hidden; }
.bar-fill { height: 100%; background: #a6e3a1; transition: width 1s; }
.warning .bar-fill { background: #f9e2af; }
.critical .bar-fill { background: #f38ba8; }
</style>
</head><body>
<h1>📊 $HOSTNAME — System Health</h1>
<p>Updated: $(date '+%Y-%m-%d %H:%M:%S') | Uptime: ${uptime_d}d ${uptime_h}h</p>

<div class="metric">
  <strong>CPU Load:</strong> ${load} / $(nproc) cores
  <div class="bar"><div class="bar-fill" style="width: $(echo "$load * 100 / $(nproc)" | bc | cut -d. -f1)%"></div></div>
</div>

<div class="metric">
  <strong>Memory:</strong> ${mem}%
  <div class="bar $( [ "$(echo "$mem > 90" | bc)" -eq 1 ] && echo 'critical' || [ "$(echo "$mem > 75" | bc)" -eq 1 ] && echo 'warning' )">
    <div class="bar-fill" style="width: ${mem}%"></div>
  </div>
</div>

<div class="metric">
  <strong>Disk (root):</strong> ${disk}%
  <div class="bar $( [ "$disk" -gt 90 ] && echo 'critical' || [ "$disk" -gt 75 ] && echo 'warning' )">
    <div class="bar-fill" style="width: ${disk}%"></div>
  </div>
</div>
</body></html>
HTML
```

---

## Performance Considerations

### Reading /proc Many Times

Each `cat` is a syscall. In a single Bash script with multiple `cat /proc/xxx` calls:

| Optimization | Before | After |
|-------------|--------|-------|
| Read /proc/once per section | 20 reads | 2-3 reads |
| Use `/sys/class/net/` files directly | parsing /proc/net/dev | 1 file per stat |
| Batch `awk` passes | 5 `awk` invocations | 1 `awk` invocation |

### SSH Overhead

```
Per SSH connection overhead:
- TCP handshake:    ~1-2ms (local net) to 50ms (internet)
- Auth:             ~10-50ms (key-based)
- Command exec:     ~5-10ms
- Total per host:   ~20-100ms

For 50 hosts sequentially:  1-5 seconds
For 50 hosts parallel (10): 0.1-0.5 seconds
```

**Always use parallel SSH for > 10 hosts.**

### Cron + Bash Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|-------------|--------------|-----|
| Running `collect-health.sh` every 10s via cron | Cron granularity is 1 minute; use `watch` or a `sleep` loop | Use a systemd timer with 10s accuracy |
| Blocking on SSH timeouts | One slow host delays the entire batch | Set `ConnectTimeout=3`, use parallel |
| Reading `/proc/<pid>/smaps` for all PIDs | High overhead for large process counts | Use cgroup memory instead |
| `grep` + `awk` in a pipeline for each metric | Multiple process forks per metric | Single `awk` pass over the file |

### Systemd Timer (Replacement for Cron)

```bash
# /etc/systemd/system/collect-health.timer
[Unit]
Description=Collect system health every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true
RandomizedDelaySec=10

[Install]
WantedBy=timers.target

# /etc/systemd/system/collect-health.service
[Unit]
Description=System health collection

[Service]
Type=oneshot
ExecStart=/usr/local/bin/collect-health.sh
Nice=19
IOSchedulingClass=idle
```
