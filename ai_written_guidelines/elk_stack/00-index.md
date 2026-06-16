# ELK Stack

The ELK Stack (Elasticsearch, Logstash, Kibana) is a trio of open-source tools for centralized logging, log ingestion, and log visualization. It enables searching, analyzing, and visualizing machine-generated data at scale.

## Contents

| File | Topic | Description |
|------|-------|-------------|
| [01-overview.md](./01-overview.md) | Overview | Architecture, components, and use cases |
| [02-elasticsearch.md](./02-elasticsearch.md) | Elasticsearch | Distributed search and analytics engine |
| [03-logstash.md](./03-logstash.md) | Logstash | Server-side data processing pipeline |
| [04-kibana.md](./04-kibana.md) | Kibana | Data visualization and dashboarding |
| [05-pipeline-configuration.md](./05-pipeline-configuration.md) | Pipeline Configuration | Logstash input/filter/output plugins |
| [06-practical-examples.md](./06-practical-examples.md) | Practical Examples | Real-world ELK deployments |
| [07-troubleshooting.md](./07-troubleshooting.md) | Troubleshooting | Common issues and solutions |
| [08-reference.md](./08-reference.md) | Reference | Command cheat sheet and quick reference |

## Quick Start

```bash
# Start Elasticsearch
bin/elasticsearch

# Start Logstash with a pipeline
bin/logstash -f pipeline.conf

# Start Kibana
bin/kibana
```

## Package Installation

### Fedora / RHEL

```bash
# Import GPG keys and add repositories
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Install Elasticsearch
sudo dnf install elasticsearch
sudo systemctl enable elasticsearch --now

# Install Logstash
sudo dnf install logstash

# Install Kibana
sudo dnf install kibana
sudo systemctl enable kibana --now
```

### Debian / Ubuntu

```bash
# Install prerequisites
sudo apt update && sudo apt install -y apt-transport-https

# Import GPG key and add repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Elasticsearch
sudo apt update && sudo apt install elasticsearch
sudo systemctl enable elasticsearch --now

# Install Logstash
sudo apt install logstash

# Install Kibana
sudo apt install kibana
sudo systemctl enable kibana --now
```

## Resources

- [Elasticsearch Official Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Reference](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
- [ELK Stack on GitHub](https://github.com/elastic/elasticsearch)
