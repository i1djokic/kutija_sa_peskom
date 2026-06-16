# Firewalld Guide

Complete documentation for firewalld — a dynamic firewall manager that uses zones and services to manage nftables/iptables rules.

## Contents

| File | What it covers |
|------|----------------|
| [01-overview.md](./01-overview.md) | What is firewalld, zones, services, runtime vs permanent, architecture |
| [02-zones.md](./02-zones.md) | Zone types, assigning interfaces and sources, default zone |
| [03-services.md](./03-services.md) | Predefined services, adding/removing ports, custom services |
| [04-rich-rules.md](./04-rich-rules.md) | Rich rule syntax — complex rules beyond services |
| [05-runtime-vs-permanent.md](./05-runtime-vs-permanent.md) | Two-configuration model, --reload, panic mode |
| [06-practical-examples.md](./06-practical-examples.md) | Common scenarios — web server, SSH lockdown, Docker, NAT |
| [07-advanced.md](./07-advanced.md) | Masquerading, port forwarding, ICMP blocks, lockdown, direct rules |
| [08-reference.md](./08-reference.md) | Command cheat sheet and quick reference |

## Quick Start

```bash
# Check status
sudo firewall-cmd --state

# List zones and assigned interfaces
sudo firewall-cmd --get-active-zones

# List rules in a zone
sudo firewall-cmd --list-all

# Add a service (runtime only)
sudo firewall-cmd --add-service=http

# Add a service (permanent)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

## Package Installation

```bash
# Fedora/RHEL
sudo dnf install firewalld
sudo systemctl enable --now firewalld

# Debian/Ubuntu
sudo apt install firewalld
sudo systemctl enable --now firewalld
```

## Resources

- [Firewalld Documentation](https://firewalld.org/documentation/)
- [RHEL Firewalld Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/using-and-configuring-firewalld)
