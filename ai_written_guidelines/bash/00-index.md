# Bash & DevOps Automation Guide

A curated reference for Bash essentials and automation patterns with a focus on **DevOps, sysadmin, and scripting** (no cloud-specific content).

---

## Bash Essentials

| # | Topic | Description |
|---|-------|-------------|
| 1 | [Bash Basics](03-bash-basics.md) | Shebang, syntax, variables, arrays, control flow, globbing |
| 2 | [Functions & Libraries](14-functions-libraries.md) | Functions, scope, `source`, library structure |
| 3 | [File I/O & Path Manipulation](13-file-io.md) | Reading/writing files, `path` expansion, glob patterns, here-docs |
| 4 | [Error Handling & Debugging](12-error-handling.md) | Exit codes, `set -e`, `trap`, debugging with `-x` |
| 5 | [Text Processing](23-text-processing.md) | `grep`, `sed`, `awk`, `cut`, `sort`, `uniq` |
| 6 | [Regular Expressions](19-regex.md) | BRE/ERE syntax, `grep -E`, `sed -E`, `[[ =~ ]]` |
| 7 | [Data Processing](08-data-processing.md) | JSON with `jq`, YAML with `yq`, CSV, ini files |
| 8 | [Datetime & Scheduling](09-datetime-scheduling.md) | `date`, `cron`, `systemd timers`, `at`, time math |

## DevOps & Automation

| # | Topic | Description |
|---|-------|-------------|
| 9 | [Script Safety & Strict Mode](20-script-safety.md) | `set -euo pipefail`, quoting, `IFS`, conventions |
| 10 | [Configuration Management](07-config-management.md) | Parsing YAML/JSON/TOML, `.env` files, config layering |
| 11 | [CLI Tools & Scripting](05-cli-tools.md) | `getopts`, argument parsing, usage patterns, idempotency |
| 12 | [Subprocess & System Automation](21-subprocess-system.md) | Running commands, process mgmt, `pkill`, `timeout` |
| 13 | [Working with APIs](01-apis.md) | `curl`, `HTTPie`, REST APIs, auth, error handling, rate limiting |
| 14 | [Log Management](16-log-management.md) | Rotation, archival, filtering, `logrotate`, real-time tailing |
| 15 | [User & SSH Key Management](24-user-ssh-management.md) | Batch user creation, `authorized_keys`, permissions, hardening |
| 16 | [Backup Automation](02-backup-automation.md) | `rsync`, `tar`, database dumps, object storage sync |
| 17 | [Health Checks & Monitoring](15-health-monitoring.md) | `systemctl`, disk/mem checks, `uptime`, alert thresholds |
| 18 | [Deployment & Rollback](10-deployment-rollback.md) | Blue-green, rsync deploys, health gates, rollback strategies |
| 19 | [Networking & Diagnostics](17-networking-diagnostics.md) | Ping sweep, port scan, DNS, `/dev/tcp`, `nc`, `ss` |
| 20 | [Configuration Drift Detection](11-drift-detection.md) | Hash baselines, `diff`, auditing, compliance checks |
| 21 | [Notifications & Alerting](18-notifications.md) | Slack webhooks, email (`mail`), Telegram, Discord |
| 22 | [System Administration](22-system-admin.md) | Users, groups, permissions, `systemd`, services, `cron` |

## Best Practices

| # | Topic | Description |
|---|-------|-------------|
| 23 | [Bash Best Practices](04-best-practices.md) | DRY, idempotency, naming, error patterns, modularization |
| 24 | [Code Quality](06-code-quality.md) | `shellcheck`, `shfmt`, linting, CI integration |

---

> **Purpose:** Quick-reference guide for DevOps engineers, sysadmins, and developers writing automation scripts in Bash.
