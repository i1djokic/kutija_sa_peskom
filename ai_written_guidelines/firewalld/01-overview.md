# Overview

## What Is Firewalld?

Firewalld is a **dynamic firewall management tool** for Linux. It sits on top of **nftables** (or legacy iptables) and provides:

- A **zone-based** security model — different trust levels for different network interfaces
- **Runtime vs permanent** configuration — changes don't take effect until committed
- **Service definitions** — named shortcuts for common port/protocol bundles
- **Rich rules** — rule syntax for complex filtering without writing raw nftables/iptables
- **D-Bus API** — programs can query and modify the firewall dynamically

## Zones Concept

The core idea: **every network interface belongs to exactly one zone**, and each zone defines what traffic is allowed for interfaces in that zone.

```
Zone: public         Zone: internal         Zone: dmz
  ┌──────────┐       ┌──────────┐          ┌──────────┐
  │ eth0     │       │ eth1     │          │ eth2     │
  │ SSHs,    │       │ SSHs,    │          │ SSHs,   │
  │ http     │       │ http,    │          │ http    │
  │ no mysql │       │ mysql    │          │ no mysql│
  └──────────┘       └──────────┘          └──────────┘
```

Your exposed interface (`eth0`) is in `public` (restrictive). Your internal LAN interface (`eth1`) is in `internal` (more permissive). A DMZ interface (`eth2`) is in `dmz`.

## Runtime vs Permanent

Firewalld has **two separate configuration layers:**

| Layer | Applies to | Duration |
|-------|------------|----------|
| **Runtime** | Current session only | Lost on reload or restart |
| **Permanent** | Stored in `/etc/firewalld/` | Survives reloads and reboots |

Without `--permanent`, changes are runtime only:

```bash
sudo firewall-cmd --add-service=http    # Runtime (lost on reload)
sudo firewall-cmd --permanent --add-service=http  # Permanent
```

To apply permanent changes without a reload, use `--runtime-to-permanent`.

## Architecture

```
firewall-cmd (CLI)
    │
    ▼
firewalld (daemon, D-Bus service)
    │
    ├── Configuration: /etc/firewalld/ (user overrides)
    ├── Default configuration: /usr/lib/firewalld/ (distro defaults)
    │
    ▼
nftables / iptables (kernel)
```

The user config in `/etc/firewalld/` overrides distro defaults in `/usr/lib/firewalld/`. Never edit files under `/usr/lib/firewalld/`.

## Key Concepts

- **Zone** — a named group of rules for a trust level
- **Service** — a named bundle of ports/protocols (e.g., `http` = tcp/80)
- **Rich rule** — an expressive rule syntax for complex matching
- **Source** — an IP address or subnet assigned to a zone
- **Interface** — a network interface assigned to a zone
- **Direct rule** — raw iptables/nftables rules passed through firewalld (escape hatch)
