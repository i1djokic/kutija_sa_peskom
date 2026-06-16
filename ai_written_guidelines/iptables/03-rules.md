# Rules

## Anatomy of a Rule

```
iptables -A INPUT -p tcp --dport 80 -s 10.0.0.0/24 -j ACCEPT
         │      │    │         │           │           │
         │      │    │         │           │           └── target
         │      │    │         │           └── match (source)
         │      │    │         └── match (dest port)
         │      │    └── match (protocol)
         │      └── chain
         └── action (append)
```

## Common Matches

### Source / Destination

| Match | Example |
|-------|---------|
| `-s ADDR` | `-s 10.0.0.0/24` — source IP or subnet |
| `-d ADDR` | `-d 203.0.113.1` — destination IP or subnet |
| `! -s ADDR` | `! -s 10.0.0.0/24` — invert match (not this source) |

### Protocol

| Match | Example |
|-------|---------|
| `-p PROTO` | `-p tcp` — protocol name or number |
| `! -p PROTO` | `! -p tcp` — not TCP |

Common protocols: `tcp`, `udp`, `icmp`, `icmpv6`, `all`.

### Port (TCP/UDP)

| Match | Example |
|-------|---------|
| `--sport PORT` | `--sport 1024:65535` — source port range |
| `--dport PORT` | `--dport 22` — destination port |
| `--dport PORT:PORT` | `--dport 3000:3010` — port range |

Must be used with `-p tcp` or `-p udp`.

### Interface

| Match | Example |
|-------|---------|
| `-i IFACE` | `-i eth0` — input interface |
| `-o IFACE` | `-o eth1` — output interface |

### ICMP

```bash
# Allow ping (echo-request)
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Allow ping reply
sudo iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
```

## Extension Modules (Matches via -m)

Extensions add advanced matching capabilities:

### conntrack (stateful matching)

```bash
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
```

See [04-connection-tracking.md](./04-connection-tracking.md) for details.

### mac

Match source MAC address:

```bash
sudo iptables -A INPUT -m mac --mac-source 00:11:22:33:44:55 -j ACCEPT
```

### limit

Rate limiting:

```bash
# Allow max 10 SSH connections per minute
sudo iptables -A INPUT -p tcp --dport 22 -m limit --limit 10/minute -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP

# Log at most 1 entry per minute
sudo iptables -A INPUT -j LOG --log-prefix "DROP " -m limit --limit 1/minute
```

### multiport

Match multiple ports:

```bash
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -j ACCEPT
```

### state (legacy — use conntrack instead)

```bash
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### tcp (TCP-specific flags)

```bash
# Match SYN packets only (new connection requests)
sudo iptables -A INPUT -p tcp --syn -j ACCEPT

# Match TCP flags
sudo iptables -A INPUT -p tcp --tcp-flags ALL SYN -j ACCEPT

# Block Xmas tree scan
sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
```

### recent

Track source addresses for dynamic blocking:

```bash
# Add source to list on SSH attempt
sudo iptables -A INPUT -p tcp --dport 22 -m recent --set --name SSH

# Drop if more than 4 attempts in 60 seconds
sudo iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
```

## Targets

| Target | Effect | Use |
|--------|--------|-----|
| `ACCEPT` | Allow the packet | When you want traffic through |
| `DROP` | Silently discard | Block with no response (IP blacklisting) |
| `REJECT` | Discard + error reply | Block with feedback (icmp-port-unreachable) |
| `LOG` | Log and continue | Debugging |
| `RETURN` | Return to calling chain | End of custom chain processing |
| `DNAT` | Change destination address | Port forwarding (in PREROUTING) |
| `SNAT` | Change source address | Static source NAT (in POSTROUTING) |
| `MASQUERADE` | Dynamic source NAT | NAT on interfaces with dynamic IPs |
| `REDIRECT` | Redirect to local port | Transparent proxy |
| `MARK` | Set netfilter mark | Advanced routing / QoS |
| `NOTRACK` | Skip connection tracking | High-speed protocols |

## Inserting and Deleting

```bash
# Insert at top (position 1)
sudo iptables -I INPUT 1 -s 10.0.0.5 -j DROP

# Delete by rule specification
sudo iptables -D INPUT -s 10.0.0.5 -j DROP

# Delete by line number
sudo iptables -L --line-numbers
sudo iptables -D INPUT 5    # Delete line 5

# Flush all rules
sudo iptables -F

# Flush a specific chain
sudo iptables -F INPUT

# Delete a custom chain
sudo iptables -X MYCHAIN
```
