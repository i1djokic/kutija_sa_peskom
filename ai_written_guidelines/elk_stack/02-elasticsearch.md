# Elasticsearch

Elasticsearch is a distributed, RESTful search and analytics engine built on Apache Lucene. It stores data as JSON documents and provides near-real-time search capabilities.

## Core Concepts

### Index

An **index** is a collection of documents with similar characteristics. It is analogous to a database in SQL:

```
SQL Database   → Elasticsearch Index
SQL Table      → Index Type (deprecated)
SQL Row        → Document
SQL Column     → Field
SQL Index      → Inverted Index
```

```bash
# Create an index
PUT /my-index
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 2
  }
}
```

### Document

A **document** is a JSON object stored in an index. It is the basic unit of information:

```json
{
  "_index": "my-index",
  "_id": "1",
  "_source": {
    "timestamp": "2025-06-10T12:00:00Z",
    "message": "Connection established",
    "host": "web-01",
    "status": 200
  }
}
```

```bash
# Index a document
PUT my-index/_doc/1
{
  "timestamp": "2025-06-10T12:00:00Z",
  "message": "Connection established",
  "host": "web-01"
}

# Get a document
GET my-index/_doc/1

# Search documents
GET my-index/_search
{
  "query": {
    "match": { "host": "web-01" }
  }
}
```

### Shards & Replicas

Elasticsearch splits indices into **shards** for horizontal scaling. Each shard is a fully functional Lucene index.

| Concept | Purpose |
|---------|---------|
| **Primary shard** | Holds the original data; defines index capacity |
| **Replica shard** | Copy of a primary shard; provides failover and read throughput |

```bash
# View shard allocation
GET _cat/shards?v

# View cluster health
GET _cluster/health
```

### Mapping

**Mapping** defines how documents and their fields are stored and indexed:

```json
{
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "message":   { "type": "text" },
      "host":      { "type": "keyword" },
      "status":    { "type": "integer" }
    }
  }
}
```

```bash
# Get mapping of an index
GET my-index/_mapping
```

## CRUD Operations

### Create

```bash
# Index with auto-generated ID
POST my-index/_doc
{
  "field": "value"
}

# Index with explicit ID
PUT my-index/_doc/2
{
  "field": "value"
}
```

### Read

```bash
# Get by ID
GET my-index/_doc/1

# Search
GET my-index/_search
{
  "query": { "match_all": {} }
}
```

### Update

```bash
# Partial update
POST my-index/_update/1
{
  "doc": {
    "status": 404
  }
}
```

### Delete

```bash
# Delete document
DELETE my-index/_doc/1

# Delete index
DELETE my-index
```

## Aggregations

Elasticsearch provides aggregations for data analytics:

```bash
# Average response time by host
GET logs/_search
{
  "size": 0,
  "aggs": {
    "by_host": {
      "terms": { "field": "host.keyword" },
      "aggs": {
        "avg_response": {
          "avg": { "field": "response_time" }
        }
      }
    }
  }
}
```

## Cluster Management

```bash
# List nodes
GET _cat/nodes?v

# List indices
GET _cat/indices?v

# Check cluster health
GET _cluster/health

# Force a refresh (make documents searchable immediately)
POST _refresh
```
