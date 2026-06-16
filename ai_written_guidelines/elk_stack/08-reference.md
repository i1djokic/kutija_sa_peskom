# Reference

## Elasticsearch

### REST API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/_cat/indices?v` | List all indices |
| `GET` | `/_cat/nodes?v` | List cluster nodes |
| `GET` | `/_cluster/health` | Cluster health status |
| `GET` | `/_cluster/allocation/explain` | Shard allocation info |
| `GET` | `/<index>/_search` | Search an index |
| `POST` | `/<index>/_doc` | Index a document (auto ID) |
| `PUT` | `/<index>/_doc/<id>` | Index a document (explicit ID) |
| `POST` | `/<index>/_update/<id>` | Update a document |
| `DELETE` | `/<index>/_doc/<id>` | Delete a document |
| `DELETE` | `/<index>` | Delete an index |
| `PUT` | `/<index>` | Create an index |
| `GET` | `/<index>/_settings` | Get index settings |
| `PUT` | `/<index>/_settings` | Update index settings |
| `GET` | `/<index>/_mapping` | Get index mapping |
| `POST` | `/_refresh` | Refresh all indices |

### Query DSL

| Query | Purpose |
|-------|---------|
| `{ "match": { "field": "value" } }` | Full-text search |
| `{ "term": { "field": "value" } }` | Exact value match |
| `{ "range": { "field": { "gte": 10 } } }` | Range query |
| `{ "exists": { "field": "field" } }` | Field existence |
| `{ "bool": { "must": [], "filter": [], "should": [], "must_not": [] } }` | Boolean combination |
| `{ "match_all": {} }` | Match all documents |
| `{ "aggs": { "name": { "terms": { "field": "f" } } } }` | Aggregation |

### Cluster Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `discovery.seed_hosts` | `["127.0.0.1"]` | Seed nodes for discovery |
| `cluster.initial_master_nodes` | `[]` | Bootstrap master nodes |
| `network.host` | `127.0.0.1` | Bind address |
| `http.port` | `9200` | HTTP API port |
| `transport.port` | `9300` | Transport protocol port |
| `path.data` | `/var/lib/elasticsearch` | Data directory |
| `path.logs` | `/var/log/elasticsearch` | Log directory |

## Logstash

### Pipeline Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `input { ... }` | — | Data input source |
| `filter { ... }` | — | Data transformation |
| `output { ... }` | — | Data destination |
| `if` / `else if` / `else` | — | Conditional branching |

### Common Plugins

| Plugin | Type | Description |
|--------|------|-------------|
| `file` | Input | Read from files |
| `beats` | Input | Receive from Elastic Beats |
| `tcp` | Input | Receive over TCP |
| `udp` | Input | Receive over UDP |
| `http` | Input | Receive HTTP requests |
| `kafka` | Input/Output | Apache Kafka integration |
| `grok` | Filter | Parse unstructured data |
| `mutate` | Filter | Rename, remove, convert fields |
| `date` | Filter | Parse date strings |
| `geoip` | Filter | GeoIP lookup |
| `useragent` | Filter | Parse user agent strings |
| `json` | Filter | Parse JSON |
| `csv` | Filter | Parse CSV |
| `elasticsearch` | Output | Send to Elasticsearch |
| `stdout` | Output | Print to stdout |
| `file` | Output | Write to file |

### CLI Commands

| Command | Description |
|---------|-------------|
| `bin/logstash -f pipeline.conf` | Run with a pipeline |
| `bin/logstash -f pipeline.conf --config.test_and_exit` | Validate config only |
| `bin/logstash -f pipeline.conf --debug` | Run with debug logging |
| `bin/logstash -f pipeline.conf --config.reload.automatic` | Auto-reload on config change |

## Kibana

### Endpoints

| URL | Description |
|-----|-------------|
| `http://localhost:5601` | Kibana UI |
| `http://localhost:5601/api/status` | Kibana status API |
| `http://localhost:5601/app/discover` | Discover tab |
| `http://localhost:5601/app/dashboards` | Dashboards |
| `http://localhost:5601/app/dev_tools` | Dev Tools console |

### Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `server.port` | `5601` | HTTP port |
| `server.host` | `localhost` | Bind address |
| `elasticsearch.hosts` | `["http://localhost:9200"]` | ES cluster endpoints |
| `kibana.index` | `".kibana"` | Kibana saved objects index |
| `logging.root.level` | `info` | Log level |

## Beats (Quick Reference)

| Beat | Purpose | Default Port |
|------|---------|--------------|
| Filebeat | Log files | 5044 |
| Metricbeat | System and service metrics | — |
| Packetbeat | Network traffic | — |
| Winlogbeat | Windows event logs | — |
| Auditbeat | Audit data | — |
| Heartbeat | Uptime monitoring | — |
