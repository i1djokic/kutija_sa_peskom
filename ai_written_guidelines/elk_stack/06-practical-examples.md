# Practical Examples

## Example 1: Nginx Log Centralization

**Problem:** Aggregate access logs from three Nginx web servers into a single Elasticsearch cluster for monitoring and alerting.

**Solution:** Deploy Filebeat on each web server and configure Logstash to parse, geo-enrich, and index the logs.

### Filebeat Configuration (on each web server)

```yaml
filebeat.inputs:
  - type: filestream
    id: nginx-access
    paths:
      - /var/log/nginx/access.log
    parsers:
      - ndjson:
          target: ""

output.logstash:
  hosts: ["logstash-central:5044"]
```

### Logstash Pipeline

```ruby
input {
  beats { port => 5044 }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
  geoip { source => "clientip" }
  useragent { source => "agent" }
  mutate {
    convert => { "response" => "integer" }
    convert => { "bytes" => "integer" }
  }
}

output {
  elasticsearch {
    hosts => ["es-cluster:9200"]
    index => "nginx-access-%{+YYYY.MM.dd}"
  }
}
```

### Kibana Dashboard

```bash
# Create index pattern for nginx-access-*
# Add visualizations:
#   - Line chart: requests over time
#   - Pie chart: HTTP status breakdown
#   - Map: client IP geolocation
#   - Data table: top requested URLs
#   - Metric: total requests in last 24h
```

## Example 2: Application Error Alerting

**Problem:** Receive real-time alerts when application error rates exceed a threshold.

**Solution:** Use Logstash to tag error events and Kibana Alerting to trigger notifications.

### Logstash Filter

```ruby
filter {
  if [level] == "ERROR" or [level] == "FATAL" {
    mutate {
      add_tag => ["critical"]
    }
    throttle {
      before_count => -1
      after_count => 5
      period => 60
      max_age => 3600
      key => "%{host}"
    }
  }
}
```

### Kibana Alert Rule

```yaml
# Stack Management → Rules → Create Rule
Name: High Error Rate
Rule type: Threshold
Index: app-logs-*
Aggregation: count
Condition: count > 100 in last 5 minutes
Actions:
  - Email: ops@example.com
  - Webhook: https://hooks.slack.com/...
```

## Example 3: Multi-Tenant Logging

**Problem:** Isolate logs from different teams using the same ELK cluster.

**Solution:** Use separate indices per team with role-based access control.

### Logstash Pipeline with Team Routing

```ruby
input {
  beats { port => 5044 }
}

filter {
  mutate {
    add_field => { "team" => "%{[fields][team]}" }
  }
}

output {
  if [team] == "team-a" {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "team-a-logs-%{+YYYY.MM.dd}"
    }
  } else if [team] == "team-b" {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "team-b-logs-%{+YYYY.MM.dd}"
    }
  } else {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "default-logs-%{+YYYY.MM.dd}"
    }
  }
}
```

### Elasticsearch Role Configuration

```json
PUT _security/role/team-a-role
{
  "indices": [
    {
      "names": ["team-a-logs-*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ]
}

PUT _security/user/team-a-user
{
  "password": "secure-password",
  "roles": ["team-a-role"]
}
```

## Example 4: Long-Term Log Archival

**Problem:** Retain logs for 90 days for compliance while managing storage costs.

**Solution:** Use Index Lifecycle Management (ILM) to transition data through hot, warm, cold, and delete phases.

```json
PUT _ilm/policy/log-retention
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": { "max_size": "50GB" },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "60d",
        "actions": {
          "searchable_snapshot": { "snapshot_repository": "my_backup" },
          "set_priority": { "priority": 0 }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

## Example 5: Structured JSON Logging from Applications

**Problem:** Parse structured JSON logs produced by a Python application.

### Application Configuration (Python)

```python
import logging
import json_logging

json_logging.init_non_web()
logger = logging.getLogger("my-app")
logger.setLevel(logging.INFO)

handler = logging.StreamHandler()
formatter = json_logging.JSONLogFormatter()
handler.setFormatter(formatter)
logger.addHandler(handler)

logger.info("User login", extra={
    "user_id": 1234,
    "action": "login",
    "ip": "192.168.1.1"
})
```

### Logstash Pipeline

```ruby
input {
  beats { port => 5044 }
}

filter {
  json {
    source => "message"
  }
  date {
    match => ["timestamp", "ISO8601"]
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "app-json-logs-%{+YYYY.MM.dd}"
  }
}
```
