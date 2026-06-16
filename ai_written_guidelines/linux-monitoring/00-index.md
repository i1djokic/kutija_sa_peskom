# Linux Agentless Monitoring — Deep Dive Guides

## Structure

| # | File | Topic |
|---|------|-------|
| 1 | [01-kernel-interfaces.md](./01-kernel-interfaces.md) | `/proc`, `/sys`, and other kernel-exposed interfaces |
| 2 | [02-builtin-cli-tools.md](./02-builtin-cli-tools.md) | Every built-in tool covered in depth with practical examples |
| 3 | [03-systemd-journald.md](./03-systemd-journald.md) | systemd, journalctl, logging, cgroups, boot analysis |
| 4 | [04-bash-automation.md](./04-bash-automation.md) | Bash collectors, cron pipelines, alerting, SSH pull |
| 5 | [05-python-collection.md](./05-python-collection.md) | Python /proc parsers, HTTP push, central server, integration |
| 6 | [06-lightweight-agents.md](./06-lightweight-agents.md) | When to add an agent: Telegraf, Node Exporter, collectd, netdata |
| 7 | [07-centralization-patterns.md](./07-centralization-patterns.md) | Push vs pull, syslog forwarding, Prometheus stack, Kafka pipelines |

## Quick Start by Use Case

- **I just need a health check on 5 servers** → [04-bash-automation.md](./04-bash-automation.md)
- **I want historical metrics on a single box** → [02-builtin-cli-tools.md](./02-builtin-cli-tools.md) (sar section)
- **I need centralized logs from 50 servers** → [07-centralization-patterns.md](./07-centralization-patterns.md)
- **I want a custom Python dashboard** → [05-python-collection.md](./05-python-collection.md)
- **I have 500+ servers and need real monitoring** → [06-lightweight-agents.md](./06-lightweight-agents.md)

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Kernel Interfaces                   │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │  /proc   │ │  /sys    │ │  syscalls / netlink │   │
│  └────┬─────┘ └────┬─────┘ └─────────┬─────────┘   │
│       │            │                  │              │
│       ▼            ▼                  ▼              │
│  ┌──────────────────────────────────────────────┐   │
│  │         Built-in CLI Tools Layer              │   │
│  │  top, ps, free, iostat, sar, ss, ip, etc.    │   │
│  └──────────────────────────────────────────────┘   │
│       │            │                  │              │
│       ▼            ▼                  ▼              │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │  Bash    │ │  Python  │ │  systemd/rsyslog   │   │
│  │  cron    │ │  scripts │ │  forwarding        │   │
│  └────┬─────┘ └────┬─────┘ └─────────┬─────────┘   │
│       │            │                  │              │
│       ▼            ▼                  ▼              │
│  ┌──────────────────────────────────────────────┐   │
│  │       Central Aggregation Layer               │   │
│  │  InfluxDB, Prometheus, Logstash, SQLite, CSV │   │
│  └──────────────────────────────────────────────┘   │
│       │                                              │
│       ▼                                              │
│  ┌──────────────────────────────────────────────┐   │
│  │       Visualization / Alerting                 │   │
│  │  Grafana, Alertmanager, custom dashboards    │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Prerequisite Knowledge

- Basic Linux command-line: `ls`, `cat`, `grep`, `awk`, pipes
- Understanding of processes, memory, disk, networking concepts
- (For Python sections) Basic Python: reading files, JSON, HTTP

## How to Use

Read in order for a complete understanding, or jump to specific topics via the index. Every file is self-contained with its own examples and references.
