# Kernel Interfaces — `/proc`, `/sys`, Netlink, sysfs, tracefs

## Table of Contents
1. [Overview: What the Kernel Exposes](#overview-what-the-kernel-exposes)
2. [procfs (`/proc`)](#procfs-proc)
3. [sysfs (`/sys`)](#sysfs-sys)
4. [Other Kernel Interfaces](#other-kernel-interfaces)
5. [Practical: Reading Metrics Programmatically](#practical-reading-metrics-programmatically)
6. [Performance & Pitfalls](#performance--pitfalls)

---

## Overview: What the Kernel Exposes

The Linux kernel exposes system state through several pseudo-filesystems — virtual files that don't exist on disk but are generated on-the-fly when read. This is the foundation of every monitoring tool on Linux.

| Filesystem | Mount point | Kernel subsystem | Content type |
|------------|-------------|------------------|--------------|
| **procfs** | `/proc` | Process scheduler, memory mgr, VFS | Process info, system-wide stats |
| **sysfs** | `/sys` | Driver model, devices, block, power | Device hierarchy, attributes |
| **tracefs** | `/sys/kernel/tracing` | Ftrace | Kernel tracing events |
| **debugfs** | `/sys/kernel/debug` | Various debug subsystems | Raw kernel debug data |
| **cgroupfs** | `/sys/fs/cgroup` | Control groups (cgroups v2) | Resource limits & accounting |
| **configfs** | `/sys/kernel/config` | Kernel object configuration | Userspace-driven kernel config |
| **bpf_fs** | `/sys/fs/bpf` | BPF | BPF maps & programs |
| **selinuxfs** | `/sys/fs/selinux` | SELinux | Security policy & enforcement |

> All of these are **zero-copy** from kernel memory — reading them incurs a context switch but no disk I/O.

---

## procfs (`/proc`)

### How procfs Works

When you `cat /proc/meminfo`, the kernel calls the `meminfo_proc_show()` function which formats memory statistics directly from kernel data structures into the read buffer. The data is **generated at read time**, never cached on disk.

### System-Wide Files

#### CPU — `/proc/stat`

```
cpu  1012453 1245 258912 90812345 67891 12345 9876 0 0 0
cpu0 504123  600  129001 45406172 34012 6000  5000 0 0 0
cpu1 508330  645  129911 45406173 33879 6345  4876 0 0 0
intr 23456789 ...      (interrupt counters per IRQ)
ctxt 12345678           (context switches since boot)
btime 1709123456        (boot timestamp, epoch seconds)
processes 56789         (processes created since boot)
procs_running 2         (processes currently running)
procs_blocked 0         (processes blocked on I/O)
```

**Columns for `cpu` line:**
1. **user** — normal processes executing in user mode
2. **nice** — niced processes in user mode
3. **system** — kernel processes (system calls, interrupts)
4. **idle** — time spent doing nothing
5. **iowait** — waiting for I/O to complete
6. **irq** — servicing hardware interrupts
7. **softirq** — servicing software interrupts
8. **steal** — time stolen by hypervisor (virtualization only)
9. **guest** — time running a guest OS
10. **guest_nice** — niced guest time

**Calculating CPU utilization:**
```
total = user + nice + system + idle + iowait + irq + softirq + steal
idle_total = idle + iowait
usage_pct = (1 - (idle_delta / total_delta)) * 100
```

**Bash one-liner for per-second CPU:**
```bash
#!/bin/bash
PREV=$(grep '^cpu ' /proc/stat)
sleep 1
CURR=$(grep '^cpu ' /proc/stat)
# awk calculates deltas and prints % for each category
awk -v prev="$PREV" -v curr="$CURR" '
BEGIN {
    split(prev, p); split(curr, c)
    total_delta = (c[2]-p[2]) + (c[3]-p[3]) + (c[4]-p[4]) + (c[5]-p[5]) + (c[6]-p[6]) + (c[7]-p[7]) + (c[8]-p[8])
    printf "user:%.1f nice:%.1f system:%.1f idle:%.1f iowait:%.1f irq:%.1f softirq:%.1f steal:%.1f\n", \
        100*(c[2]-p[2])/total_delta, 100*(c[3]-p[3])/total_delta, 100*(c[4]-p[4])/total_delta, \
        100*(c[5]-p[5])/total_delta, 100*(c[6]-p[6])/total_delta, 100*(c[7]-p[7])/total_delta, \
        100*(c[8]-p[8])/total_delta, 100*(c[9]-p[9])/total_delta
}'
```

#### Memory — `/proc/meminfo`

```
MemTotal:       16384000 kB
MemFree:         3840000 kB
MemAvailable:    8240000 kB
Buffers:          240000 kB
Cached:          5600000 kB
SwapCached:         1200 kB
Active:          6200000 kB
Inactive:        3400000 kB
Active(anon):    3800000 kB
Inactive(anon):  1200000 kB
Active(file):    2400000 kB
Inactive(file):  2200000 kB
Unevictable:        1200 kB
Mlocked:               0 kB
SwapTotal:       2048000 kB
SwapFree:        2048000 kB
Dirty:               120 kB
Writeback:             0 kB
AnonPages:       4800000 kB
Mapped:           980000 kB
Shmem:             45000 kB
KReclaimable:     380000 kB
Slab:             520000 kB
SReclaimable:     380000 kB
SUnreclaim:       140000 kB
KernelStack:       12000 kB
PageTables:        96000 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:    10240000 kB
Committed_AS:    6800000 kB
VmallocTotal:   34359738367 kB
VmallocUsed:       72000 kB
VmallocChunk:          0 kB
Percpu:            12000 kB
HardwareCorrupted:     0 kB
AnonHugePages:   2400000 kB
ShmemHugePages:        0 kB
ShmemPMDMapped:        0 kB
FileHugePages:         0 kB
FilePMDMapped:         0 kB
CmaTotal:              0 kB
CmaFree:               0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB
DirectMap4k:      240000 kB
DirectMap2M:     8200000 kB
DirectMap1G:     8192000 kB
```

**Key fields explained:**

- **MemTotal** — total physical RAM
- **MemFree** — completely unused pages (not very useful by itself)
- **MemAvailable** — **the most useful metric**: memory available for starting new applications without swapping. Includes free + reclaimable caches. This is what `free` reports as "available".
- **Buffers** — raw disk block cache
- **Cached** — page cache (file contents in memory)
- **Active** / **Inactive** — recently/potentially reclaimable pages
- **SwapTotal** / **SwapFree** — swap space
- **Dirty** — data modified in memory, waiting to be written to disk
- **Slab** — kernel object cache (SReclaimable = can be freed, SUnreclaim = pinned)

**Real memory usage calculation:**
```
True system-wide usage = MemTotal - MemAvailable
Per-process RSS ≠ process real memory (pages are shared!)
```

#### Load Average — `/proc/loadavg`

```
0.45 0.30 0.20 2/345 67890
```

| Field | Meaning |
|-------|---------|
| 0.45 | 1-minute load average |
| 0.30 | 5-minute load average |
| 0.20 | 15-minute load average |
| 2/345 | Currently running / total threads |
| 67890 | Last created PID |

**Interpreting load:**
- Load = number of processes **running** + **waiting** for CPU
- On a 4-core machine, load of 4 = fully utilized (no queuing)
- Load of 8 = average 4 processes waiting on CPU
- High load + low CPU utilization → processes are blocked on I/O (not CPU-bound)

#### Network — `/proc/net/dev`

```
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 1234567  12345    0    0    0     0          0         0  1234567  12345    0    0    0     0       0          0
 eth0: 987654321 987654  0    5    0     0          0         0 654321987 456789  0    2    0     0       0          0
```

**Important counters:**
- **errs** — hardware / driver errors (often cable problems)
- **drop** — packets dropped by kernel (full receive ring, firewall, etc.)
- **fifo** — FIFO overrun (kernel buffer too small)
- **frame** — framing errors (physical layer issues)
- **colls** — collisions (half-duplex only, legacy)

**Throughput (bytes/s):** sample, wait 1s, sample again, subtract.

```bash
#!/bin/bash
IFACE=eth0
RX1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
echo "RX: $(( (RX2 - RX1) / 1024 )) KB/s | TX: $(( (TX2 - TX1) / 1024 )) KB/s"
```

#### Disk I/O — `/proc/diskstats`

```
 251       0 sda 123456 2345 7890123 45678 98765 4321 654321 23456 0 12345 67890
```

| Field | Offset | Meaning |
|-------|--------|---------|
| major | 1 | Major device number |
| minor | 2 | Minor device number |
| name | 3 | Device name |
| reads completed | 4 | Successful reads |
| reads merged | 5 | Adjacent reads merged by elevator |
| sectors read | 6 | Sectors read successfully |
| time reading (ms) | 7 | Time spent reading |
| writes completed | 8 | Successful writes |
| writes merged | 9 | Adjacent writes merged |
| sectors written | 10 | Sectors written |
| time writing (ms) | 11 | Time spent writing |
| I/O in progress | 12 | Currently outstanding I/Os |
| time in I/O (ms) | 13 | Total time device had I/O outstanding |
| weighted I/O time (ms) | 14 | Weighted time device had I/O outstanding |

**Derived metrics (require 2 samples):**

```bash
#!/bin/bash
# iops-calc.sh — calculate IOPs and latency from /proc/diskstats
S1=$(awk '$3=="sda" {print $4,$5,$8,$9,$12,$13}' /proc/diskstats)
sleep 1
S2=$(awk '$3=="sda" {print $4,$5,$8,$9,$12,$13}' /proc/diskstats)

awk -v s1="$S1" -v s2="$S2" '
BEGIN {
    split(s1, a); split(s2, b)
    rio = b[1] - a[1]      # read I/Os
    rmerge = b[2] - a[2]   # merged reads
    wio = b[3] - a[3]      # write I/Os
    wmerge = b[4] - a[4]   # merged writes
    ios = rio + wio
    ms_in_io = b[6] - a[6] # ms device had I/O outstanding
    pct_util = ms_in_io / 10   # device utilization %

    printf "Read IOPs: %d\nWrite IOPs: %d\nTotal IOPs: %d\nUtilization: %.1f%%\n", rio, wio, ios, pct_util
}'
```

### Per-Process Files

Each running process has a directory `/proc/<pid>/`:

| Entry | Content |
|-------|---------|
| `cmdline` | Full command line (null-byte separated) |
| `cwd` | Symlink to current working directory |
| `exe` | Symlink to executable |
| `fd/` | Directory of open file descriptors |
| `fdinfo/` | Per-FD flags, position, mount info |
| `io` | I/O counters: read/write bytes and syscalls |
| `limits` | Resource limits (ulimit) |
| `maps` | Memory-mapped regions |
| `mem` | Process memory (requires ptrace) |
| `mountinfo` | Mount namespace details |
| `net/` | Process-level network info |
| `ns/` | Namespace references |
| `oom_score` | OOM killer score (higher = more likely killed) |
| `oom_score_adj` | OOM score adjustment |
| `root` | Symlink to root directory |
| `smaps` | Detailed per-region memory maps |
| `smaps_rollup` | Aggregated memory statistics |
| `stat` | Process state, PPID, priority, CPU ticks |
| `statm` | Memory: size, rss, shared, text, lib, data, dt |
| `status` | Human-readable process info |
| `task/` | Threads directory |
| `wchan` | What the process is waiting on (if sleeping) |

**`/proc/<pid>/smap` (most useful for memory analysis):**

```
555555554000-555555556000 r-xp 00000000 08:01 1234567 /bin/cat
Size:                 16 kB
KernelPageSize:        4 kB
MMUPageSize:           4 kB
Rss:                  12 kB
Pss:                   8 kB
Pss_Dirty:             0 kB
Shared_Clean:          4 kB
Shared_Dirty:          0 kB
Private_Clean:         8 kB
Private_Dirty:         0 kB
Referenced:           12 kB
Anonymous:             0 kB
LazyFree:              0 kB
AnonHugePages:         0 kB
ShmemPmdMapped:        0 kB
FilePmdMapped:         0 kB
Shared_Hugetlb:        0 kB
Private_Hugetlb:       0 kB
Swap:                  0 kB
SwapPss:               0 kB
Locked:                0 kB
THPeligible:           1
VmFlags: rd ex mr mw me dw sd
```

**PSS (Proportional Set Size)** is the most accurate memory metric: it divides shared pages equally among the processes sharing them. RSS double-counts shared memory.

```bash
# Per-process PSS total
awk '/^Pss:/ { sum += $2 } END { print sum " kB" }' /proc/<pid>/smaps
```

---

## sysfs (`/sys`)

### How sysfs Works

sysfs exposes the kernel **device model** as a filesystem. Each kernel object (device, driver, bus, class) is a directory, and its attributes are files. It's the successor to `/proc` for device-related information.

### CPU — `/sys/devices/system/cpu/`

```
/sys/devices/system/cpu/
├── cpu0/
│   ├── cache/index0/          # L1 data cache info
│   ├── cache/index1/          # L1 instruction cache
│   ├── cache/index2/          # L2 cache
│   ├── cache/index3/          # L3 cache
│   ├── cpufreq/                # CPU frequency scaling
│   │   ├── scaling_cur_freq   # Current frequency (kHz)
│   │   ├── scaling_min_freq   # Min frequency (kHz)
│   │   ├── scaling_max_freq   # Max frequency (kHz)
│   │   ├── scaling_governor   # Governor (performance, powersave, ondemand)
│   │   ├── scaling_available_governors
│   │   └── stats/             # Time-in-state statistics
│   ├── topology/
│   │   ├── core_id            # Physical core ID
│   │   ├── core_siblings_list # CPUs sharing this core
│   │   ├── thread_siblings_list # SMT threads on this core
│   │   └── die_id             # Die ID for multi-die CPUs
│   ├── online                 # 1 if online, 0 if offline
│   └── thermal_throttle/
├── cpu1/
├── offline
├── online
├── possible
└── present
```

**CPU frequency monitoring:**
```bash
#!/bin/bash
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    num=$(basename "$cpu")
    freq=$(cat "$cpu/cpufreq/scaling_cur_freq" 2>/dev/null || echo "offline")
    gov=$(cat "$cpu/cpufreq/scaling_governor" 2>/dev/null || echo "-")
    echo "$num: ${freq} kHz [${gov}]"
done
```

### Memory — `/sys/devices/system/memory/`

**Hotplug memory info (useful in VM/cloud environments):**
```bash
ls /sys/devices/system/memory/
# memory0/ memory1/ ... memoryN/
cat /sys/devices/system/memory/memory0/online  # 0 or 1
```

### Block Devices — `/sys/block/`

```
/sys/block/sda/
├── sda1/
├── sda2/
├── queue/
│   ├── scheduler          # I/O scheduler (mq-deadline, kyber, none)
│   ├── nr_requests        # Max I/O requests in queue
│   ├── rotational         # 1=HDD, 0=SSD
│   ├── iostats            # Enable/disable I/O stats
│   ├── read_ahead_kb      # Read-ahead size
│   ├── add_random          # Add entropy from I/O timing
│   └── discard_max_bytes  # Max discard size for SSDs
├── device/
│   ├── model              # Disk model name
│   ├── vendor             # Vendor name
│   ├── rev                # Revision
│   └── timeout            # Command timeout (sec)
├── size                   # Total size (512-byte sectors)
├── stat                   # Block layer statistics (same as /proc/diskstats)
└── inflight               # Currently in-flight I/Os (rd, wr)

# Per-partition directory
/sys/block/sda/sda1/
├── partition             # Partition number
├── start                 # Start sector
└── size                  # Partition size (sectors)
```

**Check if drive is HDD or SSD:**
```bash
cat /sys/block/sda/queue/rotational   # 1 = HDD, 0 = SSD
```

**Read I/O scheduler:**
```bash
cat /sys/block/sda/queue/scheduler
# [mq-deadline] kyber  none
```

### Network — `/sys/class/net/`

```
/sys/class/net/eth0/
├── address                # MAC address
├── addr_len               # MAC address length
├── carrier                # 1=link detected, 0=no link
├── carrier_changes        # Carrier change count
├── dev_id                 # Device ID
├── dev_port               # Port number
├── dormant                # Dormant state
├── duplex                 # full/half
├── flags                  # Interface flags (hex)
├── gro_flush_timeout      # Generic receive offload timeout
├── ifalias                # Interface alias
├── ifindex                # Interface index
├── iflink                 # Associated device index
├── link_mode              # Link mode
├── mtu                    # Maximum Transmission Unit
├── name_assign_type       # How the name was assigned
├── netdev_group           # Netdev group
├── operstate              # Operational state (up/down)
├── phys_port_id           # Physical port identifier
├── phys_port_name         # Physical port name
├── phys_switch_id         # Physical switch identifier
├── power/
├── proto_down             # Protocol-down state
├── queues/
│   ├── rx-0/              # Receive queue 0
│   └── tx-0/              # Transmit queue 0
├── speed                  # Link speed (Mbps)
├── statistics/            # Per-interface counters
│   ├── rx_bytes
│   ├── rx_packets
│   ├── rx_errors
│   ├── rx_dropped
│   ├── rx_fifo_errors
│   ├── rx_frame_errors
│   ├── rx_multicast
│   ├── rx_compressed
│   ├── rx_nohandler
│   ├── tx_bytes
│   ├── tx_packets
│   ├── tx_errors
│   ├── tx_dropped
│   ├── tx_fifo_errors
│   ├── tx_carrier_errors
│   └── tx_heartbeat_errors
├── tx_queue_len           # TX queue length
└── type                   # Interface type (ARP HRD)
```

**Why use `/sys/class/net/.../statistics/` over `/proc/net/dev`?**
- Per-statistic file = read only what you need (fewer string splits)
- Even cleaner for scripting
- Values are unsigned long, same as /proc

**Network monitoring — detect interface flapping:**
```bash
#!/bin/bash
# check-carrier.sh — alert on link flapping
IFACE=${1:-eth0}
BEFORE=$(cat /sys/class/net/$IFACE/carrier_changes 2>/dev/null || echo 0)
sleep 60
AFTER=$(cat /sys/class/net/$IFACE/carrier_changes 2>/dev/null || echo 0)
DELTA=$((AFTER - BEFORE))
if [ "$DELTA" -gt 10 ]; then
    echo "WARNING: $IFACE carrier changed $DELTA times in 60s (possible flapping)"
fi
```

### Power & Thermal — `/sys/class/power_supply/` and `/sys/class/thermal/`

```bash
# Battery info (laptops/embedded)
cat /sys/class/power_supply/BAT0/capacity         # 0-100%
cat /sys/class/power_supply/BAT0/status           # Charging/Discharging/Full

# Thermal zones
for z in /sys/class/thermal/thermal_zone*; do
    echo "$(basename $z): type=$(cat $z/type) temp=$(cat $z/temp)C"
done
```

---

## Other Kernel Interfaces

### Netlink — The "Fast Path" to Kernel State

Netlink is a socket-based interface for communicating with the kernel, used by modern tools (`ip`, `ss`, `tc`). Unlike `/proc` which requires a read syscall and string parsing, Netlink sends structured binary messages.

```
Application --> [NETLINK socket] --> Kernel subsystem
```

**Common Netlink protocols:**
| Protocol | Family | Used by | Purpose |
|----------|--------|---------|---------|
| NETLINK_ROUTE | 0 | `ip`, `ss`, `tc` | Routing, links, addresses, neighbours |
| NETLINK_KOBJECT_UEVENT | 15 | udev | Device hotplug events |
| NETLINK_AUDIT | 13 | auditd | Security audit events |
| NETLINK_SELINUX | 7 | SELinux | SELinux events |

**Why it matters for monitoring:**
- `/proc/net/dev` is polled (you must keep re-reading)
- Netlink can **push** events (link up/down, new neighbour, etc.)
- `ip monitor` subscribes to real-time kernel events:
  ```bash
  ip monitor all                        # Links, addresses, routes in real time
  ip monitor link dev eth0              # Only eth0 link events
  ss -t -e -m state ESTABLISHED         # TCP socket details via Netlink
  ```

### cgroups v2 — `/sys/fs/cgroup/`

Modern resource accounting is done via cgroups v2. systemd automatically places every service in its own cgroup.

```bash
/sys/fs/cgroup/
├── cpu.stat                # CPU usage, throttling per group
├── memory.current          # Current memory usage
├── memory.stat             # Detailed memory breakdown
├── io.stat                 # I/O statistics per device
├── pids.current            # Number of processes/threads
├── system.slice/
│   ├── sshd.service/
│   │   ├── cpu.stat
│   │   ├── memory.current
│   │   ├── pids.current
│   │   └── ...
│   ├── nginx.service/
│   └── postgresql.service/
└── user.slice/
    └── user-1000.slice/
```

**Per-service memory via cgroups:**
```bash
#!/bin/bash
for svc in /sys/fs/cgroup/system.slice/*.service; do
    name=$(basename "$svc")
    mem=$(cat "$svc/memory.current" 2>/dev/null || echo 0)
    mem_mb=$((mem / 1024 / 1024))
    echo "$name: ${mem_mb} MB"
done
```

### BPF (Berkeley Packet Filter) — The Modern Approach

BPF (eBPF) allows running sandboxed programs in kernel context. It's the engine behind modern observability tools but requires kernel support (Linux 4.0+).

**Notable BPF-based monitoring tools:**
| Tool | What it measures |
|------|-----------------|
| `bpftrace` | Dynamic tracing — function calls, latency, returns |
| `bcc` (Python/Lua) | Toolkit of BPF programs |
| `perf` | Sampling/profiling with BPF support |
| `pixie` | Kubernetes observability (BPF-based) |

**Example bpftrace one-liner:**
```bash
# Count syscalls per process (agentless, compiled in-kernel)
bpftrace -e 'tracepoint:syscalls:sys_enter_* { @[comm] = count(); }' -c "sleep 3"
```

**When to use BPF vs /proc:**
- `/proc` — polling with 1s+ intervals, lightweight, no compilation
- BPF — event-driven, zero-overhead when idle, needs kernel headers
- For most system monitoring, `/proc` is sufficient

### tracefs & ftrace — `/sys/kernel/tracing/`

```bash
# Available tracers
cat /sys/kernel/tracing/available_tracers
# function function_graph wakeup_dl wakeup_rt wakeup irqsoff preemptoff preemptirqsoff

# Enable function graph tracer
echo function_graph > /sys/kernel/tracing/current_tracer
echo 1 > /sys/kernel/tracing/tracing_on
# Wait...
cat /sys/kernel/tracing/trace
echo 0 > /sys/kernel/tracing/tracing_on
```

### Udev Events — Dynamic Device Monitoring

The kernel emits `uevent` messages over Netlink when devices are added/removed. `udevadm monitor` watches these:

```bash
udevadm monitor --property          # Real-time device events
udevadm monitor --kernel --subsystem-match=block   # Only block events
```

---

## Practical: Reading Metrics Programmatically

### Bash — Raw Read (Fastest)

```bash
# Single scalar — just cat it
load_1m=$(cut -d' ' -f1 /proc/loadavg)

# Multiple values — read once, parse
read mem_total mem_free mem_avail <<< $(awk '
    /MemTotal/ {t=$2}
    /MemFree/  {f=$2}
    /MemAvailable/ {a=$2}
    END {print t,f,a}
' /proc/meminfo)
```

### Python — File-based (Reliable)

```python
from pathlib import Path

def parse_keyval(path, sep=":"):
    """Parse /proc files with key: value format."""
    d = {}
    for line in Path(path).read_text().splitlines():
        if sep in line:
            k, v = line.split(sep, 1)
            d[k.strip()] = v.strip()
    return d

mem = parse_keyval("/proc/meminfo")
mem["MemAvailable"], mem["MemTotal"]
# ('8240000 kB', '16384000 kB')
```

### C — Minimal Overhead (Lowest-Level)

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    FILE *f = fopen("/proc/loadavg", "r");
    if (!f) { perror("fopen"); return 1; }
    double load1, load5, load15;
    int run, total;
    fscanf(f, "%lf %lf %lf %d/%d", &load1, &load5, &load15, &run, &total);
    fclose(f);
    printf("%.2f %.2f %.2f\n", load1, load5, load15);
    return 0;
}
```

### Go — Using Standard Library

```go
package main

import (
    "fmt"
    "os"
    "bufio"
    "strings"
)

func main() {
    f, _ := os.Open("/proc/meminfo")
    defer f.Close()
    scanner := bufio.NewScanner(f)
    m := map[string]string{}
    for scanner.Scan() {
        parts := strings.SplitN(scanner.Text(), ":", 2)
        if len(parts) == 2 {
            m[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
        }
    }
    fmt.Println("Available:", m["MemAvailable"])
}
```

---

## Performance & Pitfalls

### Overhead of Reading `/proc`/`/sys`

Each read is a syscall. The kernel format-string inside triggers callbacks.

| Operation | Approximate cost |
|-----------|-----------------|
| `cat /proc/loadavg` | ~2 µs |
| `cat /proc/meminfo` | ~10 µs |
| `cat /proc/<pid>/smaps` (large process) | ~1-10 ms |
| `find /sys -type f -exec cat {} \;` | slow, don't do this |

**Rules of thumb:**
- Don't poll more than once per second for most metrics
- Don't read `/proc/<pid>/smaps` for all PIDs in a loop — use `smaps_rollup`
- Prefer `ss` over reading `/proc/net/tcp` directly (kernel parsing is similar)
- Cache values that change slowly (CPU info, topology)

### Race Conditions

- Values in `/proc` files are **not atomic across reads** — reading `/proc/stat`, then `/proc/loadavg` gives different micro-timestamps
- For derived metrics (delta/second), sample pairs should be read as close together as possible
- Process directories (`/proc/<pid>/`) may vanish between read and stat — always handle `ENOENT`

### Long Lines & Format Changes

- Some files have very long lines (e.g., `/proc/<pid>/cmdline` with env vars via `/proc/<pid>/environ`)
- Kernel can add new fields (backwards compatible — new columns appended)
- Never assume a fixed number of columns; parse by name or position from the end

### Permissions

| File | Required Permission |
|------|--------------------|
| `/proc/<pid>/fd/` | Owner or root |
| `/proc/<pid>/mem` | `PTRACE` capability |
| `/proc/<pid>/io` | Owner or `CAP_NET_ADMIN` |
| `/proc/kcore` | Root (full memory image) |
| `/proc/kallsyms` | Root (kernel symbols) |
| `/sys/devices/virtual/powercap/` | Root (power capping) |
| Most `/proc/` and `/sys/` | World-readable |

---

## Summary

```
┌────────────────────────────────────────────────────────────┐
│  What do you want to monitor?                              │
│                                                            │
│  CPU usage      → /proc/stat, /sys/devices/system/cpu/    │
│  Memory         → /proc/meminfo, /proc/<pid>/smaps        │
│  Load           → /proc/loadavg                           │
│  Disk I/O       → /proc/diskstats, /sys/block/*/stat      │
│  Network        → /proc/net/dev, /sys/class/net/*/statistics│
│  Processes      → /proc/<pid>/stat, /proc/<pid>/status    │
│  Devices        → /sys, udev, Netlink                     │
│  Kernel events  → Netlink, tracefs, BPF                   │
│  Resource ctrl  → /sys/fs/cgroup/                         │
└────────────────────────────────────────────────────────────┘
```
