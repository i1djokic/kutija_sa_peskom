# Troubleshooting

## Elasticsearch

### Cluster health is yellow or red

```bash
# Check cluster health
GET _cluster/health

# View unassigned shards
GET _cat/shards?v | grep UNASSIGNED

# Explain why shards are unassigned
GET _cluster/allocation/explain
```

**Common causes:**
- Insufficient disk space — `df -h` on data nodes
- Replicas cannot be assigned because there aren't enough nodes
- Watermark thresholds exceeded

```bash
# Check disk thresholds
GET _cluster/settings?include_defaults=true&flat_settings=true | grep disk
```

### Index is read-only

```bash
# Check if index is read-only
GET my-index/_settings/index.blocks*

# Remove read-only block
PUT my-index/_settings
{
  "index.blocks.read_only_allow_delete": null
}
```

### Query performance is slow

```bash
# Enable slow query logging
PUT my-index/_settings
{
  "index.search.slowlog.threshold.query.warn": "10s",
  "index.search.slowlog.threshold.fetch.warn": "5s"
}

# Check slowlog
GET my-index/_search?slowlog
```

## Logstash

### Pipeline fails silently

```bash
# Test configuration
bin/logstash -f pipeline.conf --config.test_and_exit

# Run with debug logging
bin/logstash -f pipeline.conf --debug

# Check Logstash logs
tail -f /var/log/logstash/logstash-plain.log
```

### Grok pattern not matching

```bash
# Test grok patterns with the grok debugger in Kibana Dev Tools
# Or use the command-line tool:
bin/logstash --pluginpath /usr/share/logstash/plugins -e 'input { stdin {}} filter { grok { match => { "message" => "%{COMBINEDAPACHELOG}" }}} output { stdout { codec => rubydebug }}'
```

### Events not reaching Elasticsearch

```bash
# Check if output is receiving events
# Temporarily replace output with stdout:
output {
  stdout { codec => rubydebug }
}

# Check Elasticsearch connectivity
curl -X GET "localhost:9200/_cluster/health"
```

## Kibana

### Data view shows no data

```bash
# Verify the index pattern matches Elasticsearch indices
GET _cat/indices?v | grep <pattern>

# Check if the time field is correct
# Discover tab → "This field is the default time field"
```

### Kibana won't start

```bash
# Check Kibana logs
tail -f /var/log/kibana/kibana.log

# Verify Elasticsearch is reachable from Kibana
curl -X GET "localhost:5601/api/status"
```

## Common Performance Issues

### Elasticsearch is using too much memory

```yaml
# /etc/elasticsearch/jvm.options
-Xms4g
-Xmx4g
```

**Rule of thumb:** Set heap to 50% of available RAM, but not more than 32GB.

### Logstash is falling behind

```bash
# Monitor Logstash event rate
# http://localhost:9600/_node/stats

# Adjust pipeline settings in logstash.yml
pipeline.workers: 8
pipeline.batch.size: 250
queue.type: persisted
queue.max_bytes: 4gb
```

### Disk usage is growing too fast

```bash
# Check index sizes
GET _cat/indices?v&s=pri.store.size:desc

# Set up ILM to manage index lifecycle
# Configure rollover based on size or age
```
