# Kibana

Kibana is the visualization and management layer of the ELK Stack. It provides a web UI for exploring Elasticsearch data, building dashboards, and managing the stack.

## Core Features

| Feature | Description |
|---------|-------------|
| **Discover** | Explore and search data in real time |
| **Visualize** | Create charts, maps, tables, and graphs |
| **Dashboard** | Combine visualizations into a single view |
| **Canvas** | Design custom, pixel-perfect infographics |
| **Maps** | Geospatial data visualization |
| **Machine Learning** | Detect anomalies and forecast trends |
| **Alerting** | Set up threshold-based and machine learning alerts |
| **Dev Tools** | Console for Elasticsearch API interactions |

## Data Views

Before visualizing data, you must create a **Data View** that points to an Elasticsearch index:

1. Open Kibana → **Stack Management** → **Data Views**
2. Click **Create Data View**
3. Enter a name (e.g., `weblogs-*`)
4. Specify the index pattern (e.g., `weblog-*`)
5. Select the time field (`@timestamp`)
6. Click **Save data view to Kibana**

## Discover

The **Discover** tab lets you search and filter data:

```
Search bar:    [status: 404 AND host: web-01        ]
Filters:       + host : web-01    ✕   ✕ time range
                                                    │
Time histogram: ▁▂▃▄▅▆▇█▇▆▅▄▃▂▁                   │
                                                    │
Documents:      timestamp      host      message     │
                2025-06-10    web-01    404 error    │
                2025-06-10    web-02    200 OK       │
```

## Visualizations

### Lens (Drag-and-Drop)

Kibana Lens provides a drag-and-drop interface for building visualizations:

```json
// Equivalent Lens configuration in JSON
{
  "visualizationType": "lnsXY",
  "layers": [
    {
      "layerType": "data",
      "seriesType": "line",
      "xAccessor": "timeline",
      "yConfig": [{ "accessor": "sum_of_bytes" }]
    }
  ]
}
```

### Common Visualization Types

| Type | Use Case |
|------|----------|
| **Line/Area** | Time-series trends |
| **Bar** | Compare values across categories |
| **Pie/Donut** | Proportional distribution |
| **Data Table** | Raw data display |
| **Maps** | Geospatial data |
| **Tag Cloud** | Frequency of terms |
| **Metric** | Single numeric value |
| **Gauge** | Progress toward a goal |

## Dashboard

A dashboard combines multiple visualizations:

```yaml
Dashboard:
  - Requests over time        (line chart)
  - HTTP status breakdown     (pie chart)
  - Top 10 client IPs         (data table)
  - Geolocation map           (region map)
  - Response time percentile  (metric)
  - Error rate gauge          (gauge)
```

## Dev Tools

The **Dev Tools** console provides direct access to the Elasticsearch API:

```
# In Kibana Dev Tools Console:

GET _cluster/health

PUT my-index/_doc/1
{
  "message": "Hello from Dev Tools"
}

GET my-index/_search
{
  "query": { "match_all": {} }
}
```

## Saved Objects

Kibana allows exporting and importing dashboards, visualizations, and data views:

```bash
# Export saved objects as NDJSON
# Stack Management → Saved Objects → Export

# Import saved objects
# Stack Management → Saved Objects → Import
```

## Managing Elasticsearch Indices

```bash
# View indices
GET _cat/indices?v

# Manage index lifecycle
PUT _ilm/policy/my_policy
{
  "policy": {
    "phases": {
      "hot":  { "min_age": "0d", "actions": { "rollover": { "max_size": "50GB" }}},
      "warm": { "min_age": "30d", "actions": { "shrink": { "number_of_shards": 1 }}},
      "cold": { "min_age": "60d", "actions": { "freeze": {} }},
      "delete": { "min_age": "90d", "actions": { "delete": {} }}
    }
  }
}
```
