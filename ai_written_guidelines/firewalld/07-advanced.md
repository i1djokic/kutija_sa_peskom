# Advanced Topics

## Masquerading (NAT)

Masquerading hides internal IPs behind the firewall's IP (source NAT). Used for sharing a single public IP with multiple internal machines.

```bash
# Enable masquerade on a zone
sudo firewall-cmd --permanent --zone=public --add-masquerade

# Check if masquerade is enabled
sudo firewall-cmd --zone=public --query-masquerade

# Remove masquerade
sudo firewall-cmd --permanent --zone=public --remove-masquerade

sudo firewall-cmd --reload
```

Typically used on the `external` zone for a NAT gateway.

## Port Forwarding

Forward incoming traffic on one port/address to another internal host.

### Local Forwarding (same host)

Forward port 8080 to port 80 on the same machine:

```bash
sudo firewall-cmd --permanent --zone=public --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --reload
```

### Remote Forwarding (different host)

Forward port 8080 to another machine (masquerading must be enabled):

```bash
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --permanent --zone=public --add-forward-port=port=8080:proto=tcp:toport=80:toaddr=10.0.0.5
sudo firewall-cmd --reload
```

### Rich Rule Forwarding

Equivalent with rich rules:

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  forward-port port="8080" protocol="tcp" to-port="80" to-addr="10.0.0.5"'
sudo firewall-cmd --reload
```

## ICMP Blocking

Firewalld can block specific ICMP types (ping, traceroute, etc.).

```bash
# List known ICMP types
sudo firewall-cmd --get-icmptypes

# Block ping (echo-request) in a zone
sudo firewall-cmd --permanent --zone=public --add-icmp-block=echo-request

# Block all ICMP
sudo firewall-cmd --permanent --zone=public --add-icmp-block=echo-request
sudo firewall-cmd --permanent --zone=public --add-icmp-block=echo-reply
sudo firewall-cmd --permanent --zone=public --add-icmp-block=timestamp-request

# Check ICMP blocks
sudo firewall-cmd --zone=public --list-icmp-blocks

# Remove ICMP block
sudo firewall-cmd --permanent --zone=public --remove-icmp-block=echo-request

sudo firewall-cmd --reload
```

## IP Sets

IP sets group addresses/subnets into a named set for use in rules.

```bash
# Create an IP set
sudo firewall-cmd --permanent --new-ipset=office --type=hash:net

# Add entries
sudo firewall-cmd --permanent --ipset=office --add-entry=203.0.113.0/24
sudo firewall-cmd --permanent --ipset=office --add-entry=198.51.100.0/24

# Use in a rich rule
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source ipset="office"
  service name="ssh"
  accept'

sudo firewall-cmd --reload
```

IP set types:
- `hash:ip` — list of individual IPs
- `hash:net` — list of subnets
- `hash:ip,port` — IP+port combos
- `hash:net,port` — subnet+port combos

## Lockdown Mode

When lockdown is enabled, only processes on a whitelist can modify firewalld rules. This prevents unauthorized applications from changing the firewall.

```bash
# Enable lockdown
sudo firewall-cmd --lockdown-on

# Check status
sudo firewall-cmd --query-lockdown

# Disable
sudo firewall-cmd --lockdown-off
```

The whitelist is in `/etc/firewalld/lockdown-whitelist.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<whitelist>
  <command name="/usr/bin/firewall-cmd"/>
  <command name="/usr/sbin/iptables"/>
  <selinux context="system_u:system_r:firewalld_t:s0"/>
  <user id="0"/>
</whitelist>
```

## Direct Rules

Direct rules are raw iptables/nftables rules passed through firewalld without translation. They bypass the zone/service model entirely.

```bash
# Add a direct rule (iptables syntax)
sudo firewall-cmd --direct --add-rule ipv4 filter INPUT 0 -s 10.0.0.0/24 -j ACCEPT

# List direct rules
sudo firewall-cmd --direct --get-all-rules

# Remove a direct rule
sudo firewall-cmd --direct --remove-rule ipv4 filter INPUT 0 -s 10.0.0.0/24 -j ACCEPT
```

Direct rules are an **escape hatch**. Prefer zones, services, and rich rules when possible. Direct rules bypass firewalld's integration with nftables and may conflict with management tools.

## Zone Configuration Files

Each zone is stored as an XML file. Example `/etc/firewalld/zones/public.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas. ...</description>
  <service name="ssh"/>
  <service name="dhcpv6-client"/>
  <masquerade/>
  <forward-port port="8080" protocol="tcp" to-port="80"/>
  <rule family="ipv4">
    <source address="10.0.0.0/24"/>
    <service name="http"/>
    <accept/>
  </rule>
</zone>
```

## Logging and Debugging

```bash
# Check firewalld service status
sudo systemctl status firewalld

# Watch firewalld logs
sudo journalctl -u firewalld -f

# List all runtime rules (shows the nftables/iptables rules firewalld generated)
sudo firewall-cmd --list-all-zones
```
