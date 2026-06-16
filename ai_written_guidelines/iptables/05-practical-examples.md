# Practical Examples

## Example 1: Basic Web Server Firewall

Allow SSH, HTTP, and HTTPS; drop everything else.

```bash
# Default policies
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH, HTTP, HTTPS
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# Drop invalid
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Log dropped packets (rate limited)
sudo iptables -A INPUT -j LOG --log-prefix "IPTABLES_DROP: " -m limit --limit 5/minute

# Save
sudo iptables-save > /etc/iptables/rules.v4
```

## Example 2: SSH from Office Only

Allow SSH only from a specific subnet, block all others.

```bash
sudo iptables -P INPUT DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH only from office
sudo iptables -A INPUT -p tcp --dport 22 -s 203.0.113.0/24 -m conntrack --ctstate NEW -j ACCEPT

# Optionally, log blocked SSH attempts
sudo iptables -A INPUT -p tcp --dport 22 -j LOG --log-prefix "SSH_BLOCKED: "
```

## Example 3: Rate Limit SSH

Prevent brute force by limiting connections.

```bash
sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH

sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
  -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
```

## Example 4: Simple NAT Gateway

```bash
# Enable forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl -p /etc/sysctl.d/99-forward.conf

# Masquerade traffic from internal network
sudo iptables -t nat -A POSTROUTING -o eth0 -s 10.0.0.0/24 -j MASQUERADE

# Allow forwarding
sudo iptables -A FORWARD -i eth1 -o eth0 -s 10.0.0.0/24 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o eth1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -P FORWARD DROP
```

## Example 5: Port Forwarding (DNAT)

Forward incoming traffic on port 8080 to an internal server at 10.0.0.5:80.

```bash
# DNAT — change destination to internal server
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 \
  -j DNAT --to-destination 10.0.0.5:80

# Allow forwarded traffic
sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 80 \
  -d 10.0.0.5 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Masquerade so the internal server sees traffic from the gateway, not the client
sudo iptables -t nat -A POSTROUTING -o eth1 -p tcp --dport 80 \
  -d 10.0.0.5 -j MASQUERADE
```

## Example 6: Transparent Proxy (REDIRECT)

Redirect all HTTP traffic to a local proxy (port 3128).

```bash
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 \
  -j REDIRECT --to-port 3128
```

## Example 7: Block an IP Address

```bash
sudo iptables -A INPUT -s 203.0.113.5 -j DROP

# Block a subnet
sudo iptables -A INPUT -s 203.0.113.0/24 -j DROP

# Block with logging
sudo iptables -A INPUT -s 203.0.113.5 -j LOG --log-prefix "BLOCKED: "
sudo iptables -A INPUT -s 203.0.113.5 -j DROP
```

## Example 8: Allow Ping but Block Everything Else

```bash
sudo iptables -P INPUT DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow ping
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
```

## Example 9: Multi-Port Service

Allow multiple ports for a service:

```bash
# Using multiport module
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443,8080,8443 \
  -m conntrack --ctstate NEW -j ACCEPT
```

## Example 10: Logging Before Drop

Log dropped traffic to aid debugging:

```bash
# Create LOG_DROP chain
sudo iptables -N LOG_DROP
sudo iptables -A LOG_DROP -j LOG --log-prefix "IPTABLES_DROP: " --log-level 4
sudo iptables -A LOG_DROP -j DROP

# Use it instead of -j DROP
sudo iptables -A INPUT -s 203.0.113.5 -j LOG_DROP
```

Watch logs:

```bash
sudo journalctl -k | grep IPTABLES_DROP
# or
sudo dmesg | tail -50
```
