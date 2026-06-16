# Reference

## Quick Commands

| Command | What it does |
|---------|-------------|
| `sudo iptables -L -n -v` | List all filter rules (verbose, numeric) |
| `sudo iptables -L --line-numbers` | List rules with line numbers |
| `sudo iptables -t nat -L -n -v` | List NAT rules |
| `sudo iptables -t mangle -L -n -v` | List mangle rules |
| `sudo iptables -A CHAIN RULE` | Append rule to chain |
| `sudo iptables -I CHAIN NUM RULE` | Insert rule at position NUM |
| `sudo iptables -R CHAIN NUM RULE` | Replace rule at position NUM |
| `sudo iptables -D CHAIN NUM` | Delete rule by line number |
| `sudo iptables -D CHAIN RULE` | Delete rule by specification |
| `sudo iptables -F` | Flush (delete) all rules |
| `sudo iptables -P CHAIN TARGET` | Set default policy |
| `sudo iptables -N CHAIN` | Create a new custom chain |
| `sudo iptables -X CHAIN` | Delete a custom chain |
| `sudo iptables -E OLD NEW` | Rename a custom chain |
| `sudo iptables-save` | Print current rules as save format |
| `sudo iptables-restore < FILE` | Restore rules from save format |
| `sudo conntrack -L` | List connection tracking table |
| `sudo conntrack -C` | Count tracked connections |

## Rule Anatomy

```
iptables [-t table] -A chain [matches] -j target
```

| Part | Options |
|------|---------|
| `-t TABLE` | `filter` (default), `nat`, `mangle`, `raw`, `security` |
| `-A CHAIN` | INPUT, OUTPUT, FORWARD, PREROUTING, POSTROUTING, or custom |
| `-s ADDR` | Source IP or subnet (`10.0.0.0/24`) |
| `-d ADDR` | Destination IP or subnet |
| `-p PROTO` | Protocol: `tcp`, `udp`, `icmp`, `all`, or number |
| `--sport PORT` | Source port (with `-p tcp` or `-p udp`) |
| `--dport PORT` | Destination port (with `-p tcp` or `-p udp`) |
| `-i IFACE` | Input interface |
| `-o IFACE` | Output interface |
| `-m MODULE` | Extension module (conntrack, limit, multiport, etc.) |
| `-j TARGET` | ACCEPT, DROP, REJECT, LOG, RETURN, DNAT, SNAT, MASQUERADE |

## Common Match Modules

### conntrack

```
-m conntrack --ctstate STATE[,STATE...]
```

States: `NEW`, `ESTABLISHED`, `RELATED`, `INVALID`

### limit

```
-m limit --limit RATE[/minute|/second|/hour] --limit-burst NUM
```

Examples: `3/minute`, `10/second`, `1000/hour`

### multiport

```
-m multiport --dports PORT[,PORT...]
-m multiport --sports PORT[,PORT...]
```

### recent

```
-m recent --set --name LIST
-m recent --update --seconds SEC --hitcount NUM --name LIST
-m recent --remove --name LIST
```

### state (legacy — prefer conntrack)

```
-m state --state STATE[,STATE...]
```

## Common Targets

| Target | Table | Chain | Effect |
|--------|-------|-------|--------|
| `ACCEPT` | All | All | Allow packet |
| `DROP` | All | All | Silently discard |
| `REJECT` | filter | INPUT, FORWARD, OUTPUT | Discard + icmp error |
| `LOG` | All | All | Log and continue |
| `RETURN` | All | All | Return to previous chain |
| `DNAT --to-destination IP[:PORT]` | nat | PREROUTING, OUTPUT | Change destination |
| `SNAT --to-source IP[:PORT]` | nat | POSTROUTING | Change source |
| `MASQUERADE` | nat | POSTROUTING | Dynamic source NAT |
| `REDIRECT --to-port PORT` | nat | PREROUTING, OUTPUT | Redirect to local port |
| `MARK --set-mark NUM` | mangle | All | Set netfilter mark |
| `NOTRACK` | raw | PREROUTING, OUTPUT | Skip connection tracking |

## Default Policy Examples

```bash
# Drop all incoming, allow all outgoing
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Drop all traffic both directions (isolated host)
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP
```

## Stateful Firewall Template

```bash
# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Allow established/related
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow new connections for services
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT

# Drop invalid
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
```

## Saving and Restoring

```bash
# Save
sudo iptables-save > /etc/iptables/rules.v4       # IPv4
sudo ip6tables-save > /etc/iptables/rules.v6       # IPv6

# Restore
sudo iptables-restore < /etc/iptables/rules.v4

# Debian/Ubuntu: netfilter-persistent
sudo netfilter-persistent save
sudo netfilter-persistent reload

# RHEL/Fedora: iptables-services
sudo service iptables save
sudo systemctl enable iptables
```

## nftables Equivalents

| iptables | nftables |
|----------|----------|
| `iptables -L` | `nft list ruleset` |
| `iptables -A INPUT -p tcp --dport 22 -j ACCEPT` | `nft add rule inet filter input tcp dport 22 accept` |
| `iptables -P INPUT DROP` | `nft add chain inet filter input { policy drop; }` |
| `iptables -t nat -A POSTROUTING -j MASQUERADE` | `nft add rule nat postrouting masquerade` |
| `iptables -I INPUT 1 ...` | `nft insert rule inet filter input ...` |
| `iptables -D INPUT 3` | `nft delete rule inet filter input handle N` |
| `iptables-save` | `nft list ruleset` |
| `iptables-restore` | `nft -f FILE` |

## Important Paths

| Path | Purpose |
|------|---------|
| `/etc/iptables/rules.v4` | Saved IPv4 rules (Debian/Ubuntu) |
| `/etc/iptables/rules.v6` | Saved IPv6 rules (Debian/Ubuntu) |
| `/etc/sysconfig/iptables` | Saved rules (RHEL/Fedora) |
| `/etc/nftables.conf` | nftables ruleset |
| `/etc/sysctl.d/90-conntrack.conf` | Connection tracking sysctl settings |
| `/proc/net/nf_conntrack` | Active connection tracking table |
