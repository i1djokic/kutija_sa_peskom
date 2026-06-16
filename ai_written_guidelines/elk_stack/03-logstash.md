# Logstash

Logstash is a server-side data processing pipeline that ingests data from multiple sources, transforms it, and sends it to a destination (usually Elasticsearch).

## Pipeline Architecture

A Logstash pipeline has three stages:

```
Input → Filter → Output
```

Each stage uses **plugins**:

| Stage | Purpose | Examples |
|-------|---------|----------|
| **Input** | Ingest data from sources | file, beats, tcp, udp, http, kafka, syslog |
| **Filter** | Parse and transform data | grok, mutate, date, geoip, useragent, csv, json |
| **Output** | Send data to destination | elasticsearch, file, stdout, kafka, s3 |

## Pipeline Configuration

Pipelines are defined in `.conf` files:

```
input {
  beats {
    port => 5044
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }

  date {
    match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
  }

  geoip {
    source => "clientip"
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "weblog-%{+YYYY.MM.dd}"
  }
}
```

## Input Plugins

### File Input

```ruby
input {
  file {
    path => "/var/log/nginx/access.log"
    start_position => "beginning"
    sincedb_path => "/var/lib/logstash/sincedb"
  }
}
```

### Beats Input

```ruby
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate_authorities => ["/etc/logstash/ca.crt"]
  }
}
```

### TCP Input

```ruby
input {
  tcp {
    port => 5000
    codec => json
  }
}
```

## Filter Plugins

### Grok

Grok parses unstructured text into structured fields using predefined patterns:

```ruby
filter {
  grok {
    match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_host} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
  }
}
```

Common built-in patterns: `%{IP:clientip}`, `%{URIPATHPARAM:request}`, `%{NUMBER:response_code}`, `%{TIMESTAMP_ISO8601:timestamp}`.

### Mutate

The mutate filter transforms fields:

```ruby
filter {
  mutate {
    remove_field => ["@version", "tags"]
    rename => { "host" => "source_host" }
    convert => { "status" => "integer" }
    uppercase => ["protocol"]
    gsub => ["message", "\n", ""]
  }
}
```

### Date

Parse date strings into Logstash's internal `@timestamp`:

```ruby
filter {
  date {
    match => ["timestamp", "ISO8601", "dd/MMM/yyyy:HH:mm:ss Z"]
    target => "@timestamp"
  }
}
```

### GeoIP

Add geographical location data from an IP address:

```ruby
filter {
  geoip {
    source => "clientip"
    target => "geo"
    fields => ["city_name", "country_name", "location"]
  }
}
```

## Output Plugins

### Elasticsearch Output

```ruby
output {
  elasticsearch {
    hosts => ["https://es-node1:9200", "https://es-node2:9200"]
    index => "logs-%{+YYYY.MM.dd}"
    user => "logstash"
    password => "${ES_PASSWORD}"
    ssl => true
    cacert => "/etc/logstash/ca.crt"
  }
}
```

### Multiple Outputs

```ruby
output {
  elasticsearch {
    hosts => ["localhost:9200"]
  }
  file {
    path => "/var/log/logstash/backup.log"
  }
}
```

## Running Logstash

```bash
# Test a pipeline configuration
bin/logstash -f pipeline.conf --config.test_and_exit

# Run with a pipeline
bin/logstash -f pipeline.conf

# Run multiple pipelines
bin/logstash -f /etc/logstash/conf.d/

# Run with automatic reload
bin/logstash -f pipeline.conf --config.reload.automatic
```
