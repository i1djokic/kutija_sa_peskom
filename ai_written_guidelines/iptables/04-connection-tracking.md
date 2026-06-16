# Connection Tracking (conntrack)

Connection tracking is what makes iptables a **stateful firewall**. The kernel tracks every network connection and categorizes packets by connection state.

## The Four States

### ESTABLISHED

Packets belonging to an **existing connection** that has seen traffic in both directions.

```bash
# Allow all established connections (return traffic)
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
```

This is the most important rule in any stateful firewall — without it, no response traffic gets back in.

### RELATED

Packets belonging to a **new connection that is associated with an existing one**. Examples:
- FTP data connection (FTP control connection spawns a separate data connection)
- ICMP errors (Path MTU discovery related to a TCP connection)
- IRC DCC

```bash
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

### NEW

The **first packet** of a new connection (typically a TCP SYN packet).

```bash
# Allow new SSH connections
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
```

### INVALID

Packets that don't match any known connection and aren't starting a new valid one. These should almost always be dropped.

```bash
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
```

## Typical Stateful Rule Set

```bash
# Allow return traffic
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow loopback traffic
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow new SSH connections
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# Allow new HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# Drop invalid packets
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Default: drop everything else
sudo iptables -P INPUT DROP
```

## Viewing the Connection Table

```bash
# Show all tracked connections
sudo conntrack -L

# Show only TCP connections
sudo conntrack -L -p tcp

# Show connections by state
sudo conntrack -L --state ESTABLISHED

# Show counts
sudo conntrack -C

# Watch connections in real time
sudo conntrack -E
```

## Connection Tracking and Performance

Connection tracking uses memory. Each tracked connection consumes about 400 bytes. On high-traffic servers, you can:

### Increase the limit

```bash
# Check current count and max
sudo sysctl net.netfilter.nf_conntrack_count
sudo sysctl net.netfilter.nf_conntrack_max

# Increase max (e.g., to 1M)
sudo sysctl -w net.netfilter.nf_conntrack_max=1000000
echo "net.netfilter.nf_conntrack_max=1000000" | sudo tee /etc/sysctl.d/90-conntrack.conf
```

### Skip tracking for high-volume ports

Use the `raw` table to exempt traffic from connection tracking:

```bash
# Don't track incoming DNS traffic (high volume, stateless)
sudo iptables -t raw -A PREROUTING -p udp --dport 53 -j NOTRACK
sudo iptables -t raw -A OUTPUT -p udp --sport 53 -j NOTRACK

# Then allow it in filter with stateless rules
sudo iptables -A INPUT -p udp --dport 53 -j ACCEPT
sudo iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
```

## Timeout Values

Connection tracking times out connections based on protocol and state:

```bash
# Check current timeouts (tunable via sysctl)
sudo sysctl net.netfilter.nf_conntrack_tcp_timeout_established
# Default: 432000 seconds (5 days)

# Shorten for high-traffic servers
sudo sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=86400
```

## Common Troubleshooting

**Symptom:** Server stops accepting connections under load.
**Cause:** Connection tracking table full (`conntrack -C` hits `conntrack_max`).

**Symptom:** UDP applications don't work with stateful rules.
**Cause:** UDP is connectionless — NEW packets may not be recognized correctly. Ensure `RELATED` is included.

**Symptom:** FTP transfers fail.
**Cause:** FTP data connections are RELATED but the `nf_conntrack_ftp` module must be loaded:

```bash
sudo modprobe nf_conntrack_ftp
echo "nf_conntrack_ftp" | sudo tee /etc/modules-load.d/ftp-conntrack.conf
```
