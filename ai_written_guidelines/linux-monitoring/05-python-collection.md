# Python Collection — Parsing, Pushing, Central Server

## Table of Contents
1. [Why Python for Monitoring?](#why-python-for-monitoring)
2. [Robust /proc Parser](#robust-proc-parser)
3. [Delta Calculation Engine](#delta-calculation-engine)
4. [HTTP Push Client](#http-push-client)
5. [Central Ingestion Server](#central-ingestion-server)
6. [SQLite Storage & Queries](#sqlite-storage--queries)
7. [Asynchronous Architecture](#asynchronous-architecture)
8. [Integration with Existing Tools](#integration-with-existing-tools)
9. [Packaging & Deployment](#packaging--deployment)

---

## Why Python for Monitoring?

Bash works for simple collection, but Python wins when you need:
- **Error handling** — `try/except` vs `||` chains
- **Structured data** — JSON, dicts, dataclasses vs field-splitting
- **HTTP** — `requests` / `urllib` vs `curl` subprocesses
- **Threads** — parallel SSH or concurrent HTTP pushes
- **Libraries** — `psutil` (agentless, reads /proc), `prometheus_client`, `influxdb`
- **Testing** — unit tests for parsers, mock `open()`

**This section uses only stdlib** — no pip install required.

---

## Robust /proc Parser

### Base Parser with Error Handling

```python
#!/usr/bin/env python3
"""procutils.py — safe /proc /sys readers"""

import os, time, json, socket, struct
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from collections import namedtuple


class ReadError(Exception):
    """Raised when a /proc or /sys file cannot be read."""


def safe_read(path: str, default: str = "") -> str:
    """Read a file, return default on any error."""
    try:
        return Path(path).read_text().strip()
    except (FileNotFoundError, PermissionError, OSError):
        return default


def parse_keyval(text: str, sep: str = ":") -> Dict[str, str]:
    """Parse key: value format (like /proc/meminfo)."""
    result = {}
    for line in text.splitlines():
        if sep not in line:
            continue
        key, val = line.split(sep, 1)
        result[key.strip()] = val.strip()
    return result


def parse_cpuinfo() -> List[Dict[str, str]]:
    """Parse /proc/cpuinfo into a list of processor dicts."""
    text = safe_read("/proc/cpuinfo")
    processors = []
    current = {}
    for line in text.splitlines():
        if not line.strip():
            if current:
                processors.append(current)
                current = {}
            continue
        if ":" in line:
            key, val = line.split(":", 1)
            current[key.strip()] = val.strip()
    if current:
        processors.append(current)
    return processors


def parse_loadavg() -> Dict[str, float]:
    """Parse /proc/loadavg."""
    text = safe_read("/proc/loadavg", "0.00 0.00 0.00 0/0 0")
    parts = text.split()
    load = {
        "load_1m": float(parts[0]) if len(parts) > 0 else 0.0,
        "load_5m": float(parts[1]) if len(parts) > 1 else 0.0,
        "load_15m": float(parts[2]) if len(parts) > 2 else 0.0,
    }
    if "/" in parts[3] if len(parts) > 3 else "":
        run, total = parts[3].split("/")
        load["procs_running"] = int(run)
        load["procs_total"] = int(total)
    return load


def parse_meminfo() -> Dict[str, int]:
    """Parse /proc/meminfo, return all values in kB."""
    text = safe_read("/proc/meminfo")
    result = {}
    for line in text.splitlines():
        if ":" in line:
            key, val = line.split(":", 1)
            num = val.strip().split()[0]
            try:
                result[key.strip()] = int(num)
            except ValueError:
                result[key.strip()] = 0
    return result


def get_mem_pct() -> float:
    """Get memory usage percentage from MemTotal / MemAvailable."""
    mem = parse_meminfo()
    total = mem.get("MemTotal", 1)
    avail = mem.get("MemAvailable", 0)
    return (1 - avail / total) * 100


def get_swap_pct() -> float:
    """Get swap usage percentage."""
    mem = parse_meminfo()
    total = mem.get("SwapTotal", 0)
    free = mem.get("SwapFree", 0)
    if total == 0:
        return 0.0
    return (1 - free / total) * 100


def parse_uptime() -> Dict[str, float]:
    """Parse /proc/uptime: seconds since boot, idle seconds."""
    text = safe_read("/proc/uptime", "0 0")
    parts = text.split()
    return {
        "uptime_sec": float(parts[0]) if len(parts) > 0 else 0.0,
        "idle_sec": float(parts[1]) if len(parts) > 1 else 0.0,
    }


def parse_net_dev(interface: str = None) -> Dict[str, Dict]:
    """Parse /proc/net/dev for one or all interfaces.
    
    Returns:
        {iface_name: {rx_bytes: int, tx_bytes: int, rx_errors: int, tx_errors: int, ...}}
    """
    text = safe_read("/proc/net/dev")
    result = {}
    for line in text.splitlines()[2:]:  # skip headers
        parts = line.replace(":", " ").split()
        if len(parts) < 17:
            continue
        iface = parts[0]
        if interface and iface != interface:
            continue
        result[iface] = {
            "rx_bytes": int(parts[1]),
            "rx_packets": int(parts[2]),
            "rx_errors": int(parts[3]),
            "rx_dropped": int(parts[4]),
            "tx_bytes": int(parts[9]),
            "tx_packets": int(parts[10]),
            "tx_errors": int(parts[11]),
            "tx_dropped": int(parts[12]),
        }
    return result


def parse_net_sys(interface: str = None) -> Dict[str, Dict]:
    """Read network stats from /sys/class/net (cleaner per-interface).
    
    Prefer this over /proc/net/dev when you only need a specific interface.
    """
    base = Path("/sys/class/net")
    if not base.exists():
        return {}
    
    result = {}
    for iface_path in base.iterdir():
        iface = iface_path.name
        if interface and iface != interface:
            continue
        stats = iface_path / "statistics"
        if not stats.exists():
            continue
        result[iface] = {
            "rx_bytes": int(safe_read(str(stats / "rx_bytes"), "0")),
            "tx_bytes": int(safe_read(str(stats / "tx_bytes"), "0")),
            "rx_errors": int(safe_read(str(stats / "rx_errors"), "0")),
            "tx_errors": int(safe_read(str(stats / "tx_errors"), "0")),
            "rx_dropped": int(safe_read(str(stats / "rx_dropped"), "0")),
            "tx_dropped": int(safe_read(str(stats / "tx_dropped"), "0")),
        }
    return result


def parse_diskstats() -> Dict[str, Dict]:
    """Parse /proc/diskstats for physical devices.
    
    Returns:
        {device_name: {reads: int, writes: int, ...}}
    """
    text = safe_read("/proc/diskstats")
    result = {}
    for line in text.splitlines():
        parts = line.split()
        if len(parts) < 14:
            continue
        name = parts[2]
        # Only physical devices (sdX, nvmeX, vdX, xvdX), not partitions
        if not any(name.startswith(p) for p in ("sd", "nvme", "vd", "xvd")):
            continue
        if name[-1].isdigit() and any(name[:-1].startswith(p) for p in ("sd", "vd", "xvd")):
            continue  # skip partitions like sda1
        if "nvme" in name and name.count("n") > 1 and name[-1].isdigit():
            continue  # skip nvme partitions nvme0n1p1
        result[name] = {
            "reads_completed": int(parts[3]),
            "reads_merged": int(parts[4]),
            "sectors_read": int(parts[5]),
            "time_reading_ms": int(parts[6]),
            "writes_completed": int(parts[7]),
            "writes_merged": int(parts[8]),
            "sectors_written": int(parts[9]),
            "time_writing_ms": int(parts[10]),
            "io_in_progress": int(parts[11]),
            "time_in_io_ms": int(parts[12]),
            "weighted_io_time_ms": int(parts[13]),
        }
    return result


def get_cpu_count() -> int:
    """Number of online CPUs."""
    try:
        return len(os.sched_getaffinity(0))
    except AttributeError:
        # Fallback for older Python
        return len([p for p in Path("/sys/devices/system/cpu").glob("cpu[0-9]*") 
                    if (p / "online").read_text().strip() == "1" if (p / "online").exists()
                    else True])


def read_cgroup_memory(unit: str = None) -> Dict[str, int]:
    """Read cgroup v2 memory stats.
    
    Args:
        unit: systemd unit name like "nginx.service"
              If None, reads system-wide.
    """
    if unit:
        path = f"/sys/fs/cgroup/system.slice/{unit}/memory.current"
    else:
        path = "/sys/fs/cgroup/memory.current"
    
    current = int(safe_read(path, "0"))
    stat_text = safe_read(path.replace("current", "stat"))
    
    result = {"current": current}
    for line in stat_text.splitlines():
        if " " in line:
            key, val = line.split()
            result[key] = int(val)
    return result
```

---

## Delta Calculation Engine

Many metrics are cumulative counters — you need two samples to get rates.

```python
#!/usr/bin/env python3
"""delta.py — compute rates between metric snapshots"""

import time, json
from typing import Dict, Callable
from collections import defaultdict
from procutils import (
    parse_diskstats, parse_net_sys, parse_loadavg, parse_meminfo
)


class DeltaEngine:
    """Stores a baseline snapshot and computes deltas on the next call.
    
    Usage:
        engine = DeltaEngine()
        # First call — stores baseline
        engine.snapshot()
        time.sleep(1)
        # Second call — returns rates
        rates = engine.snapshot()
    """
    
    def __init__(self):
        self._baseline = {}
        self._baseline_time = None
    
    def snapshot(self) -> Dict:
        """Take a snapshot and return (rates if baseline exists, else empty)."""
        now = time.time()
        data = self._collect()
        rates = {}
        
        if self._baseline and self._baseline_time:
            elapsed = now - self._baseline_time
            if elapsed > 0:
                rates = self._compute_rates(
                    self._baseline, data, elapsed
                )
        
        self._baseline = data
        self._baseline_time = now
        return rates
    
    def _collect(self) -> Dict:
        """Collect all cumulative counters."""
        return {
            "disk": parse_diskstats(),
            "net": parse_net_sys(),
            "timestamp": time.time(),
        }
    
    def _compute_rates(self, prev: Dict, curr: Dict, elapsed: float) -> Dict:
        """Compute per-second rates from cumulative counters."""
        rates = {}
        
        # Disk rates
        disk_rates = {}
        for dev, curr_d in curr.get("disk", {}).items():
            prev_d = prev.get("disk", {}).get(dev, {})
            disk_rates[dev] = {
                "reads_per_sec": (curr_d.get("reads_completed", 0) - prev_d.get("reads_completed", 0)) / elapsed,
                "writes_per_sec": (curr_d.get("writes_completed", 0) - prev_d.get("writes_completed", 0)) / elapsed,
                "read_kb_per_sec": ((curr_d.get("sectors_read", 0) - prev_d.get("sectors_read", 0)) * 512 / 1024) / elapsed,
                "write_kb_per_sec": ((curr_d.get("sectors_written", 0) - prev_d.get("sectors_written", 0)) * 512 / 1024) / elapsed,
                "avg_io_ms": (
                    (curr_d.get("time_in_io_ms", 0) - prev_d.get("time_in_io_ms", 0)) / 
                    max(curr_d.get("reads_completed", 0) - prev_d.get("reads_completed", 0) +
                        curr_d.get("writes_completed", 0) - prev_d.get("writes_completed", 0), 1)
                ),
            }
        if disk_rates:
            rates["disk"] = disk_rates
        
        # Network rates
        net_rates = {}
        for iface, curr_n in curr.get("net", {}).items():
            prev_n = prev.get("net", {}).get(iface, {})
            net_rates[iface] = {
                "rx_bytes_per_sec": (curr_n.get("rx_bytes", 0) - prev_n.get("rx_bytes", 0)) / elapsed,
                "tx_bytes_per_sec": (curr_n.get("tx_bytes", 0) - prev_n.get("tx_bytes", 0)) / elapsed,
                "rx_packets_per_sec": (curr_n.get("rx_packets", 0) - prev_n.get("rx_packets", 0)) / elapsed,
                "tx_packets_per_sec": (curr_n.get("tx_packets", 0) - prev_n.get("tx_packets", 0)) / elapsed,
            }
        if net_rates:
            rates["net"] = net_rates
        
        return rates


class CollectOnce:
    """Collect all system metrics in a single pass — for periodic reporting.
    
    Returns a complete JSON-serializable dict with both instantaneous and
    delta-derived values.
    """
    
    def __init__(self):
        self._delta = DeltaEngine()
    
    def collect(self) -> Dict:
        """Collect full system snapshot with rates."""
        from procutils import (
            parse_loadavg, parse_meminfo, parse_uptime,
            get_cpu_count, read_cgroup_memory
        )
        
        host = socket.gethostname()
        ts = int(time.time())
        
        # Instant values
        load = parse_loadavg()
        mem = parse_meminfo()
        upt = parse_uptime()
        
        # CPU stats from /proc/stat
        cpu_data = {}
        for line in safe_read("/proc/stat").splitlines():
            if line.startswith("cpu"):
                parts = line.split()
                name = parts[0]
                vals = [int(v) for v in parts[1:11]] if len(parts) > 1 else [0]*10
                cpu_data[name] = {
                    "user": vals[0] if len(vals) > 0 else 0,
                    "nice": vals[1] if len(vals) > 1 else 0,
                    "system": vals[2] if len(vals) > 2 else 0,
                    "idle": vals[3] if len(vals) > 3 else 0,
                    "iowait": vals[4] if len(vals) > 4 else 0,
                    "irq": vals[5] if len(vals) > 5 else 0,
                    "softirq": vals[6] if len(vals) > 6 else 0,
                    "steal": vals[7] if len(vals) > 7 else 0,
                }
        
        # Delta-based rates
        rates = self._delta.snapshot()
        
        # cgroup memory for key services
        services = {}
        for svc_dir in Path("/sys/fs/cgroup/system.slice").glob("*.service"):
            name = svc_dir.name
            mem_file = svc_dir / "memory.current"
            if mem_file.exists():
                try:
                    services[name] = int(mem_file.read_text().strip()) // 1024  # kB
                except (ValueError, OSError):
                    pass
        
        return {
            "host": host,
            "timestamp": ts,
            "load": load,
            "memory": {
                "total_kb": mem.get("MemTotal", 0),
                "free_kb": mem.get("MemFree", 0),
                "avail_kb": mem.get("MemAvailable", 0),
                "pct": (1 - mem.get("MemAvailable", 0) / max(mem.get("MemTotal", 1), 1)) * 100,
                "swap_total_kb": mem.get("SwapTotal", 0),
                "swap_free_kb": mem.get("SwapFree", 0),
            },
            "cpu": {
                "count": get_cpu_count(),
                "stats": cpu_data,
            },
            "uptime": upt,
            "services_memory_kb": services,
            "rates": rates,
        }
```

---

## HTTP Push Client

### Client Using Only stdlib

```python
#!/usr/bin/env python3
"""push.py — collect metrics and POST to central server"""

import json, os, time, socket, sys, urllib.request, urllib.error

# Configuration — could come from env vars or a config file
CENTRAL_URL = os.environ.get("MONITOR_URL", "http://monitor.example.com:8080/api/metrics")
API_KEY = os.environ.get("MONITOR_API_KEY", "changeme")
HOST = socket.gethostname()
INTERVAL = int(os.environ.get("MONITOR_INTERVAL", "60"))  # seconds

# Import from sibling file
sys.path.insert(0, os.path.dirname(__file__))
from collector import CollectOnce
from procutils import safe_read


def send(data: dict) -> bool:
    """POST JSON metrics to central server."""
    payload = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        CENTRAL_URL,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "X-API-Key": API_KEY,
            "X-Host": HOST,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status != 201 and resp.status != 200:
                print(f"WARN: server returned {resp.status}")
                return False
            return True
    except (urllib.error.URLError, urllib.error.HTTPError) as e:
        print(f"ERROR: push failed: {e}")
        return False


def push_loop():
    """Main loop — collect and push every INTERVAL seconds."""
    collector = CollectOnce()
    failures = 0
    max_failures = 10
    
    while True:
        try:
            data = collector.collect()
            ok = send(data)
            if ok:
                failures = 0
                print(f"[{data['timestamp']}] Pushed {len(json.dumps(data))} bytes")
            else:
                failures += 1
                print(f"[{data['timestamp']}] Push FAILED ({failures}/{max_failures})")
        except Exception as e:
            failures += 1
            print(f"ERROR: {e}")
        
        if failures >= max_failures:
            # Write to local fallback
            fallback_file = f"/var/log/agentless/fallback-{HOST}-{int(time.time())}.json"
            with open(fallback_file, "w") as f:
                json.dump(data, f)
            print(f"Wrote fallback to {fallback_file}")
            failures = 0
        
        time.sleep(INTERVAL)


if __name__ == "__main__":
    # One-shot mode if args present
    if "--once" in sys.argv:
        c = CollectOnce()
        data = c.collect()
        print(json.dumps(data, indent=2))
        if "--push" in sys.argv:
            send(data)
    else:
        push_loop()
```

### Using `requests` (If Available)

```python
try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

def send_requests(data: dict) -> bool:
    if not HAS_REQUESTS:
        return send(data)  # fallback to stdlib
    
    try:
        resp = requests.post(
            CENTRAL_URL,
            json=data,
            headers={"X-API-Key": API_KEY},
            timeout=15,
        )
        return resp.ok
    except requests.RequestException as e:
        print(f"ERROR: {e}")
        return False
```

---

## Central Ingestion Server

### Minimal Flask Server

```python
#!/usr/bin/env python3
"""server.py — central metric ingestion server"""

import json, os, time, threading
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler

DATA_DIR = os.environ.get("MONITOR_DATA_DIR", "/var/lib/monitor/data")
API_KEY = os.environ.get("MONITOR_API_KEY", "changeme")
LISTEN_HOST = os.environ.get("MONITOR_LISTEN", "0.0.0.0")
LISTEN_PORT = int(os.environ.get("MONITOR_PORT", "8080"))

os.makedirs(DATA_DIR, exist_ok=True)


class MetricHandler(BaseHTTPRequestHandler):
    """HTTP handler for metric ingestion."""
    
    def do_POST(self):
        if self.path != "/api/metrics":
            self.send_response(404)
            self.end_headers()
            return
        
        # API key check
        key = self.headers.get("X-API-Key", "")
        if key != API_KEY:
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b'{"error":"unauthorized"}')
            return
        
        # Read body
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            self.send_response(400)
            self.end_headers()
            return
        
        body = self.rfile.read(length)
        
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            return
        
        host = data.get("host", "unknown")
        date = time.strftime("%Y-%m-%d")
        log_path = Path(DATA_DIR) / f"{host}-{date}.jsonl"
        
        # Append as JSON line
        with open(log_path, "a") as f:
            f.write(json.dumps(data) + "\n")
        
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"status": "ok"}).encode())
    
    def do_GET(self):
        """Health check."""
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode())
            return
        
        # List hosts
        if self.path == "/api/hosts":
            hosts = set()
            for f in Path(DATA_DIR).glob("*.jsonl"):
                hosts.add(f.stem.split("-")[0])
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(list(hosts)).encode())
            return
        
        self.send_response(404)
        self.end_headers()
    
    def log_message(self, format, *args):
        """Suppress default HTTP server logging."""
        pass


def run_server():
    server = HTTPServer((LISTEN_HOST, LISTEN_PORT), MetricHandler)
    print(f"Monitor server listening on {LISTEN_HOST}:{LISTEN_PORT}")
    print(f"Data directory: {DATA_DIR}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.server_close()


if __name__ == "__main__":
    run_server()
```

### With Prometheus Exposition Format

```python
#!/usr/bin/env python3
"""prometheus_exporter.py — expose collected metrics for Prometheus scraping"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from collector import CollectOnce

collector = CollectOnce()


class PrometheusHandler(BaseHTTPRequestHandler):
    """Exposes metrics in Prometheus text format."""

    METRIC_TEMPLATE = "# HELP {name} {help}\n# TYPE {name} gauge\n{name}{{host=\"{host}\"}} {value}\n"

    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not found\n")
            return
        
        data = collector.collect()
        host = data["host"]
        lines = []
        
        # Load
        lines.append(self.METRIC_TEMPLATE.format(
            name="system_load_1m", help="1-minute load average",
            host=host, value=data["load"]["load_1m"]))
        lines.append(self.METRIC_TEMPLATE.format(
            name="system_load_5m", help="5-minute load average",
            host=host, value=data["load"]["load_5m"]))
        lines.append(self.METRIC_TEMPLATE.format(
            name="system_load_15m", help="15-minute load average",
            host=host, value=data["load"]["load_15m"]))
        
        # Memory
        lines.append(self.METRIC_TEMPLATE.format(
            name="memory_pct", help="Memory usage percentage",
            host=host, value=data["memory"]["pct"]))
        lines.append(self.METRIC_TEMPLATE.format(
            name="memory_avail_kb", help="Available memory in kB",
            host=host, value=data["memory"]["avail_kb"]))
        
        # Disk rates
        for dev, stats in data.get("rates", {}).get("disk", {}).items():
            lines.append(self.METRIC_TEMPLATE.format(
                name="disk_read_kb_per_sec",
                help="Disk read throughput kB/s",
                host=host, value=stats["read_kb_per_sec"]))
            break  # just first device
        
        body = "".join(lines)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body.encode())


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 9100), PrometheusHandler)
    print("Prometheus exporter on :9100/metrics")
    server.serve_forever()
```

---

## SQLite Storage & Queries

### Local Storage for Resilience

```python
#!/usr/bin/env python3
"""store.py — SQLite storage for collected metrics"""

import sqlite3, json, time, os
from pathlib import Path
from typing import Optional, List, Dict


SCHEMA = """
CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    host TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    tags TEXT DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_metrics_host_ts ON metrics(host, timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics(metric_name);
"""


class MetricsStore:
    """SQLite-backed metric store.
    
    Stores metrics in a normalized format (one row per metric per timestamp),
    making it easy to query historical trends.
    """
    
    def __init__(self, db_path: str = "/var/lib/monitor/metrics.db"):
        self.db_path = db_path
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self._conn = sqlite3.connect(db_path, check_same_thread=False)
        self._conn.executescript(SCHEMA)
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA synchronous=NORMAL")
    
    def store(self, host: str, timestamp: int, metrics: Dict[str, float],
              tags: Optional[Dict] = None):
        """Store a batch of metrics.
        
        Args:
            host: Hostname
            timestamp: Unix epoch seconds
            metrics: {metric_name: value}
            tags: Optional dict of tags (e.g., {"region": "us-east"})
        """
        tags_json = json.dumps(tags or {})
        rows = [(host, timestamp, name, value, tags_json)
                for name, value in metrics.items()]
        self._conn.executemany(
            "INSERT INTO metrics (host, timestamp, metric_name, metric_value, tags) "
            "VALUES (?, ?, ?, ?, ?)",
            rows
        )
        self._conn.commit()
    
    def query(self, host: str, metric_name: str,
              since: int = 0, until: int = 0,
              limit: int = 1000) -> List[Dict]:
        """Query a metric over time.
        
        Returns:
            List of {timestamp, value} dicts.
        """
        query = (
            "SELECT timestamp, metric_value FROM metrics "
            "WHERE host = ? AND metric_name = ? AND timestamp >= ?"
        )
        params = [host, metric_name, since]
        if until > 0:
            query += " AND timestamp <= ?"
            params.append(until)
        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)
        
        cur = self._conn.execute(query, params)
        return [{"timestamp": row[0], "value": row[1]} for row in cur.fetchall()]
    
    def latest(self, host: str, metric_name: str) -> Optional[float]:
        """Get most recent value for a metric."""
        cur = self._conn.execute(
            "SELECT metric_value FROM metrics "
            "WHERE host = ? AND metric_name = ? "
            "ORDER BY timestamp DESC LIMIT 1",
            (host, metric_name)
        )
        row = cur.fetchone()
        return row[0] if row else None
    
    def list_hosts(self) -> List[str]:
        """List all hosts that have stored metrics."""
        cur = self._conn.execute(
            "SELECT DISTINCT host FROM metrics ORDER BY host"
        )
        return [row[0] for row in cur.fetchall()]
    
    def cleanup(self, older_than_days: int = 90):
        """Delete metrics older than N days."""
        cutoff = int(time.time()) - older_than_days * 86400
        self._conn.execute(
            "DELETE FROM metrics WHERE timestamp < ?", (cutoff,)
        )
        self._conn.execute("VACUUM")
        self._conn.commit()
    
    def close(self):
        self._conn.close()


# Query example
def generate_report(store: MetricsStore, host: str, hours: int = 24):
    """Generate a simple report for a host."""
    since = int(time.time()) - hours * 3600
    
    print(f"=== Report for {host} (last {hours}h) ===")
    
    for metric in ["cpu_pct", "memory_pct", "disk_pct"]:
        points = store.query(host, metric, since=since)
        if not points:
            continue
        values = [p["value"] for p in points]
        print(f"\n{metric}:")
        print(f"  Current: {values[0]:.1f}")
        print(f"  Average: {sum(values)/len(values):.1f}")
        print(f"  Max: {max(values):.1f}")
        print(f"  Min: {min(values):.1f}")
        print(f"  Samples: {len(values)}")
```

---

## Asynchronous Architecture

### Async Collector (Python 3.7+)

```python
#!/usr/bin/env python3
"""async_collector.py — async push loop with multiple targets"""

import asyncio, json, time, os, signal
import aiohttp  # pip install aiohttp (or use stdlib http.client with threads)

from collector import CollectOnce

TARGETS = [
    "https://monitor1.example.com/api/metrics",
    "https://monitor2.example.com/api/metrics",
]
API_KEY = os.environ["MONITOR_API_KEY"]
INTERVAL = 60
collector = CollectOnce()


async def push_one(session: aiohttp.ClientSession, url: str, data: dict) -> bool:
    try:
        async with session.post(
            url,
            json=data,
            headers={"X-API-Key": API_KEY},
            timeout=aiohttp.ClientTimeout(total=10),
        ) as resp:
            return resp.status in (200, 201)
    except Exception as e:
        print(f"Push to {url} failed: {e}")
        return False


async def push_loop():
    async with aiohttp.ClientSession() as session:
        while True:
            data = collector.collect()
            tasks = [push_one(session, url, data) for url in TARGETS]
            results = await asyncio.gather(*tasks)
            success = sum(1 for r in results if r)
            print(f"[{data['timestamp']}] Pushed to {success}/{len(TARGETS)} targets")
            await asyncio.sleep(INTERVAL)


async def serve_prometheus():
    """Serve Prometheus metrics via aiohttp."""
    from aiohttp import web
    
    async def metrics(request):
        data = collector.collect()
        host = data["host"]
        text = "\n".join([
            f'system_load_1m{{host="{host}"}} {data["load"]["load_1m"]}',
            f'memory_pct{{host="{host}"}} {data["memory"]["pct"]}',
            f'disk_pct{{host="{host}"}} 0',
        ])
        return web.Response(text=text, content_type="text/plain")
    
    app = web.Application()
    app.router.add_get("/metrics", metrics)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "0.0.0.0", 9100)
    await site.start()
    print("Prometheus endpoint on :9100/metrics")


async def main():
    await asyncio.gather(
        push_loop(),
        serve_prometheus(),
    )


if __name__ == "__main__":
    asyncio.run(main())
```

### Multi-Host SSH Pull (Async)

```python
#!/usr/bin/env python3
"""async_ssh_pull.py — parallel SSH to many hosts using asyncio"""

import asyncio, json, time

# Requires: pip install asyncssh
import asyncssh

HOSTS = [
    {"host": "web01", "user": "monitor", "port": 22},
    {"host": "web02", "user": "monitor", "port": 22},
    {"host": "db01", "user": "monitor", "port": 22},
]

REMOTE_CMD = """
cat /proc/loadavg | awk '{print $1}'
awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.1f\\n", (1-a/t)*100}' /proc/meminfo
df / | awk 'NR==2{print $5}' | tr -d '%'
ss -t4 state established --no-header | wc -l
"""


async def pull_host(config: dict) -> dict:
    """SSH into one host and collect metrics."""
    try:
        async with asyncssh.connect(
            config["host"],
            username=config["user"],
            known_hosts=None,  # In production, use known_hosts
            connect_timeout=10,
        ) as conn:
            result = await conn.run(REMOTE_CMD, timeout=15)
            if result.exit_status != 0:
                return {"host": config["host"], "error": result.stderr.strip()}
            
            lines = result.stdout.strip().splitlines()
            return {
                "host": config["host"],
                "timestamp": int(time.time()),
                "load_1m": float(lines[0]) if len(lines) > 0 else 0,
                "mem_pct": float(lines[1]) if len(lines) > 1 else 0,
                "disk_pct": int(lines[2]) if len(lines) > 2 else 0,
                "tcp_estab": int(lines[3]) if len(lines) > 3 else 0,
            }
    except Exception as e:
        return {"host": config["host"], "error": str(e)}


async def pull_all():
    tasks = [pull_host(h) for h in HOSTS]
    results = await asyncio.gather(*tasks)
    for r in results:
        if "error" in r:
            print(f"FAIL: {r['host']}: {r['error']}")
        else:
            print(f"OK:   {r['host']}: load={r['load_1m']} mem={r['mem_pct']}% disk={r['disk_pct']}%")


if __name__ == "__main__":
    asyncio.run(pull_all())
```

---

## Integration with Existing Tools

### Push to InfluxDB

```python
#!/usr/bin/env python3
"""influx_push.py — push metrics to InfluxDB (v1 or v2)"""

import json, os, time, urllib.request, urllib.parse

INFLUX_URL = os.environ.get("INFLUX_URL", "http://localhost:8086")
INFLUX_DB = os.environ.get("INFLUX_DB", "metrics")
INFLUX_USER = os.environ.get("INFLUX_USER", "")
INFLUX_PASS = os.environ.get("INFLUX_PASS", "")

from collector import CollectOnce


def to_line_protocol(data: dict) -> str:
    """Convert collected dict to InfluxDB line protocol format."""
    host = data["host"]
    ts = data["timestamp"]
    lines = []
    
    tags = f"host={host}"
    
    # Load
    lines.append(
        f'system_load,{tags} '
        f'load_1m={data["load"]["load_1m"]},'
        f'load_5m={data["load"]["load_5m"]},'
        f'load_15m={data["load"]["load_15m"]} '
        f'{ts}000000000'
    )
    
    # Memory
    lines.append(
        f'system_memory,{tags} '
        f'pct={data["memory"]["pct"]},'
        f'avail_kb={data["memory"]["avail_kb"]}i '
        f'{ts}000000000'
    )
    
    return "\n".join(lines)


def push(data: dict) -> bool:
    line_data = to_line_protocol(data)
    url = f"{INFLUX_URL}/write?db={INFLUX_DB}"
    
    if INFLUX_USER:
        url += f"&u={urllib.parse.quote(INFLUX_USER)}&p={urllib.parse.quote(INFLUX_PASS)}"
    
    req = urllib.request.Request(url, data=line_data.encode(), method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10):
            return True
    except Exception as e:
        print(f"InfluxDB push failed: {e}")
        return False


if __name__ == "__main__":
    c = CollectOnce()
    data = c.collect()
    push(data)
```

### Push to Prometheus Pushgateway

```python
PUSHGATEWAY_URL = os.environ.get("PUSHGATEWAY_URL", "http://localhost:9091")

def push_to_gateway(data: dict):
    """Push metrics to Prometheus Pushgateway."""
    host = data["host"]
    job = "system_health"
    
    text = "\n".join([
        f'# HELP system_load_1m 1-minute load average',
        f'# TYPE system_load_1m gauge',
        f'system_load_1m{{host="{host}"}} {data["load"]["load_1m"]}',
        f'',
        f'# HELP memory_pct Memory usage percentage',
        f'# TYPE memory_pct gauge',
        f'memory_pct{{host="{host}"}} {data["memory"]["pct"]}',
    ])
    
    url = f"{PUSHGATEWAY_URL}/metrics/job/{job}/instance/{host}"
    req = urllib.request.Request(url, data=text.encode(), method="PUT")
    try:
        with urllib.request.urlopen(req, timeout=10):
            pass
    except Exception as e:
        print(f"Pushgateway push failed: {e}")
```

---

## Packaging & Deployment

### Single-File Deployment

All Python scripts above can be combined into a single deployable script:

```python
#!/usr/bin/env python3
"""agentless-monitor.py — single-file monitor (collect + push)"""

import os, json, time, socket, sys, urllib.request, urllib.error
from pathlib import Path

# ===== Configuration =====
MODE = os.environ.get("MONITOR_MODE", "push")  # push, server, once
CENTRAL_URL = os.environ.get("MONITOR_URL", "http://localhost:8080/api/metrics")
API_KEY = os.environ.get("MONITOR_API_KEY", "changeme")
LISTEN_PORT = int(os.environ.get("MONITOR_PORT", "8080"))
INTERVAL = int(os.environ.get("MONITOR_INTERVAL", "60"))

# ===== /proc readers (concatented from procutils.py) =====
# [Include all procutils.py functions here]

# ===== Collector =====
# [Include collector, delta engine here]

# ===== Server =====
# [Include HTTP server here]

if __name__ == "__main__":
    if MODE == "push":
        # push loop
        pass
    elif MODE == "server":
        # run HTTP server
        pass
    elif MODE == "once":
        # single collect
        pass
```

### Systemd Service for Python Collector

```bash
# /etc/systemd/system/agentless-monitor.service
[Unit]
Description=Agentless system monitor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/agentless-monitor.py
Environment=MONITOR_URL=http://central.example.com:8080/api/metrics
Environment=MONITOR_API_KEY=changeme
Environment=MONITOR_INTERVAL=60
Restart=on-failure
RestartSec=10
User=root
Nice=10
IOSchedulingClass=idle

[Install]
WantedBy=multi-user.target
```

### Cron for One-Shot Mode

```bash
# /etc/cron.d/agentless
*/5 * * * * root /usr/local/bin/agentless-monitor.py --mode once --push
```
