# System Monitoring

## psutil (CPU, memory, disk, network)

```bash
pip install psutil
```

### CPU

```python
import psutil

# CPU usage
psutil.cpu_percent(interval=1)          # overall CPU %
psutil.cpu_percent(interval=1, percpu=True)  # per-core
psutil.cpu_count()                      # logical cores
psutil.cpu_count(logical=False)         # physical cores
psutil.cpu_freq()                       # current frequency
psutil.getloadavg()                     # load average (1, 5, 15 min)
```

### Memory

```python
mem = psutil.virtual_memory()
print(f"Total: {mem.total / 1e9:.1f} GB")
print(f"Available: {mem.available / 1e9:.1f} GB")
print(f"Used: {mem.percent:.1f}%")

swap = psutil.swap_memory()
print(f"Swap used: {swap.percent:.1f}%")
```

### Disk

```python
# Disk usage
du = psutil.disk_usage("/")
print(f"Disk: {du.used / 1e9:.1f} / {du.total / 1e9:.1f} GB ({du.percent:.1f}%)")

# Disk I/O
dio = psutil.disk_io_counters(perdisk=True)
for disk, counters in dio.items():
    print(f"{disk}: read={counters.read_bytes / 1e6:.0f} MB, "
          f"write={counters.write_bytes / 1e6:.0f} MB")
```

### Network

```python
net = psutil.net_io_counters()
print(f"Bytes sent: {net.bytes_sent / 1e6:.1f} MB")
print(f"Bytes recv: {net.bytes_recv / 1e6:.1f} MB")

# Connections
connections = psutil.net_connections()
for conn in connections:
    if conn.status == "LISTEN":
        print(f"Listening: {conn.laddr.ip}:{conn.laddr.port}")

# Network interfaces
ifaces = psutil.net_if_addrs()
for name, addrs in ifaces.items():
    for addr in addrs:
        if addr.family.name == "AF_INET":
            print(f"{name}: {addr.address}")
```

### Processes

```python
# List all processes
for proc in psutil.process_iter(["pid", "name", "memory_percent", "cpu_percent"]):
    try:
        print(f"{proc.info['pid']:>6} {proc.info['name']:20} "
              f"CPU: {proc.info['cpu_percent']:>5.1f}% "
              f"MEM: {proc.info['memory_percent']:>5.2f}%")
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        pass

# Find process by name
def find_process(name: str) -> list[psutil.Process]:
    return [p for p in psutil.process_iter(["name"]) if p.info["name"] == name]

# Kill process tree
def kill_tree(proc: psutil.Process, sig: int = 15) -> None:
    for child in proc.children(recursive=True):
        child.send_signal(sig)
    proc.send_signal(sig)
```

### Sensors

```python
# Temperatures (Linux with lm-sensors)
if hasattr(psutil, "sensors_temperatures"):
    temps = psutil.sensors_temperatures()
    for name, entries in temps.items():
        for entry in entries:
            print(f"{name}: {entry.current}°C")

# Battery
battery = psutil.sensors_battery()
if battery:
    print(f"Battery: {battery.percent}% {'plugged' if battery.power_plugged else 'on battery'}")
```

## Resource usage decorator

```python
import psutil
import os
import time
from functools import wraps

def monitor(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        process = psutil.Process(os.getpid())
        cpu_before = process.cpu_percent(interval=None)
        mem_before = process.memory_info().rss
        start = time.perf_counter()

        try:
            result = func(*args, **kwargs)
        finally:
            elapsed = time.perf_counter() - start
            cpu_after = process.cpu_percent(interval=None)
            mem_after = process.memory_info().rss
            log.info(
                "%s: %.3fs  CPU: %.1f%%  MEM: %+.1f MB",
                func.__name__,
                elapsed,
                cpu_after,
                (mem_after - mem_before) / 1e6,
            )
        return result
    return wrapper
```

## Systemd service health

```python
import subprocess
import shlex

def service_status(name: str) -> dict:
    result = subprocess.run(
        ["systemctl", "show", "--no-page", name],
        capture_output=True, text=True,
    )
    props = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            props[k] = v
    return {
        "active": props.get("ActiveState") == "active",
        "running": props.get("SubState") == "running",
        "pid": props.get("MainPID"),
        "memory": props.get("MemoryCurrent"),
        "uptime": props.get("ActiveEnterTimestamp"),
    }
```

## Threshold alerting

```python
def check_system_thresholds() -> list[str]:
    alerts = []
    cpu = psutil.cpu_percent(interval=1)
    if cpu > 80:
        alerts.append(f"CPU usage high: {cpu}%")

    mem = psutil.virtual_memory()
    if mem.percent > 85:
        alerts.append(f"Memory usage high: {mem.percent}%")

    disk = psutil.disk_usage("/")
    if disk.percent > 90:
        alerts.append(f"Disk usage high: {disk.percent}%")

    return alerts
```

## Log monitoring (tail + pattern match)

```python
import time
from pathlib import Path

def tail_log(path: str, pattern: str, callback):
    import re
    compiled = re.compile(pattern)
    path = Path(path)
    last_size = path.stat().st_size

    while True:
        current_size = path.stat().st_size
        if current_size > last_size:
            with open(path) as f:
                f.seek(last_size)
                for line in f:
                    if compiled.search(line):
                        callback(line.strip())
        last_size = current_size
        time.sleep(1)
```

## Common monitoring patterns

```python
# Collect and log system info
def system_snapshot() -> dict:
    return {
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_percent": psutil.virtual_memory().percent,
        "disk_percent": psutil.disk_usage("/").percent,
        "load_avg": psutil.getloadavg(),
        "connections": len(psutil.net_connections()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
```
