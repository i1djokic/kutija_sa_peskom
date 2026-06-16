# Centralization Patterns — Push, Pull, Syslog, Prometheus, Kafka

## Table of Contents
1. [Centralization Topologies](#centralization-topologies)
2. [Push Patterns](#push-patterns)
3. [Pull Patterns](#pull-patterns)
4. [Syslog / Log Forwarding](#syslog--log-forwarding)
5. [Prometheus Stack](#prometheus-stack)
6. [Kafka / Message Queue Pipeline](#kafka--message-queue-pipeline)
7. [Grafana: Unified Dashboard](#grafana-unified-dashboard)
8. [Alerting: Alertmanager & Custom](#alerting-alertmanager--custom)
9. [Choosing the Right Topology](#choosing-the-right-topology)

---

## Centralization Topologies

### Topology 1: Direct Push

```
[Host A] ──HTTP POST──> [Central Server: InfluxDB/API]
[Host B] ──HTTP POST──> [Central Server]
[Host C] ──HTTP POST──> [Central Server]
```

**Pros:** Simple, firewall-friendly (hosts initiate outbound)
**Cons:** Central server must handle write load; no replay buffer

### Topology 2: Central Pull

```
[Central Scraper/Scheduler]
    │
    ├── SSH ──> [Host A]
    ├── SSH ──> [Host B]
    └── HTTP ──> [Host C: Prometheus client]
```

**Pros:** Central controls timing; hosts need no config
**Cons:** Requires network reachability; SSH auth management

### Topology 3: Forwarding Chain

```
[Host A] ──syslog──> [Log Aggregator] ──syslog──> [Central Log Server]
[Host B] ──syslog──> [Log Aggregator] ──TCP─────> [SIEM]
[Host C] ──telegraf─> [Local InfluxDB] ──continuous query──> [Central InfluxDB]
```

**Pros:** Scale-out; local buffering; hierarchical aggregation
**Cons:** More components; potential data duplication

### Topology 4: Message Queue

```
[Host A] ──> Kafka Producer ──> [Kafka] ──> [Consumer: InfluxDB]
[Host B] ──> Kafka Producer ──> [Kafka] ──> [Consumer: Elasticsearch]
[Host C] ──> Kafka Producer ──> [Kafka] ──> [Consumer: Archive]
```

**Pros:** Decoupled; replayable; many consumers; durable
**Cons:** Requires Kafka cluster (ZooKeeper/KRaft); heavy ops

---

## Push Patterns

### Pattern A: Bash + curl to Central API

**On each host (cron every 5 minutes):**

```bash
#!/bin/bash
# /usr/local/bin/push-metrics.sh

HOST=$(hostname)
LOAD=$(awk '{print $1}' /proc/loadavg)
MEM=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END{printf "%.0f", (1-a/t)*100}' /proc/meminfo)
DISK=$(df / | awk 'NR==2{print $5}' | tr -d '%')
EPOCH=$(date +%s)

curl -s -X POST "https://monitor.example.com/api/metrics" \
    -H "X-API-Key: ${MONITOR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"host\":\"$HOST\",\"timestamp\":$EPOCH,\"load\":$LOAD,\"mem\":$MEM,\"disk\":$DISK}"
```

**Central receiver (nginx + Flask):**
```
location /api/metrics {
    proxy_pass http://127.0.0.1:8080;
    client_max_body_size 64k;
    proxy_read_timeout 10s;
}
```

### Pattern B: Telegraf to InfluxDB

```toml
# On each host — /etc/telegraf/telegraf.conf
[[outputs.influxdb_v2]]
    urls = ["https://influxdb.example.com:8086"]
    token = "${INFLUX_TOKEN}"
    organization = "myorg"
    bucket = "metrics"
    insecure_skip_verify = false

[[outputs.http]]
    url = "https://backup.example.com/api/telegraf"
    data_format = "influx"
    timeout = "5s"
```

**Central backup receiver (any HTTP server):**
```python
# receiver.py — accepts InfluxDB line protocol
from http.server import HTTPServer, BaseHTTPRequestHandler

class TelegrafHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        with open("/var/log/telegraf-backup/$(date +%Y%m%d).txt", "ab") as f:
            f.write(body + b"\n")
        self.send_response(204)
        self.end_headers()

HTTPServer(("0.0.0.0", 8094), TelegrafHandler).serve_forever()
```

### Pattern C: Node Exporter + Remote Write

Node Exporter doesn't push — but Prometheus can **remote write** to any endpoint:

```yaml
# prometheus.yml
remote_write:
  - url: "https://thanos.example.com/api/v1/receive"
    basic_auth:
      username: "admin"
      password: "secret"
  - url: "https://cortex.example.com/api/v1/push"
```

---

## Pull Patterns

### Pattern A: Prometheus Scrape

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'node'
    scrape_interval: 30s
    scrape_timeout: 10s
    static_configs:
      - targets:
        - '10.0.0.1:9100'
        - '10.0.0.2:9100'
        - '10.0.0.3:9100'
  
  - job_name: 'custom-endpoints'
    scrape_interval: 60s
    metrics_path: '/health'
    static_configs:
      - targets:
        - '10.0.0.1:8080'
        - '10.0.0.2:8080'
```

**File-based service discovery** (for dynamic hosts):
```yaml
  - job_name: 'node'
    file_sd_configs:
      - files: ['/etc/prometheus/targets/*.json']
```

**targets/web.json:**
```json
[
  {"targets": ["10.0.0.1:9100", "10.0.0.2:9100"], "labels": {"group": "web"}},
  {"targets": ["10.0.0.3:9100"], "labels": {"group": "db"}}
]
```

### Pattern B: SSH-Based Pull with Parallel Execution

Already covered in [04-bash-automation.md](./04-bash-automation.md), but here's the production version:

```bash
#!/bin/bash
# /usr/local/bin/prometheus-pull.sh — generates a targets.json from inventory

INVENTORY="/etc/monitor/inventory.json"
TARGET_DIR="/etc/prometheus/targets"

mkdir -p "$TARGET_DIR"

# Group by service
for group in $(jq -r 'group_by(.group)[] | .[0].group' "$INVENTORY"); do
    jq --arg g "$group" '.[] | select(.group == $g) | {targets: [.host + ":9100"], labels: {group: $g}}' \
        "$INVENTORY" | jq -s '.' > "$TARGET_DIR/${group}.json"
done
```

### Pattern C: Custom HTTP Endpoint on Each Host

Instead of SSH pull, each host can expose a simple HTTP endpoint that returns JSON:

```python
#!/usr/bin/env python3
"""agentless-httpd.py — minimal HTTP metric server on each host"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json, socket
from collector import CollectOnce

collector = CollectOnce()
HOST = socket.gethostname()


class MetricHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics/json":
            data = collector.collect()
            body = json.dumps(data).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/metrics/prometheus":
            data = collector.collect()
            lines = [
                f'node_load1{{host="{HOST}"}} {data["load"]["load_1m"]}',
                f'node_memory_pct{{host="{HOST}"}} {data["memory"]["pct"]}',
                f'node_disk_pct{{host="{HOST}"}} 0',
            ]
            body = "\n".join(lines).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, *args):
        pass


HTTPServer(("0.0.0.0", 9100), MetricHandler).serve_forever()
```

Now Prometheus can scrape each host directly — **no agent, just a Python script**.

---

## Syslog / Log Forwarding

### rsyslog — The Universal Log Forwarder

**On each client:**

```bash
# /etc/rsyslog.d/50-remote.conf
# Forward all logs to central server

*.* action(
    type="omfwd"
    target="logserver.example.com"
    port="514"
    protocol="tcp"
    action.resumeRetryCount="100"
    queue.type="linkedList"
    queue.size="10000"
    queue.discardseverity="debug"  # drop debug messages when queue full
)

# Also keep local copy
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
*.info;mail.none;authpriv.none;cron.none    /var/log/messages
```

**On the central server:**

```bash
# /etc/rsyslog.d/50-receive.conf
# Receive logs from network

module(load="imtcp")
module(load="imudp")

input(type="imtcp" port="514")
input(type="imudp" port="514")

# Store per-host, per-date
template(name="PerHostLog" type="string"
    string="/var/log/remote/%FROMHOST%/%$YEAR%/%$MONTH%/%$DAY%/messages.log")

*.* action(type="omfile" dynaFile="PerHostLog")
```

**Security (TLS):**

```bash
# Client
$DefaultNetstreamDriverCAFile /etc/ssl/certs/ca-certificates.crt
$ActionSendStreamDriver gtls
$ActionSendStreamDriverMode 1
$ActionSendStreamDriverAuthMode x509/name

# Server
$DefaultNetstreamDriverCAFile /etc/ssl/certs/ca-certificates.crt
$DefaultNetstreamDriverCertFile /etc/ssl/certs/server-cert.pem
$DefaultNetstreamDriverKeyFile /etc/ssl/private/server-key.pem
$ActionSendStreamDriverAuthMode x509/name
```

### journald → syslog → Central

```bash
# 1. Forward journal to syslog
# /etc/systemd/journald.conf
ForwardToSyslog=yes

# 2. Forward syslog to central (rsyslog)
# /etc/rsyslog.d/50-remote.conf
*.* @logserver.example.com:514
```

### Central Log Analysis with Bash

```bash
#!/bin/bash
# /usr/local/bin/analyze-logs.sh — daily summary from centralized logs

DATE=$(date -d yesterday +%Y/%m/%d)
LOG_DIR="/var/log/remote"
REPORT="/var/www/html/log-report-$(date -d yesterday +%Y%m%d).html"

echo "<html><body><h1>Log Summary for $(date -d yesterday +%F)</h1>" > "$REPORT"

for host in "$LOG_DIR"/*; do
    name=$(basename "$host")
    logfile="$host/$DATE/messages.log"
    [ -f "$logfile" ] || continue
    
    total=$(wc -l < "$logfile")
    errors=$(grep -c -i "error" "$logfile" 2>/dev/null || echo 0)
    warns=$(grep -c -i "warning" "$logfile" 2>/dev/null || echo 0)
    
    cat >> "$REPORT" <<HTML
    <div class="host">
        <h2>$name</h2>
        <p>Total: $total | Errors: $errors | Warnings: $warns</p>
    </div>
HTML
done

echo "</body></html>" >> "$REPORT"
```

---

## Prometheus Stack

### Architecture

```
                    ┌──────────────────┐
                    │  Alertmanager     │──> Email, Slack, PagerDuty
                    └────────┬─────────┘
                             │ alerts
        ┌────────────────────┼────────────────────┐
        │                    │                     │
  ┌─────▼─────┐      ┌──────▼──────┐      ┌──────▼──────┐
  │ Prometheus │      │ Prometheus  │      │  Prometheus │
  │ (region 1) │      │ (region 2)  │      │ (region 3)  │
  └─────┬─────┘      └──────┬──────┘      └──────┬──────┘
        │                    │                     │
        │ scrape             │ scrape              │ scrape
  ┌─────▼─────┐      ┌──────▼──────┐      ┌──────▼──────┐
  │ Node Exp. │      │ Node Exp.   │      │  Node Exp.  │
  │ 10 hosts  │      │  10 hosts   │      │  10 hosts   │
  └───────────┘      └─────────────┘      └─────────────┘
        │                    │                     │
        └────────────────────┼─────────────────────┘
                             │ remote write
                      ┌──────▼──────┐
                      │  Thanos /   │
                      │  Cortex     │──> Long-term storage (S3/GCS)
                      └──────┬──────┘
                             │
                      ┌──────▼──────┐
                      │   Grafana   │
                      └─────────────┘
```

### Prometheus Installation

```bash
# Single binary, no dependencies
wget https://github.com/prometheus/prometheus/releases/download/v2.50.0/prometheus-2.50.0.linux-amd64.tar.gz
tar xzf prometheus-*.tar.gz
sudo mv prometheus-*/prometheus prometheus-*/promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo mv prometheus-*/consoles prometheus-*/console_libraries /etc/prometheus/
```

### Complete prometheus.yml

```yaml
global:
  scrape_interval: 30s
  evaluation_interval: 30s
  external_labels:
    region: "us-east-1"
    env: "production"

# Alerting
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

# Rule files
rule_files:
  - "alerts.yml"

# Scrape targets
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    scrape_interval: 15s
    static_configs:
      - targets:
        - '10.0.0.1:9100'
        - '10.0.0.2:9100'
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):.*'
        target_label: 'instance'
        replacement: '${1}'

  - job_name: 'custom-httpd'
    scrape_interval: 30s
    static_configs:
      - targets:
        - '10.0.0.1:9100'
        - '10.0.0.2:9100'
```

### Alert Rules (alerts.yml)

```yaml
groups:
  - name: node_alerts
    interval: 30s
    rules:
      - alert: NodeDown
        expr: up{job="node"} == 0
        for: 5m
        annotations:
          summary: "Node {{ $labels.instance }} is down"

      - alert: HighCpuLoad
        expr: node_load1 > count(node_cpu_seconds_total{mode="user"}) * 0.9
        for: 15m
        annotations:
          summary: "High CPU load on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 90
        for: 10m
        annotations:
          summary: "Memory > 90% on {{ $labels.instance }}"

      - alert: DiskSpaceWarning
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        annotations:
          summary: "Disk space < 15% on {{ $labels.instance }}"

      - alert: SwapUsage
        expr: (node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes) / node_memory_SwapTotal_bytes * 100 > 50
        for: 10m
        annotations:
          summary: "Swap > 50% on {{ $labels.instance }}"
```

### Thanos for Multi-Region

Thanos extends Prometheus with long-term storage and global query:

```yaml
# thanos-sidecar on each Prometheus
thanos sidecar \
    --prometheus.url=http://localhost:9090 \
    --tsdb.path=/var/lib/prometheus \
    --objstore.config-file=s3-config.yaml \
    --http-address=0.0.0.0:19191 \
    --grpc-address=0.0.0.0:19090

# thanos-query (global view)
thanos query \
    --http-address=0.0.0.0:19192 \
    --store=prometheus1:19090 \
    --store=prometheus2:19090 \
    --store=thanos-store:10901
```

---

## Kafka / Message Queue Pipeline

### Architecture

```
[Host A] ──> Telegraf ──> Kafka Producer ──> [Kafka topic: "metrics"]
[Host B] ──> Telegraf ──> Kafka Producer ──> [Kafka topic: "metrics"]
[Host C] ──> Telegraf ──> Kafka Producer ──> [Kafka topic: "metrics"]
                                                    │
                                                    │
                        ┌───────────────────────────┼───────────────┐
                        │                           │               │
                   [Consumer 1]              [Consumer 2]      [Consumer 3]
                        │                           │               │
                        ▼                           ▼               ▼
                   InfluxDB                   Elasticsearch      S3 Archive
                        │                           │
                        ▼                           ▼
                   Grafana                      Kibana
```

### Telegraf → Kafka

```toml
# /etc/telegraf/telegraf.conf

[[outputs.kafka]]
  brokers = ["kafka1.example.com:9092", "kafka2.example.com:9092"]
  topic = "metrics"
  topic_tag = "host"
  data_format = "json"
  sasl_username = "telegraf"
  sasl_password = "${KAFKA_PASSWORD}"
  sasl_mechanism = "SCRAM-SHA-512"
```

### Kafka → InfluxDB (Consumer)

```python
#!/usr/bin/env python3
"""kafka-to-influx.py — consumer that writes to InfluxDB"""

from kafka import KafkaConsumer  # pip install kafka-python
from influxdb_client import InfluxDBClient  # pip install influxdb-client
import json, os

KAFKA_BROKERS = os.environ.get("KAFKA_BROKERS", "kafka:9092")
INFLUX_URL = os.environ.get("INFLUX_URL", "http://influxdb:8086")
INFLUX_TOKEN = os.environ["INFLUX_TOKEN"]
INFLUX_ORG = "myorg"
INFLUX_BUCKET = "metrics"

consumer = KafkaConsumer(
    "metrics",
    bootstrap_servers=KAFKA_BROKERS.split(","),
    value_deserializer=lambda m: json.loads(m.decode()),
    auto_offset_reset="earliest",
    enable_auto_commit=True,
)

influx = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
write_api = influx.write_api()

for msg in consumer:
    data = msg.value
    point = {
        "measurement": "system",
        "tags": {"host": data.get("host")},
        "fields": {
            "load_1m": data.get("load", {}).get("load_1m", 0),
            "memory_pct": data.get("mem", 0),
            "disk_pct": data.get("disk", 0),
        },
        "time": data.get("timestamp") * 1_000_000_000,
    }
    write_api.write(bucket=INFLUX_BUCKET, record=point)
```

### Kafka → S3 Archive

```python
#!/usr/bin/env python3
"""kafka-to-s3.py — batch writer to S3"""

from kafka import KafkaConsumer
import json, gzip, io, os
import boto3  # pip install boto3

consumer = KafkaConsumer(
    "metrics",
    bootstrap_servers="kafka:9092",
    value_deserializer=lambda m: json.loads(m.decode()),
)

s3 = boto3.client("s3")
BUCKET = "monitor-archive"

batch = []
last_flush = time.time()

for msg in consumer:
    batch.append(msg.value)
    
    if len(batch) >= 1000 or (time.time() - last_flush) >= 300:
        buf = io.BytesIO()
        with gzip.GzipFile(fileobj=buf, mode="w") as f:
            for item in batch:
                f.write(json.dumps(item).encode() + b"\n")
        
        key = f"metrics/{time.strftime('%Y/%m/%d/%H%M%S')}.json.gz"
        s3.upload_fileobj(io.BytesIO(buf.getvalue()), BUCKET, key)
        
        batch = []
        last_flush = time.time()
```

---

## Grafana — Unified Dashboard

### Installing Grafana

```bash
# Debian/Ubuntu
apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
apt update && apt install grafana
systemctl enable --now grafana-server

# RHEL/CentOS/Fedora
cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF
yum install grafana
systemctl enable --now grafana-server
```

### Provisioning — Dashboards as Code

```yaml
# /etc/grafana/provisioning/datasources/datasources.yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true

  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://localhost:8086
    database: metrics
    user: admin
    secureJsonData:
      password: "${INFLUX_PASSWORD}"
```

```yaml
# /etc/grafana/provisioning/dashboards/dashboards.yaml
apiVersion: 1

providers:
  - name: 'Node Exporter'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 60
    options:
      path: /etc/grafana/dashboards
```

### Essential Dashboard Panels (JSON)

```json
{
  "title": "System Overview",
  "panels": [
    {
      "title": "CPU Load",
      "type": "graph",
      "targets": [
        {
          "expr": "node_load1{instance=~\"$host\"}",
          "legendFormat": "1m"
        },
        {
          "expr": "node_load5{instance=~\"$host\"}",
          "legendFormat": "5m"
        },
        {
          "expr": "node_load15{instance=~\"$host\"}",
          "legendFormat": "15m"
        }
      ]
    },
    {
      "title": "Memory Usage",
      "type": "gauge",
      "targets": [
        {
          "expr": "(1 - node_memory_MemAvailable_bytes{instance=~\"$host\"} / node_memory_MemTotal_bytes{instance=~\"$host\"}) * 100"
        }
      ],
      "thresholds": "75,90"
    },
    {
      "title": "Disk Space",
      "type": "table",
      "targets": [
        {
          "expr": "100 - (node_filesystem_avail_bytes{mountpoint=\"/\", instance=~\"$host\"} / node_filesystem_size_bytes{mountpoint=\"/\", instance=~\"$host\"}) * 100"
        }
      ]
    }
  ]
}
```

---

## Alerting

### Prometheus Alertmanager

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: '${SMTP_PASSWORD}'

route:
  receiver: 'team-ops'
  group_by: ['alertname', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - match:
        severity: critical
      receiver: 'team-ops-critical'
      repeat_interval: 10m

receivers:
  - name: 'team-ops'
    email_configs:
      - to: 'ops@example.com'

  - name: 'team-ops-critical'
    email_configs:
      - to: 'ops-critical@example.com'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T.../B.../xxx'
        channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ .CommonAnnotations.summary }}'
    pagerduty_configs:
      - routing_key: '${PD_ROUTING_KEY}'
        severity: critical
```

### Bash Alerting with Central Coordination

```bash
#!/bin/bash
# /usr/local/bin/central-alertd.sh
# Run on central server, checks all hosts via SSH

HOSTS=("web01" "web02" "db01")
ALERT_WEBHOOK="https://hooks.slack.com/services/T.../B.../xxx"
ALERT_EMAIL="ops@example.com"
THROTTLE_FILE="/tmp/.alert-throttle"

throttle() {
    local name="$1"
    local interval="${2:-300}"
    local now; now=$(date +%s)
    local last=0
    [ -f "$THROTTLE_FILE.$name" ] && last=$(cat "$THROTTLE_FILE.$name")
    if [ $((now - last)) -lt "$interval" ]; then
        return 1  # throttled
    fi
    echo "$now" > "$THROTTLE_FILE.$name"
    return 0
}

for host in "${HOSTS[@]}"; do
    data=$(ssh -o ConnectTimeout=5 "$host" "
        echo \$(awk '{print \$1}' /proc/loadavg)
        awk '/MemAvailable/{a=\$2} /MemTotal/{t=\$2} END{printf \"%.0f\", (1-a/t)*100}' /proc/meminfo
        df / | awk 'NR==2{print \$5}' | tr -d '%'
        systemctl is-active nginx.service 2>/dev/null || echo 'unknown'
    " 2>/dev/null) || {
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"HOST DOWN: $host unreachable\"}" "$ALERT_WEBHOOK"
        continue
    }
    
    read -r load mem disk nginx <<< "$(echo "$data" | tr '\n' ' ')"
    
    [ "$(echo "$load > 10" | bc)" -eq 1 ] && throttle "load-$host" 300 && \
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"HIGH LOAD on $host: $load\"}" "$ALERT_WEBHOOK"
    
    [ "$mem" -gt 90 ] && throttle "mem-$host" 300 && \
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"HIGH MEMORY on $host: ${mem}%\"}" "$ALERT_WEBHOOK"
    
    [ "$disk" -gt 85 ] && throttle "disk-$host" 600 && \
        mail -s "DISK WARNING: $host at ${disk}%" "$ALERT_EMAIL"
    
    [ "$nginx" != "active" ] && throttle "nginx-$host" 60 && \
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"NGINX DOWN on $host\"}" "$ALERT_WEBHOOK"
done
```

---

## Choosing the Right Topology

### Decision Tree

```
How many hosts?
   │
   ├── < 10 ───> Bash/SSH pull or HTTP push + CSV/JSON files
   │
   ├── 10-50 ──> Telegraf → InfluxDB → Grafana
   │                OR
   │              Node Exporter + Prometheus (single instance)
   │                OR
   │              rsyslog forwarding + sar history
   │
   ├── 50-500 ──> Prometheus + Node Exporter + Alertmanager
   │                OR
   │              Telegraf → Kafka → InfluxDB + Elasticsearch
   │
   ├── 500-5000 ─> Prometheus + Thanos + Alertmanager
   │                OR
   │              Telegraf → Kafka → InfluxDB Cluster + Grafana
   │
   └── 5000+ ───> Prometheus with Thanos/Cortex + Grafana
                    OR
                  Datadog/SignalFX/Splunk (SaaS)
```

### Cost vs Complexity

```
Cost (Ops effort)
      ^
      |                        ┌─── Datadog/Splunk
      |                   ┌────┤ (SaaS, $ per host)
      |              ┌────┤    └───
      |         ┌────┤    └─── Prometheus + Thanos + Grafana
      |    ┌────┤    └─── Telegraf + InfluxDB + Grafana
      |   ┌┤    └─── Agentless Python + SQLite + Grafana
      |   ┤└─── Bash cron + CSV + static HTML
      └───┴──────────────────────────────────────────>
          Agentless                      Agent-based
```

### Practical Recommendation

| Your situation | Start with | Add later |
|---------------|------------|-----------|
| "I have 3 VPS boxes" | Bash cron + rsync | Python + HTTP push |
| "I have 20 production servers" | Telegraf → InfluxDB → Grafana | Alerting with Kapacitor |
| "Startup, 50 servers, fast growth" | Node Exporter + Prometheus (single) | Thanos for long-term storage |
| "Enterprise, 500+ servers" | Prometheus + Node Exporter + Alertmanager | Thanos/Cortex, Service discovery |
| "Kubernetes environment" | Prometheus Operator + Node Exporter | Custom service monitors |

**The key insight: all of them read `/proc` and `/sys`.** The difference is how data moves from kernel → where you can see it.
