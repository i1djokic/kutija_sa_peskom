# Built-in CLI Tools — Deep Reference

## Table of Contents
1. [CPU & Process Tools](#cpu--process-tools)
2. [Memory Tools](#memory-tools)
3. [Disk & I/O Tools](#disk--io-tools)
4. [Network Tools](#network-tools)
5. [System Logs & Events](#system-logs--events)
6. [sysstat (sar) — The Historical Swiss Army Knife](#sysstat-sar)
7. [Tool Comparison Matrix](#tool-comparison-matrix)

---

## CPU & Process Tools

### `top` — Real-Time Process View

**Source:** procps-ng

**Why it's essential:** `top` is usually the first thing an admin runs when a system feels slow. It reads `/proc/stat`, `/proc/loadavg`, `/proc/meminfo`, and `/proc/<pid>/stat` — every line comes from kernel interfaces.

**Key interactive commands during `top`:**
| Key | Action |
|-----|--------|
| `1` | Toggle per-CPU view |
| `P` | Sort by CPU usage (desc) |
| `M` | Sort by memory usage (desc) |
| `T` | Sort by running time |
| `c` | Toggle full command line |
| `H` | Toggle threads view |
| `u` | Filter by user |
| `k` | Kill a process (sends signal) |
| `r` | Renice a process |
| `W` | Write configuration to `~/.toprc` |
| `?` | Help |

**Batch mode (for scripting):**
```bash
# Single snapshot
top -bn1

# 3 snapshots, 2s apart (useful for deltas)
top -bn3 -d2

# Specify output fields
top -bn1 -o %MEM -e k | head -20

# Monitor specific PIDs
top -bn1 -p 1234,5678

# Thread-safe mode (-w for wide output)
top -bn1 -w 200
```

**Reading `top` output:**
```
top - 14:23:45 up 30 days,  1:23,  2 users,  load average: 0.45, 0.30, 0.20
Tasks: 123 total,   1 running, 122 sleeping,   0 stopped,   0 zombie
%Cpu(s):  8.5 us,  2.1 sy,  0.0 ni, 88.9 id,  0.3 wa,  0.0 hi,  0.2 si,  0.0 st
MiB Mem :  16000.0 total,   4000.0 free,   6000.0 used,   6000.0 buff/cache
MiB Swap:   2000.0 total,   1800.0 free,    200.0 used.   7000.0 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1234 postgres  20   0  1.2g 245000  24000 S   2.3   1.5   15:32.12 postgres
 5678 nginx     20   0   56000  12000   8000 S   0.0   0.1   12:34.56 nginx
```

| Field | Meaning | Calculation |
|-------|---------|-------------|
| VIRT | Virtual memory allocated | Total address space (private + shared + mapped) |
| RES | Resident memory (RSS) | Physical pages in RAM |
| SHR | Shared memory pages | Part of RES that's shared with other procs |
| S | Process state | D=running, R=runnable, S=sleeping, T=stopped, Z=zombie |
| %CPU | CPU% since last refresh | (CPU ticks delta / total ticks delta) × 100 |
| %MEM | RES / total physical RAM | RES / MemTotal × 100 |
| TIME+ | Total CPU time consumed | Cumulative since process start |

### `ps` — Process Snapshot

**Source:** procps-ng

**Standard selection syntaxes:**
- **BSD style** (no leading `-`): `ps aux`
- **UNIX style** (`-` prefix): `ps -ef`
- **GNU style** (`--` prefix): `ps --forest`

**Most useful invocations:**

```bash
# Show all fields — for scripting
ps -eo pid,ppid,uid,user,%cpu,%mem,vsz,rss,stat,start,time,args

# Tree view (parent-child)
ps auxf
ps -ejH
ps axjf

# Threads of a process
ps -L -p <pid>
ps -eTo pid,tid,ppid,pcpu,args

# Zombie processes
ps aux | awk '$8=="Z"'
ps -eo pid,stat,args | awk '/^ *[0-9]+ Z/'

# Top memory consumers
ps aux --sort=-%mem | head -10

# Top CPU consumers
ps aux --sort=-%cpu | head -10

# Specific user's processes
ps -u www-data
ps -U root -u root -N       # processes NOT running as root

# Session leader (daemon checking)
ps -eo pid,sess,args | awk '$1==$2'   # session leaders = daemons

# Age filter (processes running more than 1 day)
ps -eo pid,etime,args | awk '{split($2,a,"-"); if(a[1]+0>=1) print}'

# Process tree with resource info
ps -eo pid,ppid,c,stime,tty,time,cmd --sort=-start_time
```

**Exit codes:** `ps` returns 0 on success, 1 for errors. With `-C`:
```bash
ps -C nginx > /dev/null && echo "nginx running" || echo "nginx not running"
```

### `pidstat` — Per-Process Statistics Over Time

**Source:** sysstat (may need `apt install sysstat`)

Unlike `ps` (snapshot) or `top` (interactive), `pidstat` prints deltas, making it ideal for scripting CPU/memory/I/O spikes.

```bash
# CPU per process, 10 times, 1s interval
pidstat 1 10

# Only reporting processes with activity
pidstat -p ALL 1 | grep -v "0.00"

# Memory (RSS, VMSize, %MEM)
pidstat -r 1 5

# I/O (reads, writes, kB, iodelay)
pidstat -d 1 5

# Full thread-level monitoring
pidstat -t 1 5

# Specific process
pidstat -p 1234 -r -d 1 5

# Human-readable output
pidstat -ruh 1 5
```

**Memory-specific fields (`pidstat -r`):**
```
  PID  minflt/s  majflt/s     VSZ     RSS   %MEM  Command
 1234      0.50      0.00  1234567  245678   1.53  postgres
```
- `minflt/s` — minor faults (pages in memory, just need mapping)
- `majflt/s` — major faults (pages on disk — high values mean swapping or memory pressure)
- `VSZ` — virtual size
- `RSS` — resident set size

**I/O-specific fields (`pidstat -d`):**
```
  PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
 1234      0.00     12.50      0.00       5  postgres
```
- `kB_rd/s`, `kB_wr/s` — read/write throughput
- `kB_ccwr/s` — cancelled writes (truncated before written)
- `iodelay` — I/O delay in clock ticks (high = waiting for I/O)

### `mpstat` — Per-CPU Utilization

**Source:** sysstat

```bash
# All CPUs, 1s intervals
mpstat -P ALL 1

# Just CPU 0 and 1, 3 times
mpstat -P 0,1 1 3

# Summary only (no per-CPU)
mpstat 1 5

# JSON output
mpstat -P ALL -o JSON 1 2
```

**Output fields:**
```
%usr  %nice  %sys  %iowait  %irq  %soft  %steal  %guest  %gnice  %idle
 8.5    0.0   2.1      0.3   0.0    0.2     0.0     0.0     0.0   88.9
```

**Detecting CPU steal (virtualization):**
When `%steal` is consistently >5%, the hypervisor is oversubscribing CPU. This is invisible without `mpstat` or `vmstat`.

---

## Memory Tools

### `free` — Quick Memory Overview

**Source:** procps-ng

```bash
free -h                        # Human-readable
free -w                        # Wide (separates buffers/cache)
free -t                        # Show total line
free -s 2 -c 5                 # 5 snapshots, 2s apart

# Parse-friendly output
free -b | awk '/^Mem:/ {print $2, $3, $4, $7}'
```

**Reading `free -hw`:**
```
              total        used        free      shared     buffers       cache   available
Mem:            15G        5.8G        3.9G        300M        245M        5.7G        8.0G
Swap:          2.0G        200M        1.8G
```

**The critical numbers:**
- **available** (not free!) = how much memory can be given to new apps
- **used** = total - free - buffers/cache (but NOT the true consumption)
- Real memory pressure: when **available** drops below 10% of total

### `vmstat` — Virtual Memory Statistics

**Source:** procps-ng

`vmstat` reads `/proc/stat`, `/proc/meminfo`, `/proc/vmstat`, and `/proc/diskstats`.

```bash
vmstat 1                         # Continuous 1s updates
vmstat 1 10                      # 10 updates, 1s apart
vmstat -s                        # Event counters since boot
vmstat -d                        # Disk statistics
vmstat -p /dev/sda1              # Partition statistics
```

**Output fields:**
```
procs  -----------memory----------  ---swap--  -----io----  -system--  ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs  us  sy  id  wa  st
 2  0   200K  3.9G   245M   5.7G    0    0    12    50  123  456   8   2  89   0   0
```

| Column | Group | Meaning |
|--------|-------|---------|
| r | procs | Processes waiting for CPU (run queue) |
| b | procs | Processes blocked on I/O |
| swpd | memory | Virtual memory used (swap out) |
| free | memory | Idle memory |
| buff | memory | Buffer cache |
| cache | memory | Page cache |
| si | swap | Swap in from disk (pages/s) |
| so | swap | Swap out to disk (pages/s) |
| bi | io | Blocks received from block device (reads) |
| bo | io | Blocks sent to block device (writes) |
| in | system | Interrupts per second |
| cs | system | Context switches per second |

**Critical thresholds:**
- `r` > CPU count: processes are queued for CPU
- `b` > 0: some processes blocked on I/O
- `si`/`so` > 0: swapping — system is out of RAM
- `wa` > 10%: disk I/O is a bottleneck

**Context switching context:**
```
High cs (>50,000/s on modern hardware) may indicate:
  - Too many threads/tasks competing
  - Heavy multiplexing (event loops)
  - Need to consolidate work or use epoll/kqueue
```

### `/proc/meminfo` Parsing with `awk` (Script-Ready)

```bash
#!/bin/bash
# memory-health.sh — checks memory thresholds
eval $(awk '
    /MemTotal/     {t=$2}
    /MemAvailable/ {a=$2}
    /SwapTotal/    {st=$2}
    /SwapFree/     {sf=$2}
    END {
        printf "MEM_TOTAL=%d; MEM_AVAIL=%d; SWAP_TOTAL=%d; SWAP_FREE=%d;", t, a, st, sf
    }
' /proc/meminfo)

MEM_PCT=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))
SWAP_PCT=$(( (SWAP_TOTAL - SWAP_FREE) * 100 / SWAP_TOTAL ))

[ "$MEM_PCT" -gt 90 ] && echo "CRITICAL: Memory ${MEM_PCT}% used"
[ "$SWAP_PCT" -gt 50 ] && echo "WARNING: Swap ${SWAP_PCT}% used"
```

---

## Disk & I/O Tools

### `iostat` — Device-Level I/O Statistics

**Source:** sysstat

```bash
iostat -x 1                    # Extended stats, 1s intervals
iostat -x sda sdb 1 5          # Specific devices, 5 samples
iostat -p sda 1                # Per-partition
iostat -h                      # Human-readable
iostat -o JSON                 # JSON output (for scripting)
```

**Extended fields (`-x`):**
```
Device  r/s    w/s   rkB/s   wkB/s  rrqm/s  wrqm/s  %rrqm  %wrqm  await  r_await  w_await  svctm  %util
sda    45.0  120.0  800.0  2400.0    5.0    30.0    10.0   20.0   4.5     3.2      5.0    0.8    14.2
```

| Field | Meaning | Calculation |
|-------|---------|-------------|
| r/s | Read I/O requests per second | `reads_completed` delta |
| w/s | Write I/O requests per second | `writes_completed` delta |
| rkB/s | Kilobytes read per second | `sectors_read` × 512 / 1024 / time |
| await | Average I/O response time (ms) | `time_read + time_written` / `reads+ writes` |
| r_await | Read response time | Time spent reading / reads |
| w_await | Write response time | Time spent writing / writes |
| svctm | Average service time (ms) | `time_in_io` / I/Os completed |
| %util | Device busy percentage | `time_in_io` / sample_time × 100 |

**Interpreting disk metrics:**
- **await** vs **svctm**: If `await >> svctm`, there's queuing — the device is saturated
- **%util** 100%: device is busy 100% of the time, but can still handle more I/O with queuing (especially SSDs)
- **High queue but low util**: I/O controller bottleneck, not device

### `iotop` — Per-Process I/O (Root Required)

```bash
iotop                           # Interactive mode
iotop -b -n 3 -d 2              # Batch mode, 3 samples, 2s apart
iotop -P                        # Show processes only (no threads)
iotop -u www-data               # Only www-data's I/O
iotop -o                        # Only processes with actual I/O
iotop -k                        # KB/s instead of generic units
```

**Output:**
```
Total DISK READ: 12.00 M/s | Total DISK WRITE: 45.00 M/s
  TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN      IO>    COMMAND
 1234 be/4  postgres    8.00 M/s   30.00 M/s  0.00 %   2.50 %  postgres: writer
```

**Why it's useful:** `iostat` shows the device is busy. `iotop` shows *which process* is causing it.

### `df` and `du` — Disk Usage

**`df` (disk free):**
```bash
df -h                         # Human-readable
df -hT                        # Include filesystem type
df -h --total                 # Grand total
df /var                       # Specific mount point
df -i                         # Inode usage (critical for mail spools, /tmp)
```

**`du` (disk usage):**
```bash
du -sh /*                      # Root level, human-readable
du -sh /var/* | sort -rh      # Largest in /var
du --max-depth=2 /home        # Two-level deep
du -sh --exclude=/proc        # Exclude pseudo-fs (for system-wide)
du -h -t 100M                 # Only show entries >100M
```

**Inode exhaustion check:**
```bash
df -i /
# If IUsed > 90%, filesystem is full of small files — `du` won't show this
```

### `lsblk` — Block Device Topology

```bash
lsblk                         # Tree view
lsblk -f                      # Filesystem info (UUID, label, type)
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,UUID,MODEL
lsblk -t                      # Topology (queue info)
lsblk -S                      # SCSI devices only
```

---

## Network Tools

### `ss` — Modern Socket Statistics (Replaces `netstat`)

**Source:** iproute2

`ss` uses **Netlink** (not `/proc`) — faster and more feature-rich than `netstat`.

```bash
# All listening sockets
ss -tlnp                      # TCP, listening, numeric, process
ss -ulnp                      # UDP, listening, numeric, process
ss -xlnp                      # Unix domain sockets

# Established connections
ss -tn state established      # TCP established
ss -t4n                       # IPv4 only
ss -t6n                       # IPv6 only

# Connection states
ss -t4n state time-wait       # Connections in TIME_WAIT
ss -t4n state fin-wait-1      # Half-closed connections

# Socket details
ss -tlnpe                     # Process, user, inode info
ss -tlnm                      # Memory usage per socket
ss -tlni                      # TCP info (cwnd, ssthresh, rtt)

# Filtering
ss -t '( dport = :http or sport = :https )'
ss -t '( dst 10.0.0.0/24 )'
ss -t '( sport > :1024 )'

# Socket-level memory
ss -tlnm | grep -oP 'skmem\([^)]+\)' | head -5
# Example: skmem(r1,rb1,t1,tb1,f1,f0,t0,t0,0,0)
# r=receive buffer, t=transmit buffer, b=allocated
```

**Why `ss` over `netstat`:**
- Faster (Netlink vs /proc/net/tcp parsing)
- Shows TCP congestion window, RTT, retransmissions
- Better filtering (by port range, CIDR, state)
- Available by default on modern distros (iproute2 is essential)

**Retransmission detection:**
```bash
ss -ti | grep -oP 'retransmits:\K[0-9]+' | sort -rn | head -5
```

### `ip` — Network Interface & Route Control

**Source:** iproute2

```bash
# Interface statistics
ip -s link show eth0           # Detailed counters (like /proc/net/dev)
ip -s -s link show eth0        # Even more detail (per-queue stats)
ip -statistics link            # All interfaces

# Address information
ip addr show eth0              # IP addresses, prefix length

# Neighbour (ARP) table
ip neigh show                  # MAC resolution status
ip neigh show nud stale       # Expired neighbours

# Routing
ip route show                  # Routing table
ip route get 8.8.8.8          # Which interface will be used

# VRF / network namespace awareness
ip netns list                  # List namespaces
ip netns exec <ns> ip addr    # Execute in namespace

# Monitor real-time events
ip monitor link                # Link up/down events
ip monitor addr                # Address changes
ip monitor route               # Route changes

# Bandwidth delay product (congestion)
ip route show cache            # Cached routes (if enabled)
```

### `sar` (network specific) — Historical Network Throughput

```bash
# Live network throughput (per interface)
sar -n DEV 1 10               # 10 samples, 1s apart

# Live error/drop counts
sar -n EDEV 1 10

# Live socket counts
sar -n SOCK 1 10

# Live TCP state counts
sar -n TCP,ETCP 1 10

# Historical — yesterday's network data
sar -n DEV -f /var/log/sysstat/sa$(date -d yesterday +%d)
```

### `tcpdump` — Packet Capture (No Agent, Kernel-Level)

```bash
# Capture all traffic on eth0 (no name resolution)
tcpdump -i eth0 -nn

# Count by protocol
tcpdump -i any -nn -c 10000 | awk -F' ' '{print $3}' | sort | uniq -c | sort -rn

# HTTP traffic (port 80)
tcpdump -i any -nn 'tcp port 80'

# SYN packets (new connections)
tcpdump -i any 'tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & (tcp-ack) == 0'

# DNS queries
tcpdump -i any -nn 'udp port 53'

# Save to file for later analysis
tcpdump -i any -w /tmp/capture.pcap -c 100000
# Read back
tcpdump -r /tmp/capture.pcap -nn

# Extract HTTP hosts from pcap
tcpdump -r capture.pcap -A 'tcp port 80' | grep -oP 'Host: \K[^\r\n]+' | sort -u
```

### `nstat` — Kernel SNMP Counters (Clean /proc/net/snmp Wrapper)

```bash
nstat -az                     # All counters with zeros
nstat | head -20              # Top counters
nstat -s                      # Summary
watch -n 1 nstat | grep -E '(Tcp.*Retrans|Tcp.*Loss)'   # Retransmit rate
```

---

## System Logs & Events

### `dmesg` — Kernel Ring Buffer

```bash
# Recent and important
dmesg -T | tail -50           # Human-readable timestamps
dmesg --level=err,warn        # Only errors and warnings
dmesg --level=err -T | tail -20

# Hardware errors (memory, PCI, CPU)
dmesg -T | grep -i error
dmesg -T | grep -iE '(hardware|bug|oops|segfault)'

# OOM events
dmesg -T | grep -i oom

# Disk errors
dmesg -T | grep -iE '(sda|sdb|nvme|I/O error)'

# USB events
dmesg -T | grep -i usb

# Following in real-time
dmesg -w
```

### `journalctl` — systemd Journal Query

```bash
# Unit-specific
journalctl -u nginx.service -n 100 --no-pager
journalctl -u nginx.service -f                 # Follow mode

# By severity
journalctl -p err -b                           # Errors since boot
journalctl -p warning -b                       # Warnings since boot

# By time
journalctl --since "yesterday"
journalctl --since "2025-01-01" --until "2025-01-02"
journalctl --since "-1 hour"

# By field
journalctl _SYSTEMD_UNIT=sshd.service
journalctl _PID=1234
journalctl _UID=0                              # Root's messages
journalctl _TRANSPORT=kernel                   # Kernel messages only

# Output formats
journalctl -o json-pretty                      # Structured JSON
journalctl -o verbose                          # All fields
journalctl -o short-full                       # Full dates

# Disk usage
journalctl --disk-usage
journalctl --vacuum-size=200M                  # Clean to 200MB
journalctl --vacuum-time=30d                   # Keep 30 days

# Export/backup
journalctl -o export > journal-backup.jexp     # Reloadable format
```

### `last` / `lastb` — Login Audit

```bash
last -20                           # Last 20 logins
last -F                            # Full timestamps
last -i                            # Show IP instead of hostname
last -x                            # Show system shutdowns/reboots
lastb                              # Failed login attempts
lastb -10                          # Last 10 failed logins
```

### `ausearch` / `aureport` — Auditd Queries

**Requires `auditd` running:**
```bash
ausearch -ua 1000                 # All events for user UID 1000
ausearch -f /etc/shadow           # Access to a specific file
ausearch -sc openat               # Filter by syscall name
ausearch -i                        # Interpret numeric fields

aureport --summary                 # Summary of all events
aureport -l                        # Login report
aureport -f                        # File access report
aureport -x                        # Execution report
```

---

## sysstat (sar) — The Historical Swiss Army Knife

### Architecture

```
┌─────────────┐     ┌───────────┐     ┌──────────────┐
│  sadc (data  │────>│  saDD     │────>│  sar (query) │
│  collector)  │     │  (binary  │     │              │
│  runs via    │     │  log)     │     │  human-r/pt  │
│  cron/systemd│     │           │     │  output      │
└─────────────┘     └───────────┘     └──────────────┘
```

### Enable sysstat

```bash
# Debian/Ubuntu
apt install sysstat
systemctl enable --now sysstat

# RHEL/CentOS/Fedora
yum install sysstat
systemctl enable --now sysstat

# Check if active
systemctl status sysstat
```

### Configuration

**`/etc/sysstat/sysstat` (or `/etc/default/sysstat`):**
```bash
# How long to keep data (in days)
HISTORY=28

# Compress after N days
COMPRESSAFTER=10

# sadc extra options
SADC_OPTIONS="-S DISK"

# Collection interval in minutes
# Default: every 10 minutes (via cron)
# Edit: /etc/cron.d/sysstat
```

**`/etc/cron.d/sysstat` (controls collection frequency):**
```bash
# Run system activity accounting tool every 10 minutes
*/10 * * * * root /usr/lib64/sa/sa1 1 1
# 59 23 * * * root /usr/lib64/sa/sa2 -A
```

### Query Examples

```bash
# CPU
sar -u                             # Today's CPU stats
sar -u 1 5                         # Live, 5 samples
sar -u -f /var/log/sysstat/sa01    # Specific day (1st of month)
sar -u -s 10:00:00 -e 12:00:00     # Time range

# Memory
sar -r                             # Memory utilization
sar -S                             # Swap utilization
sar -W                             # Swap statistics (swap in/out)

# Disk I/O
sar -b                             # I/O transaction rate
sar -d -p                          # Per-disk I/O (-p = pretty names)
sar -d -p 1 3                      # Live, 3 samples

# Network
sar -n DEV                         # Interface throughput
sar -n EDEV                        # Interface errors
sar -n TCP,ETCP                    # TCP stats + errors

# Context switches
sar -w                             # Context switches + task creation

# Paging
sar -B                             # Paging statistics

# Load average
sar -q                             # Queue length + load average

# Power management
sar -m CPU -u                      # Per-CPU frequency (if cpufreq)

# Combined (everything for a period)
sar -A -f /var/log/sysstat/sa05    # ALL data for 5th of month
```

**Custom resolution (live, sub-second):**
```bash
sar -u 0.5 10                      # Every 500ms, 10 times
```

### XML/JSON Output

```bash
sar -u -o /tmp/sar-output         # Binary format
sadf -d /tmp/sar-output           # Semi-colon delimited (for CSV)
sadf -j /tmp/sar-output           # JSON
sadf -x /tmp/sar-output           # XML

# Historical date range in JSON
sadf -j /var/log/sysstat/sa01 -- -u
```

### Build a Daily Report

```bash
#!/bin/bash
# daily-report.sh — generate yesterday's report
YESTERDAY=$(date -d yesterday +%d)
echo "=== CPU Report ==="
sar -u -f /var/log/sysstat/sa$YESTERDAY
echo "=== Memory Report ==="
sar -r -f /var/log/sysstat/sa$YESTERDAY
echo "=== Network Report ==="
sar -n DEV -f /var/log/sysstat/sa$YESTERDAY | grep eth0
echo "=== Disk Report ==="
sar -d -p -f /var/log/sysstat/sa$YESTERDAY
```

---

## Tool Comparison Matrix

### What to Use for Common Tasks

| Task | Best tool | Alternative | Source |
|------|-----------|-------------|--------|
| Current CPU % | `mpstat -P ALL 1` | `top -bn1` | sysstat |
| Historical CPU | `sar -u` | `sadf -j` | sysstat |
| Per-process CPU | `pidstat 1` | `top -bn1 -p PID` | sysstat |
| Current memory | `free -h` | `vmstat 1` | procps |
| Per-process memory | `pidstat -r 1` | `ps aux --sort=-%mem` | sysstat |
| Memory details | `cat /proc/meminfo` | `free -w` | kernel |
| Disk throughput | `iostat -x 1` | `sar -d -p 1 3` | sysstat |
| Per-process I/O | `iotop -b -n 1` | `pidstat -d 1` | iotop |
| Disk usage | `df -h` / `du -sh *` | `ncdu` | coreutils |
| Network throughput | `sar -n DEV 1` | `ip -s link` | sysstat |
| Connections | `ss -tlnp` | `ss -tn state established` | iproute2 |
| Packet capture | `tcpdump -i any` | `tcpdump -w file` | tcpdump |
| Socket details | `ss -tlnpe` | `ss -tlnm` (mem) | iproute2 |
| Kernel logs | `dmesg -T` | `dmesg -w` | util-linux |
| Service logs | `journalctl -u svc` | `journalctl -f` | systemd |
| Login audit | `last -20` | `ausearch -ua UID` | shadow |
| Per-service cgroup | `systemd-cgtop` | `cat <cgroup>/memory.current` | systemd |
| Boot analysis | `systemd-analyze blame` | `systemd-analyze plot` | systemd |
| All-in-one live | `dstat 1` / `atop 1` | `glances` | third-party |
| All-in-one historical | `sar -A` | `sadf -j` | sysstat |
