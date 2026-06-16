# Iptables Guide

Complete documentation for iptables (and nftables) — the Linux kernel packet filtering framework.

## Contents

| File | What it covers |
|------|----------------|
| [01-overview.md](./01-overview.md) | What is iptables, tables, chains, rules, basic packet flow |
| [02-tables-and-chains.md](./02-tables-and-chains.md) | The 5 tables (filter, nat, mangle, raw, security) and built-in chains |
| [03-rules.md](./03-rules.md) | Rule anatomy, matches (-s, -d, -p, --sport, --dport, -m), targets |
| [04-connection-tracking.md](./04-connection-tracking.md) | conntrack, states (NEW, ESTABLISHED, RELATED, INVALID), stateful firewall |
| [05-practical-examples.md](./05-practical-examples.md) | Common scenarios — web server, SSH lockdown, NAT, port forwarding |
| [06-packet-flow.md](./06-packet-flow.md) | How packets traverse tables and chains (diagram) |
| [07-nftables.md](./07-nftables.md) | nftables as the modern replacement, syntax comparison, migration |
| [08-reference.md](./08-reference.md) | Command cheat sheet and quick reference |

## Quick Start

```bash
# List all current rules
sudo iptables -L -v -n

# List rules with line numbers
sudo iptables -L --line-numbers

# Allow SSH on port 22
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Block all other incoming traffic
sudo iptables -P INPUT DROP

# Save rules (varies by distro)
sudo iptables-save > /etc/iptables/rules.v4
```

## Package Installation

```bash
# Fedora/RHEL
sudo dnf install iptables iptables-services

# Debian/Ubuntu
sudo apt install iptables iptables-persistent

# For nftables
sudo dnf install nftables   # Fedora/RHEL
sudo apt install nftables    # Debian/Ubuntu
```

## Resources

- [Netfilter Project](https://netfilter.org/)
- [Iptables Tutorial](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)
- [nftables Wiki](https://wiki.nftables.org/)
