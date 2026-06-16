# ELK Stack Overview

The ELK Stack is a collection of three open-source products — Elasticsearch, Logstash, and Kibana — that work together to ingest, store, search, and visualize data in real time.

## Architecture

```
Data Source → Logstash → Elasticsearch → Kibana
                  ↑                         |
                  |                         ↓
              (parse/filter)          (visualize)
```

### Components

| Component | Role | Default Port |
|-----------|------|--------------|
| **Elasticsearch** | Distributed search and analytics engine | 9200 (HTTP), 9300 (transport) |
| **Logstash** | Server-side data processing pipeline | 5044 (Beats), 5000 (TCP), 9600 (monitoring) |
| **Kibana** | Data visualization and exploration UI | 5601 |

## Data Flow

1. **Logstash** ingests data from sources (files, TCP/UDP, Beats, Kafka)
2. Logstash parses, transforms, and enriches the data through filters
3. Processed data is sent to **Elasticsearch** for indexing
4. **Kibana** queries Elasticsearch and renders visualizations

## Use Cases

- **Centralized logging** — aggregate logs from multiple servers
- **Security analytics** — SIEM-style threat detection
- **Application monitoring** — APM and performance metrics
- **Business analytics** — real-time dashboards on business KPIs
- **Compliance auditing** — long-term log retention and search

## Elastic Stack (formerly ELK)

The Elastic Stack adds **Beats** (lightweight data shippers) to the original three components. Beats sit on edge nodes and send data to Logstash or directly to Elasticsearch:

```
Beats → Logstash → Elasticsearch → Kibana
  │        ↑
  └────────┘ (optional direct to ES)
```

Common Beats: Filebeat (log files), Metricbeat (metrics), Packetbeat (network), Winlogbeat (Windows events).
