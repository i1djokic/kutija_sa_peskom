# Zones

A zone defines the trust level for traffic arriving on an interface or from a source.

## Predefined Zones

Firewalld ships with these zones (from most restrictive to least):

| Zone | Trust level | Typical use |
|------|-------------|-------------|
| `drop` | **None** | All incoming packets dropped (no reply). Only outgoing traffic. |
| `block` | **None** | All incoming packets rejected (reply with icmp-host-prohibited). |
| `public` | **Low** | Untrusted public networks (default). Only allow what you explicitly open. |
| `external` | **Low** | External network with masquerading (NAT). For routers/gateways. |
| `dmz` | **Low-Moderate** | DMZ — publicly accessible but isolated from internal networks. |
| `work` | **Moderate** | Work environment — more trusted than public. |
| `home` | **Moderate-High** | Home network — trust some services by default. |
| `internal` | **High** | Internal LAN — trust most common services. |
| `trusted` | **Full** | All traffic accepted. Use for internal trusted segments. |

## Default Zone

The default zone applies to interfaces not explicitly assigned to another zone:

```bash
# Check default zone
sudo firewall-cmd --get-default-zone

# Change default zone
sudo firewall-cmd --set-default-zone=internal
```

Changing the default zone affects all interfaces currently using "default" assignment.

## Assigning Interfaces

```bash
# Check which zone an interface is in
sudo firewall-cmd --get-zone-of-interface=eth0

# Assign interface to a zone
sudo firewall-cmd --zone=public --add-interface=eth0

# Permanent assignment
sudo firewall-cmd --permanent --zone=public --add-interface=eth0
sudo firewall-cmd --reload
```

An interface can only belong to **one zone**.

## Assigning Sources (IP-based)

Instead of by interface, you can assign source IP ranges to a zone:

```bash
# Trust a specific subnet
sudo firewall-cmd --zone=trusted --add-source=10.0.0.0/24

# Assign a single IP to the internal zone
sudo firewall-cmd --zone=internal --add-source=192.168.1.100
```

Sources can override zone assignment: traffic from `10.0.0.0/24` hitting any interface will use the `trusted` zone rules.

## Listing Zones

```bash
# List all zones with their rules
sudo firewall-cmd --list-all-zones

# List a single zone
sudo firewall-cmd --zone=public --list-all

# Find the zone a specific interface is in
sudo firewall-cmd --get-zone-of-interface=eth0

# Show which zones are active (have interfaces/sources)
sudo firewall-cmd --get-active-zones
```

## Zone Target

Each zone has a **target** that defines the default action for unmatched traffic:

```bash
sudo firewall-cmd --zone=public --list-all
# target: default
```

| Target | Effect |
|--------|--------|
| `default` | Accept packets matching services/ports/rich-rules; drop or reject the rest based on zone |
| `ACCEPT` | Accept all packets (like `trusted` zone) |
| `DROP` | Drop unmatched packets |
| `REJECT` | Reject unmatched packets |

## Creating Custom Zones

```bash
# Create a new zone
sudo firewall-cmd --permanent --new-zone=myzone
sudo firewall-cmd --reload

# Add rules to it
sudo firewall-cmd --permanent --zone=myzone --add-service=ssh
sudo firewall-cmd --permanent --zone=myzone --add-port=9000/tcp
sudo firewall-cmd --reload
```

Custom zone files are stored in `/etc/firewalld/zones/`.
