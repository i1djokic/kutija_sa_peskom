# Practical Examples

## Example 1: Basic Web Server

```bash
# Allow web traffic on public interface
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https

# Enable SSH (usually on by default in public zone)
sudo firewall-cmd --permanent --zone=public --add-service=ssh

# Apply
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --zone=public --list-all
```

## Example 2: SSH on a Non-Standard Port

If SSH runs on port 2222 instead of 22:

```bash
# Add custom port
sudo firewall-cmd --permanent --zone=public --add-port=2222/tcp

# Remove the standard SSH service (optional)
sudo firewall-cmd --permanent --zone=public --remove-service=ssh

sudo firewall-cmd --reload
```

Or create a custom service:

```bash
sudo firewall-cmd --permanent --new-service=custom-ssh
sudo firewall-cmd --permanent --service=custom-ssh --add-port=2222/tcp
sudo firewall-cmd --permanent --zone=public --add-service=custom-ssh
sudo firewall-cmd --reload
```

## Example 3: SSH Only from Office IP

Allow SSH from the office, block everyone else:

```bash
# Allow SSH from office subnet
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule family="ipv4"
  source address="203.0.113.0/24"
  service name="ssh"
  accept'

# Remove the wide-open SSH service
sudo firewall-cmd --permanent --zone=public --remove-service=ssh

sudo firewall-cmd --reload
```

## Example 4: Internal Network with Services

Multi-homed server with public and internal interfaces:

```bash
# Assign interfaces to zones
sudo firewall-cmd --permanent --zone=public --add-interface=eth0
sudo firewall-cmd --permanent --zone=internal --add-interface=eth1

# Public zone: only web and SSH
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --permanent --zone=public --add-service=ssh

# Internal zone: everything the team needs
sudo firewall-cmd --permanent --zone=internal --add-service=ssh
sudo firewall-cmd --permanent --zone=internal --add-service=mysql
sudo firewall-cmd --permanent --zone=internal --add-service=samba
sudo firewall-cmd --permanent --zone=internal --add-service=nfs

sudo firewall-cmd --reload
```

## Example 5: Docker Host

Docker manipulates iptables/nftables directly. Common practice is to keep the default zone and trust docker interfaces:

```bash
# Allow web ports on public zone
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https

# Trust Docker's network (if using custom bridge)
sudo firewall-cmd --permanent --zone=trusted --add-source=172.17.0.0/16

sudo firewall-cmd --reload
```

For Docker with firewalld, ensure `iptables=false` is NOT set in `/etc/docker/daemon.json` — Docker needs to manage its own rules within firewalld's integration.

## Example 6: Block All Traffic Except VPN

```bash
# Set default zone to drop
sudo firewall-cmd --set-default-zone=drop

# Allow VPN interface (tun0) in trusted zone
sudo firewall-cmd --permanent --zone=trusted --add-interface=tun0

# Allow the VPN server port (for initial connection)
sudo firewall-cmd --permanent --zone=drop --add-port=1194/udp

sudo firewall-cmd --reload
```

## Example 7: Rate Limit SSH to Prevent Brute Force

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule service name="ssh"
  log prefix="SSH_RATE" level="info" limit value="3/m"
  accept limit value="3/m"'
```

This logs up to 3 SSH connections per minute and accepts up to 3 per minute. Connections beyond the limit are dropped by the default zone target. For better rate limiting, use `fail2ban` alongside firewalld.

## Example 8: Logging Dropped Packets

Log all dropped packets in the public zone (for debugging):

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
  rule log prefix="DROP" level="info" limit value="1/m"'

sudo firewall-cmd --reload
```

View logs:

```bash
sudo journalctl -k | grep DROP
# or
sudo grep DROP /var/log/messages
```

## Example 9: Simple NAT Gateway

```bash
# Enable masquerading on the external zone
sudo firewall-cmd --permanent --zone=external --add-interface=eth0
sudo firewall-cmd --permanent --zone=external --add-masquerade

# Assign internal interface to internal zone
sudo firewall-cmd --permanent --zone=internal --add-interface=eth1

# Allow forwarding (sysctl)
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-forward.conf
sudo sysctl -p /etc/sysctl.d/99-forward.conf

sudo firewall-cmd --reload
```

## Example 10: Test a Rule Before Making Permanent

```bash
# 1. Add runtime rule
sudo firewall-cmd --add-rich-rule='rule service name="http" accept'

# 2. Test
curl http://localhost:80

# 3. If it works, make permanent
sudo firewall-cmd --runtime-to-permanent

# If it breaks, just reload to reset
sudo firewall-cmd --reload
```
