# Pipeline Configuration

Logstash pipelines define the flow of data from input to output. This guide covers advanced pipeline patterns and configuration techniques.

## Conditional Logic

Use conditionals to process events differently based on field values:

```ruby
filter {
  if [status] >= 400 {
    mutate {
      add_tag => ["error"]
    }
    grok {
      match => { "message" => "%{GREEDYDATA:error_message}" }
    }
  } else if [status] >= 300 {
    mutate {
      add_tag => ["redirect"]
    }
  } else {
    mutate {
      add_tag => ["success"]
    }
  }
}

output {
  if "error" in [tags] {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "errors-%{+YYYY.MM.dd}"
    }
  } else {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "logs-%{+YYYY.MM.dd}"
    }
  }
}
```

## Multiple Pipelines

Logstash supports running multiple independent pipelines from a single instance:

```yaml
# /etc/logstash/pipelines.yml
- pipeline.id: weblog
  path.config: "/etc/logstash/conf.d/weblog.conf"
  pipeline.workers: 4

- pipeline.id: syslog
  path.config: "/etc/logstash/conf.d/syslog.conf"
  pipeline.workers: 2

- pipeline.id: metrics
  path.config: "/etc/logstash/conf.d/metrics.conf"
  pipeline.workers: 1
```

## Pipeline-to-Pipeline Communication

Use **pipeline bus** to send events between pipelines:

```ruby
# Sender pipeline
input {
  beats { port => 5044 }
}

output {
  pipeline {
    send_to => ["central-processing"]
  }
}
```

```ruby
# Receiver pipeline
input {
  pipeline {
    address => "central-processing"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
}

output {
  elasticsearch { hosts => ["localhost:9200"] }
}
```

## Performance Tuning

### Pipeline Workers

```ruby
# /etc/logstash/logstash.yml
pipeline.workers: 8          # Default: number of CPU cores
pipeline.batch.size: 125     # Events per worker per batch
pipeline.batch.delay: 50     # Max wait in ms for a batch
```

### Queue Types

| Type | Behavior | Persistence |
|------|----------|-------------|
| `memory` (default) | In-memory queue; fast but drops on crash | None |
| `persisted` | Disk-backed queue; survives restarts | Disk |

```ruby
queue.type: persisted
queue.max_bytes: 4gb
queue.drain: true            # Wait for queue to empty before shutdown
```

## Common Pipeline Patterns

### Parse Apache/Nginx Access Logs

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
  date {
    match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "weblog-%{+YYYY.MM.dd}"
  }
}
```

### Parse JSON Logs

```ruby
input {
  beats { port => 5044 }
}

filter {
  json {
    source => "message"
    target => "parsed"
  }
  date {
    match => ["[parsed][timestamp]", "ISO8601"]
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "json-logs-%{+YYYY.MM.dd}"
  }
}
```

### Enrich with External Data

```ruby
filter {
  elasticsearch {
    hosts => ["localhost:9200"]
    query => "host:%{[host]}"
    fields => { "environment" => "env" }
  }
  translate {
    field => "status"
    destination => "status_text"
    dictionary => {
      "200" => "OK"
      "404" => "Not Found"
      "500" => "Internal Server Error"
    }
  }
}
```

### Aggregate Events

```ruby
filter {
  aggregate {
    task_id => "%{clientip}"
    code => "
      map['count'] ||= 0
      map['count'] += 1
    "
    push_previous_map_as_event => true
    timeout => 10
  }
}
```
