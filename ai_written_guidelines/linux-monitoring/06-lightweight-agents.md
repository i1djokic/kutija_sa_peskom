# Lightweight Agents — When Agentless Reaches Its Limits

## Table of Contents
1. [When to Add an Agent](#when-to-add-an-agent)
2. [Telegraf — The Universal Collector](#telegraf--the-universal-collector)
3. [Prometheus Node Exporter](#prometheus-node-exporter)
4. [collectd — The Lightweight Veteran](#collectd--the-lightweight-veteran)
5. [Netdata — Real-Time Dashboards](#netdata--real-time-dashboards)
6. [syslog-ng — Advanced Log Forwarding](#syslog-ng--advanced-log-forwarding)
7. [Comparison Matrix](#comparison-matrix)
8. [Migration Path: Agentless → Agent-Based](#migration-path-agentless--agent-based)

---

## When to Add an Agent

Agentless monitoring (SSH pull, `/proc` parsing, `sar`) works well for small-scale. When you hit these thresholds, consider a dedicated agent:

| Signal | Threshold | Why |
|--------|-----------|-----|
| Host count | > 50 | SSH pull latency becomes significant |
| Collection frequency | < 10s | SSH handshake overhead dominates |
| Metrics per host | > 100 | Cumulative counter deltas need structured handling |
| Auto-discovery | Dynamic env | Containers, auto-scaling groups need registration |
| Retry/backfill | Network unreliable | Agents buffer locally, replay on reconnect |
| Real-time alerting | Sub-minute | Poll-based misses short spikes |

**"Agent" here means a single-binary, low-footprint daemon that reads `/proc`/`/sys` and ships data. NOT a heavy Java/Python agent with complex dependencies.**

---

## Telegraf — The Universal Collector

### Overview

- **Language:** Go
- **Disk:** ~50 MB
- **CPU:** 0.5-2% of one core
- **Memory:** 15-30 MB
- **Configuration:** TOML
- **Outputs:** InfluxDB, Prometheus, Kafka, Graphite, Datadog, 30+ others
- **Inputs:** 300+ plugins including CPU, disk, net, mem, systemd, Docker, cgroups

### Why Telegraf for "Agentless-Friendly" Path

Telegraf reads the **same** `/proc`/`/sys` interfaces your bash/Python scripts do — it just does it faster and more reliably:

```toml
# CPU — reads /proc/stat
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  fielddrop = ["time_*"]

# Memory — reads /proc/meminfo
[[inputs.mem]]
  # No config needed

# Disk — reads /proc/diskstats
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "overlay"]
  fieldpass = ["used_percent", "free"]

# Network — reads /sys/class/net/*/statistics/
[[inputs.net]]
  interfaces = ["eth*"]

# systemd — reads cgroup metrics (like systemctl show)
[[inputs.systemd_units]]
  pattern = "*.service"
  # Reports ActiveState, SubState, LoadState for each unit
```

### Installation

```bash
# Debian/Ubuntu
wget -qO- https://repos.influxdata.com/influxdb.key | apt-key add -
echo "deb https://repos.influxdata.com/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/influxdb.list
apt update && apt install telegraf

# RHEL/CentOS/Fedora
cat <<EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
yum install telegraf

# Manual (any distro)
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.29.0_linux_amd64.tar.gz
tar xzf telegraf-*.tar.gz
./telegraf-*/usr/bin/telegraf --config telegraf.conf
```

### Complete Config for Agentless-Replacement

```toml
# /etc/telegraf/telegraf.conf

[agent]
  interval = "60s"
  flush_interval = "60s"
  omit_hostname = false
  hostname = ""  # defaults to OS hostname

# ===== Inputs (all agentless, all /proc + /sys) =====

[[inputs.cpu]]
  percpu = false
  totalcpu = true
  collect_cpu_time = false

[[inputs.mem]]

[[inputs.swap]]

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "overlay", "squashfs"]

[[inputs.diskio]]

[[inputs.net]]

[[inputs.netstat]]

[[inputs.system]]

[[inputs.kernel]]

[[inputs.processes]]

[[inputs.systemd_units]]
  pattern = "*.service"

[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  container_names = []
  gather_services = false

[[inputs.procstat]]
  pattern = "(nginx|postgres|sshd)"

[[inputs.influxdb]]
  urls = ["http://localhost:8086/debug/vars"]

[[inputs.socket_listener]]
  service_address = "udp://:8094"
  data_format = "influx"

# ===== Outputs =====

[[outputs.influxdb_v2]]
  urls = ["http://localhost:8086"]
  token = "${INFLUX_TOKEN}"
  organization = "myorg"
  bucket = "metrics"

# Alternative: Prometheus client
# [[outputs.prometheus_client]]
#   listen = ":9273"

# Alternative: JSON file output
# [[outputs.file]]
#   files = ["/var/log/telegraf/metrics.json"]
#   data_format = "json"
```

### Integration with Existing Scripts

Telegraf can also run arbitrary shell commands as inputs:

```toml
[[inputs.exec]]
  commands = ["/usr/local/bin/custom-metrics.sh"]
  timeout = "5s"
  data_format = "influx"  # or "json" or "graphite"
  name_override = "custom_metrics"
```

Where `custom-metrics.sh` outputs:
```
custom_metric,tag1=value1 field1=123,field2=456 1717000000
```

### Telegraf as Agentless Gateway

Telegraf can also **receive** metrics from your existing bash/Python scripts and forward them to multiple backends:

```
Bash collectors  ──┐
Python collectors ──┼──> Telegraf (socket listener) ──> InfluxDB + Kafka + file
Syslog            ──┘
```

```toml
[[inputs.socket_listener]]
  service_address = "tcp://:8094"
  data_format = "influx"

[[inputs.http_listener_v2]]
  paths = ["/telegraf"]
  methods = ["POST"]
  data_format = "json"
```

Now your `push-metrics.sh` would curl:
```bash
curl -X POST -d 'system_load host=web01 load_1m=0.5 1717000000' http://localhost:8094
```

---

## Prometheus Node Exporter

### Overview

- **Language:** Go
- **Disk:** ~30 MB
- **CPU:** 0.5-1% of one core
- **Memory:** 10-20 MB
- **Configuration:** Command-line flags only (no config file)
- **Output:** Prometheus text format at `/metrics`
- **Pull model:** Prometheus server scrapes each exporter

### Why Node Exporter

It's the gold standard for Linux host metrics in the Prometheus ecosystem. It exposes **everything** from `/proc` and `/sys` in Prometheus format.

```bash
# Run
./node_exporter \
  --collector.textfile.directory=/var/lib/node_exporter/textfile \
  --collector.systemd \
  --collector.diskstats \
  --collector.netstat \
  --collector.meminfo \
  --collector.cpu \
  --collector.loadavg \
  --web.listen-address=:9100
```

### Metrics Exposed

```bash
curl -s http://localhost:9100/metrics | head -30
# HELP node_cpu_seconds_total Seconds the cpus spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 12345678.9
node_cpu_seconds_total{cpu="0",mode="system"} 234567.8
node_cpu_seconds_total{cpu="0",mode="user"} 1234567.8

# HELP node_memory_MemAvailable_bytes Memory information field.
# TYPE node_memory_MemAvailable_bytes gauge
node_memory_MemAvailable_bytes 8.24e+09

# HELP node_load1 1m load average.
# TYPE node_load1 gauge
node_load1 0.45

# HELP node_disk_reads_completed_total The total number of reads completed successfully.
# TYPE node_disk_reads_completed_total counter
node_disk_reads_completed_total{device="sda"} 1234567

# HELP node_network_receive_bytes_total Network device statistic receive.
# TYPE node_network_receive_bytes_total counter
node_network_receive_bytes_total{device="eth0"} 9.87e+11

# HELP node_systemd_unit_state systemd unit state
# TYPE node_systemd_unit_state gauge
node_systemd_unit_state{name="nginx.service",state="active"} 1
node_systemd_unit_state{name="nginx.service",state="inactive"} 0
node_systemd_unit_state{name="nginx.service",state="failed"} 0
```

### Textfile Collector (Custom Metrics)

Node Exporter supports a **textfile** collector: put any custom metrics in a file, and they'll be exposed alongside built-in metrics:

```bash
# Write custom metrics
cat > /var/lib/node_exporter/textfile/custom.prom <<'EOF'
# HELP custom_app_users Current number of app users
# TYPE custom_app_users gauge
custom_app_users{host="web01"} 42
EOF

# Node Exporter picks it up on every scrape
```

This means you can keep your existing Bash/Python scripts for custom metrics and expose them through Node Exporter:

```bash
#!/bin/bash
# /usr/local/bin/collect-custom.sh — run via cron, outputs to textfile

OUTPUT="/var/lib/node_exporter/textfile/custom.prom"
{
    echo "# HELP custom_nginx_connections Nginx active connections"
    echo "# TYPE custom_nginx_connections gauge"
    echo "custom_nginx_connections $(curl -s http://localhost/status | awk '/Active/ {print $3}')"
    
    echo "# HELP custom_postgres_backup_age Age of last backup in seconds"
    echo "# TYPE custom_postgres_backup_age gauge"
    echo "custom_postgres_backup_age $(stat -c %Y /backups/latest.sql 2>/dev/null | xargs -I{} echo $(( $(date +%s) - {} )))"
} > "$OUTPUT"
```

**Cron:** `* * * * * root /usr/local/bin/collect-custom.sh`

### systemd Service

```bash
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.textfile.directory=/var/lib/node_exporter/textfile \
    --collector.systemd \
    --collector.meminfo \
    --collector.cpu \
    --collector.diskstats \
    --collector.netstat \
    --collector.loadavg \
    --collector.thermal_zone \
    --web.listen-address=:9100
Restart=on-failure
RestartSec=5
Nice=10
IOSchedulingClass=idle

[Install]
WantedBy=multi-user.target
```

### Scraping with Prometheus

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
        - 'web01:9100'
        - 'web02:9100'
        - 'db01:9100'
    scrape_interval: 30s
    scrape_timeout: 10s
```

---

## collectd — The Lightweight Veteran

### Overview

- **Language:** C
- **Disk:** ~3 MB
- **CPU:** 0.1-0.5% of one core
- **Memory:** 3-8 MB
- **Configuration:** Config files (own syntax)
- **Outputs:** Graphite, RRD, network, JSON, write HTTP

### Why collectd

If you need absolute minimum footprint (embedded, Raspberry Pi, low-resource VMs), collectd is the lightest of all.

### Key Plugins

| Plugin | What it reads |
|--------|--------------|
| `cpu` | `/proc/stat` |
| `memory` | `/proc/meminfo` |
| `interface` | `/sys/class/net/*/statistics/` |
| `disk` | `/proc/diskstats` |
| `load` | `/proc/loadavg` |
| `processes` | `/proc` scanning |
| `cgroups` | `/sys/fs/cgroup/` |
| `exec` | Run external scripts (custom metrics) |
| `curl_json` | Scrape JSON APIs |
| `write_http` | POST to HTTP endpoint |
| `write_graphite` | Send to Graphite/Carbon |
| `write_prometheus` | Expose in Prometheus format |
| `network` | Send/receive collectd native protocol |

### Minimal Config

```
# /etc/collectd/collectd.conf

Hostname    "web01"
Interval    60
FQDNLookup  false

LoadPlugin cpu
LoadPlugin memory
LoadPlugin load
LoadPlugin disk
LoadPlugin interface
LoadPlugin processes
LoadPlugin write_http
LoadPlugin exec

<Plugin interface>
  Interface "eth0"
  Interface "eth1"
</Plugin>

<Plugin write_http>
  <URL "http://monitor.example.com:8080/collectd">
    Format "JSON"
    StoreRates true
  </URL>
</Plugin>

<Plugin exec>
  Exec "monitor" "/usr/local/bin/collectd-metrics.sh"
</Plugin>
```

### Upgrading from Bash to collectd

```bash
# Instead of: 
#   cat /proc/loadavg | awk ...
# collectd's `load` plugin does this in C — zero overhead
# Instead of:
#   #!/bin/bash custom metrics
# Use the exec plugin — but only for metrics that change rarely
```

---

## Netdata — Real-Time Dashboards

### Overview

- **Language:** C
- **Disk:** ~100 MB
- **CPU:** 1-3% of one core
- **Memory:** 30-80 MB
- **Configuration:** Stream editor or files
- **Output:** Built-in web UI (port 19999), Prometheus, Graphite, streaming

### Why Netdata

Netdata is the **anti-agentless** in terms of usability: it gives you instant, beautiful dashboards with no configuration. It still reads `/proc`/`/sys` under the hood.

```bash
# One-liner install
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Access dashboard
# http://<host>:19999
```

### Key Features

- **Per-second granularity** — samples `/proc/stat` every second
- **Zero config** — auto-detects everything
- **Anomaly detection** — built-in ML (if compiled with ml)
- **Custom dashboards** — compose your own charts
- **Streaming** — child nodes stream to a parent node (centralization)
- **Alerts** — built-in alarm engine (notifications via email, Slack, etc.)

### Agentless Connection

Netdata's **streaming** allows agentless collection from child nodes:

1. Install Netdata only on the **parent** (central) node
2. On children, install only `netdata` with streaming disabled:
```bash
# /etc/netdata/netdata.conf on child
[global]
    memory mode = none
[stream]
    enabled = yes
    destination = parent.example.com:19999
    api key = 11111111-2222-3333-4444-555555555555
```
3. Parent receives and stores data for all children

Now you have dashboards for all nodes without running a full agent on each.

---

## syslog-ng — Advanced Log Forwarding

### Overview

- **Language:** C
- **Disk:** ~5 MB
- **CPU:** 0.1-0.3% of one core
- **Memory:** 5-15 MB
- **Configuration:** syslog-ng.conf
- **Protocols:** syslog (RFC 3164/5424), JSON, Kafka, MQTT

### Why syslog-ng Over rsyslog

| Feature | rsyslog | syslog-ng |
|---------|---------|-----------|
| JSON parsing | Limited | Built-in (json-parser) |
| Kafka output | Module | Native |
| Rewrite rules | Limited | Powerful |
| Pattern DB (log classification) | No | Yes |
| Performance | High | Higher |

### Config for Centralization

```
# On each monitored host — /etc/syslog-ng/syslog-ng.conf
@version: 3.38

source s_sys {
    system();
    internal();
};

destination d_central {
    syslog("logserver.example.com" port(6514)
           transport("tls")
           tls(peer-verify("optional-untrusted")));
};

log {
    source(s_sys);
    destination(d_central);
};
```

### Parsing Structured Logs

syslog-ng can parse structured data without agents:

```
# Parse JSON logs from nginx
@version: 3.38

source s_json {
    file("/var/log/nginx/access.json" flags(no-parse) program-override("nginx"));
};

parser p_json {
    json-parser();
};

destination d_kafka {
    kafka(
        bootstrap-servers("kafka.example.com:9092")
        topic("nginx-logs")
    );
};

log {
    source(s_json);
    parser(p_json);
    destination(d_kafka);
};
```

---

## Comparison Matrix

| Trait | Agentless (SSH/Pull) | Bash (cron) | Python | Telegraf | Node Exporter | collectd | Netdata |
|-------|---------------------|-------------|--------|----------|---------------|----------|---------|
| **Install size** | 0 | 0 | Python | 50 MB | 30 MB | 3 MB | 100 MB |
| **CPU overhead** | 0 | ~0.1% per run | ~0.5% | 0.5-2% | 0.5-1% | 0.1-0.5% | 1-3% |
| **Memory** | 0 | 0 | 5-10 MB | 15-30 MB | 10-20 MB | 3-8 MB | 30-80 MB |
| **Configuration** | None | Write scripts | Write scripts | TOML file | CLI flags | Config file | Kickstart |
| **Metrics per host** | ~20 | ~20 | ~50 | 300+ | 500+ | 100+ | 2000+ |
| **Collection interval** | 60s+ | 60s+ | 1s+ | 1s+ | 15s (scrape) | 10s+ | 1s |
| **Custom metrics** | Any | Any | Any | Exec plugin | Textfile | Exec plugin | Custom charts |
| **Auto-discovery** | None | None | None | Plugins | None | None | Auto |
| **Alerting** | Manual | Manual | Manual | With Kapacitor | With Alertmanager | Built-in | Built-in |
| **Dashboard** | None | Terminal/HTML | Custom/HTML | Grafana | Grafana | Grafana | Built-in |
| **Centralization** | SSH pull | rsync/file | HTTP push | Multi-output | Prometheus pull | Network plugin | Streaming |

**Recommendation by scale:**

| Scale | Recommended approach |
|-------|---------------------|
| 1-5 hosts | Agentless SSH pull or bash cron |
| 5-20 hosts | Bash/python + cron + rsyslog forwarding |
| 20-100 hosts | Telegraf or Node Exporter + Prometheus |
| 100-500 hosts | Telegraf + InfluxDB + Grafana OR Prometheus + Node Exporter |
| 500-5000+ hosts | Prometheus + Node Exporter + Thanos/Cortex + Alertmanager |

---

## Migration Path: Agentless → Agent-Based

### Phase 1: Raw Agentless (Day 1)
```
SSH pull or cron + CSV files
Pros: Zero install, works everywhere
Cons: Manual, no history, no dashboards
```

### Phase 2: Add sysstat + rsyslog (Day 2)
```
Enable sysstat for historical sar data
Add rsyslog forwarding to central server
Pros: Historical data, centralized logs
Cons: Need to manually parse files
```

### Phase 3: Add Telegraf (Week 1)
```
apt install telegraf
# Use the same /proc + /sys — but now ship to InfluxDB
Pros: Structured, many outputs, auto-graph
Cons: Need an InfluxDB server
```

### Phase 4: Add Grafana Dashboards (Week 2)
```
Connect InfluxDB to Grafana
Import Node Exporter Full template
Pros: Real dashboards, alerting
Cons: Need to maintain Grafana
```

### Phase 5: Prometheus Stack (Month 1)
```
Switch from InfluxDB to Prometheus for metrics
Add Alertmanager for paging
Add Node Exporter on all nodes
Pros: Industry standard, scalable to 5000+
Cons: More components to maintain
```

### Phase 6: Auto-Discovery & Service Mesh (Month 2+)
```
Add Consul/Service Registry
Prometheus service discovery
Kubernetes monitoring with Prometheus Operator
Pros: Zero-touch for new nodes
Cons: Complex infrastructure
```

**At every phase, your `/proc` and `/sys` reading scripts still work.** The agent is just a more efficient, more reliable version of what you already wrote.
