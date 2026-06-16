# Systemd & Journald — Deep Reference

## Table of Contents
1. [Why systemd Matters for Monitoring](#why-systemd-matters-for-monitoring)
2. [systemctl — Service Status & Control](#systemctl--service-status--control)
3. [systemd-cgtop — Cgroup-Aware Top](#systemd-cgtop--cgroup-aware-top)
4. [systemd-analyze — Boot Performance](#systemd-analyze--boot-performance)
5. [systemd Resource Accounting](#systemd-resource-accounting)
6. [journald Architecture & Configuration](#journald-architecture--configuration)
7. [journalctl — Query, Filter, Export](#journalctl--query-filter-export)
8. [Centralized Logging with systemd](#centralized-logging-with-systemd)
9. [cgroups v2 Deep Dive](#cgroups-v2-deep-dive)

---

## Why systemd Matters for Monitoring

systemd is the init system and service manager on virtually all modern Linux distributions. Beyond starting services, it provides:

- **Unified logging** via journald (binary, structured, indexed)
- **Resource tracking** per service via cgroups v2
- **Boot analysis** (what took time during startup)
- **Timer-based scheduling** (replacement for cron)
- **Socket activation** (track connection timing)

You can monitor system health using systemd's own tools — no external agents needed.

---

## systemctl — Service Status & Control

### Checking Service State

```bash
# Status of a specific service
systemctl status nginx.service

# Output breakdown:
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
     Active: active (running) since Thu 2025-06-03 10:23:45 UTC; 2 days ago
       Docs: man:nginx(8)
   Main PID: 1234 (nginx)
      Tasks: 3 (limit: 2314)
     Memory: 28.5M
        CPU: 12min 34.567s
     CGroup: /system.slice/nginx.service
             ├─1234 nginx: master process /usr/sbin/nginx
             └─1235 nginx: worker process

Jun 03 10:23:45 hostname systemd[1]: Starting nginx.service...
Jun 03 10:23:45 hostname systemd[1]: Started nginx.service.
```

**Key fields for monitoring:**
- **Active** — `active (running)`, `active (exited)`, `inactive (dead)`, `failed`
- **Tasks** — number of processes/threads in the cgroup
- **Memory** — current RSS (from cgroup)
- **CPU** — total CPU time consumed
- **CGroup** — cgroup path, with process tree

### Bulk Service Monitoring

```bash
# All services, unit state summary
systemctl list-units --type=service

# Only failed services
systemctl --failed

# Services sorted by memory (cgroup-aware)
systemctl list-units --type=service --output=json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for u in sorted(data, key=lambda x: x.get('memory', 0), reverse=True)[:10]:
    print(f\"{u['unit']:40s} {u['memory']:>10s}\")
"

# Show only active and running services
systemctl list-units --type=service --state=running

# Services with specific status
systemctl is-active nginx.service          # active / inactive / failed
systemctl is-enabled nginx.service         # enabled / disabled / static
systemctl is-failed nginx.service          # failed / active
```

### Property Queries (Scripting-Friendly)

```bash
# Show all properties of a unit
systemctl show nginx.service

# Specific property
systemctl show -p MainPID nginx.service
systemctl show -p ActiveState nginx.service
systemctl show -p MemoryCurrent nginx.service
systemctl show -p TasksCurrent nginx.service
systemctl show -p CPUShares nginx.service

# Multiple properties
systemctl show -p MainPID,ActiveState,MemoryCurrent nginx.service

# Parse-friendly output
systemctl show -p ActiveState nginx.service | cut -d= -f2
```

### Fail Detection

```bash
#!/bin/bash
# check-failed.sh — alert on any failed unit
FAILED=$(systemctl --failed --no-legend --no-pager | wc -l)
if [ "$FAILED" -gt 0 ]; then
    systemctl --failed --no-pager
    # Send alert...
fi
```

### Restart Counting

systemd tracks restart counts internally. Service flapping detection:

```bash
#!/bin/bash
# flapping-check.sh — check services that auto-restarted
for svc in $(systemctl list-units --type=service --state=running --no-legend | awk '{print $1}'); do
    nrestarts=$(systemctl show -p NRestarts "$svc" 2>/dev/null | cut -d= -f2)
    if [ "${nrestarts:-0}" -gt 5 ]; then
        echo "FLAPPING: $svc restarted $nrestarts times"
    fi
done
```

---

## systemd-cgtop — Cgroup-Aware Top

Unlike traditional `top` (which shows processes), `systemd-cgtop` shows **control groups**, aggregating resources per service.

```bash
systemd-cgtop                         # Interactive, default view
systemd-cgtop -d 2                    # Update every 2 seconds
systemd-cgtop -n 5                    # 5 iterations (batch)
systemd-cgtop --order=cpu             # Sort by CPU
systemd-cgtop --order=memory          # Sort by memory
systemd-cgtop -p                      # Show full paths
systemd-cgtop --depth=2               # Subtree depth
```

**Output:**
```
Control Group                            Tasks   %CPU   Memory  Input/s Output/s
/system.slice/nginx.service                 3    0.5     28.5M       0B       0B
/system.slice/postgresql.service           12    2.3    245.0M       0B  12.5K/s
/system.slice/systemd-journald.service      1    0.1     12.0M       0B       0B
/system.slice/sshd.service                  2    0.0      4.2M       0B       0B
```

**Why it's better than `top` for service monitoring:**
- Shows ALL processes of a service aggregated
- Handles forking services correctly (nginx: master + workers as one)
- Accounts for cgroup limits (memory max, CPU quota)
- Works in containers where `/proc` is namespaced

---

## systemd-analyze — Boot Performance

### Basic Analysis

```bash
# Total boot time
systemd-analyze

# Per-unit boot times
systemd-analyze blame

# Critical chain (time-critical path)
systemd-analyze critical-chain

# SVG visualization (for sharing with team)
systemd-analyze plot > boot.svg
```

### `systemd-analyze blame` Output Explanation

```
 5.234s networkd-wait-online.service
 3.456s postgresql.service
 2.100s nginx.service
 1.234s systemd-fsck@root.service
 0.567s systemd-udevd.service
 0.123s sshd.service
```

These are **wall-clock times** from activation to reaching the "started" state. Not CPU time. Postgres taking 3.4s likely means it's waiting for disk or WAL recovery.

### Advanced Boot Analysis

```bash
# Down to individual unit conditions
systemd-analyze condition 'ConditionPathExists=/etc/nginx/nginx.conf'

# Timestamps of boot phases
systemd-analyze timestamp

# Show security-sensitive settings
systemd-analyze security nginx.service

# Dependency graph generation
systemd-analyze dot nginx.service | dot -Tsvg > deps.svg
```

**Using boot analysis for regression detection:**
```bash
#!/bin/bash
# track-boot-time.sh
LOG=/var/log/boot-times.log
BOOT_MS=$(systemd-analyze | grep -oP '=\K[0-9.]+(?=s)' | tail -1)
echo "$(date '+%Y-%m-%d %H:%M:%S') boot=${BOOT_MS}s" >> "$LOG"
# Alert if boot time > 2x baseline
BASELINE=30
if (( $(echo "$BOOT_MS > $BASELINE" | bc -l) )); then
    echo "BOOT TIME WARNING: ${BOOT_MS}s (baseline: ${BASELINE}s)"
fi
```

---

## systemd Resource Accounting

### Enabling Per-Service Accounting

Resource accounting is **not enabled by default** (to save CPU). Enable it:

```bash
# Globally (in /etc/systemd/system.conf)
DefaultCPUAccounting=yes
DefaultIOAccounting=yes
DefaultMemoryAccounting=yes
DefaultTasksAccounting=yes

# Or per-unit (in /etc/systemd/system/nginx.service.d/accounting.conf)
[Service]
CPUAccounting=yes
MemoryAccounting=yes
IOAccounting=yes
TasksAccounting=yes
```

Then reload and restart:
```bash
systemctl daemon-reload
systemctl restart nginx.service
```

### Reading Per-Service Resource Usage

```bash
# Memory (in bytes)
systemctl show -p MemoryCurrent nginx.service
systemctl show -p MemoryMax nginx.service      # limit if set
systemctl show -p MemoryHigh nginx.service
systemctl show -p MemoryLow nginx.service

# CPU
systemctl show -p CPUUsageNSec nginx.service   # nanoseconds!
# Convert to seconds: divide by 1,000,000,000

# I/O
systemctl show -p IOReadBytes nginx.service
systemctl show -p IOWriteBytes nginx.service
systemctl show -p IOReadOperations nginx.service
systemctl show -p IOWriteOperations nginx.service

# Tasks
systemctl show -p TasksCurrent nginx.service
systemctl show -p TasksMax nginx.service
```

### Raw cgroup Files (Direct Access)

systemd stores resource data in `/sys/fs/cgroup/`:

```bash
# Per-service memory
cat /sys/fs/cgroup/system.slice/nginx.service/memory.current
cat /sys/fs/cgroup/system.slice/nginx.service/memory.max       # limit
cat /sys/fs/cgroup/system.slice/nginx.service/memory.stat

# Per-service CPU
cat /sys/fs/cgroup/system.slice/nginx.service/cpu.stat
# usage_usec 12345678900         (microseconds)
# user_usec 10000000000
# system_usec 2345678900
# nr_periods 0
# nr_throttled 0
# throttled_usec 0

# Per-service I/O
cat /sys/fs/cgroup/system.slice/nginx.service/io.stat
# 8:0 rbytes=123456789 wbytes=987654321 rios=1234 wios=5678
# 8:1 ...

# Per-service PID count
cat /sys/fs/cgroup/system.slice/nginx.service/pids.current
cat /sys/fs/cgroup/system.slice/nginx.service/pids.max
```

### Setting Resource Limits for Stability

```bash
# /etc/systemd/system/nginx.service.d/limits.conf
[Service]
MemoryMax=512M                   # Hard limit (OOM kill if exceeded)
MemoryHigh=400M                  # Soft limit (throttle above this)
CPUQuota=75%                     # Max 75% of one CPU core
TasksMax=50                      # Max 50 threads
IOReadBandwidthMax=/dev/sda 100M # 100 MB/s read
IOWriteBandwidthMax=/dev/sda 50M # 50 MB/s write
```

---

## journald Architecture & Configuration

### Journal Storage

journald stores logs in a binary, structured journal. Three storage modes:

| Mode | Storage location | Persistence |
|------|-----------------|-------------|
| `volatile` | `/run/log/journal/` | Lost on reboot |
| `persistent` | `/var/log/journal/` | Survives reboots |
| `auto` | `persistent` if `/var/log/journal/` exists, else `volatile` |

**Create persistent journal storage:**
```bash
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald
```

### Configuration

**`/etc/systemd/journald.conf`:**
```ini
[Journal]
# Where to store
Storage=persistent

# Max size limits
SystemMaxUse=1G
SystemKeepFree=500M
RuntimeMaxUse=200M
RuntimeKeepFree=100M

# Log rotation
MaxFileSec=1month

# Forwarding options
ForwardToSyslog=yes
ForwardToWall=yes     # Broadcast to all logged-in users
ForwardToKMsg=no
ForwardToConsole=no

# Compression
Compress=yes
Seal=yes              # Cryptographic sealing (for audit)

# Rate limiting (prevents log floods)
RateLimitIntervalSec=30s
RateLimitBurst=10000
```

### Journal Structure

Each journal entry contains **structured fields**:

```
__REALTIME_TIMESTAMP=1749000000123456
__MONOTONIC_TIMESTAMP=1234567890123
_BOOT_ID=abcdef1234567890abcdef1234567890
_MACHINE_ID=1234567890abcdef1234567890abcdef
_HOSTNAME=web01.example.com
_TRANSPORT=syslog
PRIORITY=6                                     # 0=emerg, 1=alert, 2=crit, 3=err, 4=warning, 5=notice, 6=info, 7=debug
SYSLOG_FACILITY=1
SYSLOG_IDENTIFIER=nginx
_PID=1234
_UID=0
_GID=0
_COMM=nginx
_EXE=/usr/sbin/nginx
_CMDLINE=nginx: master process /usr/sbin/nginx
MESSAGE=10.0.0.1 - - [03/Jun/2025:10:23:45 +0000] "GET / HTTP/1.1" 200 1234
```

---

## journalctl — Query, Filter, Export

### Basic Filtering

```bash
# By unit (most common)
journalctl -u nginx.service
journalctl -u sshd.service --since "2 hours ago"

# By time
journalctl --since "2025-01-01 00:00:00" --until "2025-01-02 00:00:00"
journalctl --since "yesterday"
journalctl --since "-1h"

# By priority
journalctl -p err          # Errors + critical + alert + emergency
journalctl -p err -b       # Errors since boot
journalctl -p emerg        # Only emergencies (kernel panic level)

# By boot session
journalctl -b 0            # Current boot
journalctl -b -1           # Previous boot
journalctl --list-boots    # List all available boots
```

### Field-Based Filters

```bash
# By PID
journalctl _PID=1234

# By binary
journalctl _EXE=/usr/sbin/nginx

# By command line
journalctl _CMDLINE="*worker*"

# By transport
journalctl _TRANSPORT=kernel     # Only kernel messages
journalctl _TRANSPORT=stdout     # Only stdout from services
journalctl _TRANSPORT=syslog     # Only syslog-compatible messages

# Several fields
journalctl _PID=1234 _TRANSPORT=stdout
```

### Output Formatting

```bash
# Default (short)
journalctl -u nginx.service -n 10

# Verbose (shows all fields, unordered)
journalctl -u nginx.service -o verbose

# JSON (for programmatic consumption)
journalctl -u nginx.service -o json
journalctl -u nginx.service -o json-pretty
journalctl -u nginx.service -o json-seq   # JSON lines (one per entry)

# Only message text
journalctl -u nginx.service -o cat

# Export format (re-importable)
journalctl -u nginx.service -o export > nginx-export.jexp
# Re-import:
# journalctl --file nginx-export.jexp
```

### Advanced Queries

```bash
# Correlation — messages from the same boot + same unit
journalctl -b -u nginx.service

# All messages between two cursor positions
journalctl --after-cursor "s=1234;..." -n 50

# Follow mode (like tail -f)
journalctl -u nginx.service -f

# Emergency mode — show panic-level messages first
journalctl -p emerg --no-pager

# Show only message body, no meta
journalctl -u nginx.service --no-hostname --catalog

# Disk usage summary
journalctl --disk-usage
# Archived and active journals take up 156.8M in file system.
```

### Disk Management

```bash
# Show current usage
journalctl --disk-usage

# Show detailed per-journal usage
ls -lh /var/log/journal/*/

# Cleanup
journalctl --vacuum-size=500M      # Keep total under 500M
journalctl --vacuum-time=30d       # Remove logs older than 30 days
journalctl --vacuum-files=10       # Keep only last 10 journals

# Rotate active journal (safe to do before vacuum)
journalctl --rotate

# Stop flushing to disk temporarily
systemctl stop systemd-journald
mv /var/log/journal /var/log/journal.hold
systemctl start systemd-journald
# Now logs go to /run/log/journal (volatile)
```

---

## Centralized Logging with systemd

### Option 1: Forward to Remote syslog

```bash
# /etc/systemd/journald.conf
ForwardToSyslog=yes
```

Then configure rsyslog or syslog-ng on the same machine to forward:

```bash
# /etc/rsyslog.d/remote.conf
*.* action(type="omfwd"
          target="logserver.example.com"
          port="514"
          protocol="tcp"
          action.resumeRetryCount="100"
          queue.type="linkedList"
          queue.size="10000")
```

### Option 2: Direct Journal Remote Sync (systemd v246+)

**On the client (forwarder):**
```bash
# /etc/systemd/journald.conf
[Journal]
ForwardToSyslog=no

# On the server (receiver)
# /etc/systemd/journald.conf
[Journal]
Remote=yes               # Accept remote connections
```

Or use `systemd-journal-remote`:

```bash
# On the server (receiver):
systemctl enable --now systemd-journal-remote.socket

# On the client (forwarder):
# Create a service that periodically syncs:
# /etc/systemd/system/journal-sync.service
[Service]
Type=oneshot
ExecStart=/usr/bin/journalctl --flush --rotate
ExecStartPost=/usr/bin/rsync -avz /var/log/journal/ server:/var/log/journal/
```

### Option 3: Pull-Based with journalctl over SSH

```bash
#!/bin/bash
# remote-journal-pull.sh — scripted pull, no agent on target
HOSTS=("web01" "web02" "db01")

for host in "${HOSTS[@]}"; do
    echo "=== $host ==="
    ssh "$host" "journalctl -u sshd.service -p err --since '1 hour ago' --no-pager"
done
```

### Option 4: Logstash / Filebeat Integration

Even without an agent, you can configure:

```bash
# On monitored host — use syslog forwarding to a logstash receiver
# /etc/rsyslog.d/logstash.conf
*.* @logstash.example.com:514
```

---

## cgroups v2 Deep Dive

### Hierarchy

```
/sys/fs/cgroup/
├── cpu.stat              # System-wide CPU statistics
├── memory.current        # System-wide memory
├── memory.stat           # Detailed memory breakdown
├── io.stat               # System-wide I/O
├── pids.current          # Total process count
├── cgroup.controllers    # Available controllers
├── cgroup.subtree_control
├── system.slice/         # System services
│   ├── nginx.service/
│   │   ├── cpu.stat
│   │   ├── memory.current
│   │   ├── io.stat
│   │   └── pids.current
│   ├── postgresql.service/
│   └── sshd.service/
├── user.slice/           # User sessions
│   ├── user-1000.slice/
│   │   ├── session-1.scope/
│   │   └── ...
└── machine.slice/        # VMs / containers
```

### Per-Service Memory Breakdown from cgroups

```bash
#!/bin/bash
# cgroup-mem-top.sh — top consumers from cgroups (more accurate than /proc)
printf "%-40s %s\n" "SERVICE" "MEMORY"
printf "%-40s %s\n" "-------" "------"
for svc in /sys/fs/cgroup/system.slice/*.service; do
    name=$(basename "$svc")
    mem=$(cat "$svc/memory.current" 2>/dev/null || echo 0)
    mem_mb=$(( mem / 1024 / 1024 ))
    if [ "$mem_mb" -gt 0 ]; then
        printf "%-40s %d MB\n" "$name" "$mem_mb"
    fi
done | sort -k2 -rn | head -20
```

### Memory Pressure Monitoring (PSI — Pressure Stall Information)

Linux 4.20+ exposes pressure metrics per cgroup:

```bash
cat /sys/fs/cgroup/system.slice/nginx.service/memory.pressure
# some avg10=0.00 avg60=0.00 avg300=0.00 total=123456
cat /sys/fs/cgroup/system.slice/nginx.service/cpu.pressure
# some avg10=0.50 avg60=0.30 avg300=0.10 total=7890123
cat /sys/fs/cgroup/system.slice/nginx.service/io.pressure
# some avg10=0.00 avg60=0.00 avg300=0.00 total=0
```

**PSI values:**
- `some` — at least one task is stalled on the resource
- `full` — all tasks are stalled (worse, near-oom or CPU-starved)
- `avg10` / `avg60` / `avg300` — average % of wall-time stalled in last 10s/60s/300s
- `total` — cumulative microseconds stalled

**Alerting on PSI:**
```bash
#!/bin/bash
# psi-alert.sh — alert on memory pressure
PRESSURE=$(cat /sys/fs/cgroup/memory.pressure)
AVG10=$(echo "$PRESSURE" | awk '/^some/ {print $2}' | cut -d= -f2)
if (( $(echo "$AVG10 > 10.0" | bc -l) )); then
    echo "CRITICAL: Memory pressure ${AVG10}% in last 10 seconds"
fi
```

### CPU Quota & Throttling

```bash
# Check if a service is being CPU-throttled
systemctl show -p CPUQuotaPerSecUSec nginx.service
# Check actual throttling
cat /sys/fs/cgroup/system.slice/nginx.service/cpu.stat
# nr_periods — number of enforcement periods
# nr_throttled — periods where service exceeded quota
# throttled_usec — total time throttled

# Throttle % = nr_throttled / nr_periods * 100
```

### OOM Detection via cgroups

```bash
# Check if any service was OOM-killed
dmesg -T | grep -i oom
journalctl -p err | grep -i oom

# Per-cgroup OOM events
for svc in /sys/fs/cgroup/system.slice/*.service; do
    killed=$(cat "$svc/memory.events" 2>/dev/null | grep oom_kill | cut -d' ' -f2)
    [ "${killed:-0}" -gt 0 ] && echo "OOM: $(basename $svc) killed ${killed} times"
done
```

### systemd OOMD (systemd 248+)

systemd has its own userspace OOM killer that can act before kernel OOM:

```bash
systemctl status systemd-oomd

# Configuration
# /etc/systemd/oomd.conf
[OOM]
DefaultMemoryPressureDurationSec=30s
DefaultSwapUsageLimitPercent=90

# Per-service policy:
# /etc/systemd/system/nginx.service.d/oomd.conf
[Service]
ManagedOOMSwap=kill       # Kill this cgroup if it causes swap pressure
ManagedOOMMemoryPressure=kill
```

---

## Summary: Monitoring with systemd Alone

```
┌────────────────────────────────────────────────────────────┐
│  What do you need?                                         │
│                                                            │
│  Is a service running?      → systemctl is-active svc     │
│  Why did it fail?           → journalctl -u svc -p err   │
│  How much RAM per service?  → systemctl show -p Memory...│
│  What's using most CPU?     → systemd-cgtop              │
│  Why was boot slow?         → systemd-analyze blame      │
│  Was anyone OOM-killed?     → memory.events per cgroup   │
│  Memory pressure?           → memory.pressure (PSI)      │
│  Centralized logs?          → rsyslog forwarding         │
└────────────────────────────────────────────────────────────┘
```
