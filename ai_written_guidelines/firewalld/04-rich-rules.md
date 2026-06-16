# Rich Rules

Rich rules extend firewalld beyond simple service/port rules. They let you match on source IP, log traffic, set rate limits, and more — all without dropping to direct/iptables rules.

## Syntax

```
rule [family="ipv4|ipv6"]
  [source address="ADDRESS" [invert="True"]]
  [destination address="ADDRESS" [invert="True"]]
  [<element>]
  [log [prefix="TEXT"] [level="LOG_LEVEL"] [limit value="RATE"/DURATION"]]
  [audit]
  [accept|reject|drop]
```

## Basic Examples

### Allow traffic from a specific IP

```bash
sudo firewall-cmd --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.100"
  accept'
```

### Allow SSH only from a specific subnet

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.0/24"
  service name="ssh"
  accept'
```

### Block a specific IP

```bash
sudo firewall-cmd --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="203.0.113.5"
  drop'
```

### Allow HTTP from everyone, HTTPS from a specific subnet only

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="10.0.0.0/24"
  service name="https"
  accept'

sudo firewall-cmd --permanent --zone=public --add-service=http
```

## Logging Rules

### Log rejected SSH attempts

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule service name="ssh"
  log prefix="SSH_BLOCKED" level="info"
  reject'
```

### Log with rate limiting

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule service name="ssh"
  log prefix="SSH_BLOCKED" level="info" limit value="1/m"
  reject'
```

## Port-Based Rich Rules

Instead of `service name="ssh"`, use `port port="22" protocol="tcp"`:

```bash
sudo firewall-cmd --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="192.168.1.0/24"
  port port="3306" protocol="tcp"
  accept'
```

## Accept with Destination IP

```bash
# Allow access to a specific local IP only
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  destination address="10.0.0.1"
  port port="8080" protocol="tcp"
  accept'
```

## ICMP Rules

```bash
# Block ping
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule protocol value="icmp"
  reject'

# Block ping only from a specific source
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="203.0.113.0/24"
  protocol value="icmp"
  reject'
```

## Forward Rules (NAT)

```bash
# Forward incoming traffic on port 8080 to internal host
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  forward-port port="8080" protocol="tcp" to-port="80" to-addr="10.0.0.5"'
```

## Managing Rich Rules

```bash
# List rich rules in a zone
sudo firewall-cmd --zone=public --list-rich-rules

# Remove a rich rule (repeat the same rule with --remove-rich-rule)
sudo firewall-cmd --zone=public --remove-rich-rule='
  rule family="ipv4"
  source address="203.0.113.5"
  drop'
```

## Priority

Rich rules are evaluated in order. If multiple rules match, the first one wins. Rules within a zone are evaluated in this order:

1. Port forwarding and masquerading
2. Rich rules (in order added)
3. Service and port rules
4. Zone target (default action)

## Permanent vs Runtime

Like all firewalld rules, rich rules default to **runtime**:

```bash
# Runtime (lost on reload)
sudo firewall-cmd --zone=public --add-rich-rule='rule service name="http" accept'

# Permanent
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule service name="http" accept'
sudo firewall-cmd --reload
```
