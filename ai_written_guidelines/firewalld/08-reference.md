# Reference

## Quick Commands

| Command | What it does |
|---------|-------------|
| `sudo firewall-cmd --state` | Check if firewalld is running |
| `sudo firewall-cmd --get-active-zones` | Show zones with assigned interfaces |
| `sudo firewall-cmd --get-default-zone` | Show the default zone |
| `sudo firewall-cmd --set-default-zone=ZONE` | Change the default zone |
| `sudo firewall-cmd --zone=ZONE --list-all` | List all rules in a zone |
| `sudo firewall-cmd --list-all-zones` | List all zones with their rules |
| `sudo firewall-cmd --zone=ZONE --add-service=SVC` | Add a service (runtime) |
| `sudo firewall-cmd --zone=ZONE --remove-service=SVC` | Remove a service (runtime) |
| `sudo firewall-cmd --zone=ZONE --add-port=PORT/tcp` | Add a port (runtime) |
| `sudo firewall-cmd --zone=ZONE --remove-port=PORT/tcp` | Remove a port (runtime) |
| `sudo firewall-cmd --zone=ZONE --add-interface=IFACE` | Assign interface to zone (runtime) |
| `sudo firewall-cmd --zone=ZONE --add-source=CIDR` | Assign source to zone (runtime) |
| `sudo firewall-cmd --zone=ZONE --add-rich-rule='RULE'` | Add a rich rule (runtime) |
| `sudo firewall-cmd --zone=ZONE --list-rich-rules` | List rich rules |
| `sudo firewall-cmd --permanent --add-service=SVC` | Add a service permanently |
| `sudo firewall-cmd --runtime-to-permanent` | Save runtime config as permanent |
| `sudo firewall-cmd --reload` | Apply permanent config, keep connections |
| `sudo firewall-cmd --complete-reload` | Full reload, drop all connections |
| `sudo firewall-cmd --panic-on` | Emergency — drop all traffic |
| `sudo firewall-cmd --panic-off` | Disable panic mode |
| `sudo firewall-cmd --get-services` | List all known services |
| `sudo firewall-cmd --info-service=SVC` | Show service definition |
| `sudo firewall-cmd --lockdown-on` | Enable lockdown mode |
| `sudo firewall-cmd --direct --add-rule TABLE CHAIN NUM RULE` | Add a direct iptables rule |

## Zone Reference

| Zone | Trust | Default services |
|------|-------|-----------------|
| `drop` | None | (none) — all dropped |
| `block` | None | (none) — all rejected |
| `public` | Low | `ssh`, `dhcpv6-client` |
| `external` | Low | `ssh` (with masquerading) |
| `dmz` | Low-Moderate | `ssh` |
| `work` | Moderate | `ssh`, `dhcpv6-client` |
| `home` | Moderate-High | `ssh`, `mdns`, `samba-client`, `dhcpv6-client` |
| `internal` | High | `ssh`, `mdns`, `samba-client`, `dhcpv6-client` |
| `trusted` | Full | (all accepted) |

## Common Services

| Service | Port |
|---------|------|
| `ssh` | 22/tcp |
| `http` | 80/tcp |
| `https` | 443/tcp |
| `dns` | 53/tcp, 53/udp |
| `dhcp` | 67/udp, 68/udp |
| `mysql` | 3306/tcp |
| `postgresql` | 5432/tcp |
| `smtp` | 25/tcp |
| `samba` | 137-138/udp, 139,445/tcp |
| `nfs` | 2049/tcp |
| `ftp` | 21/tcp |

## Rich Rule Elements

```
rule [family="ipv4|ipv6"]
  [source [address="ADDR" [invert="True"]] [mac="MAC"] [ipset="IPSET"]]
  [destination [address="ADDR" [invert="True"]]]
  [service name="NAME"]
  [port port="NUM" protocol="tcp|udp"]
  [protocol value="PROTO"]
  [icmp-block name="NAME"]
  [forward-port port="NUM" protocol="tcp|udp" to-port="NUM" to-addr="ADDR"]
  [log [prefix="TEXT"] [level="emerg|alert|crit|error|warn|notice|info|debug"] [limit value="RATE/DURATION"]]
  [audit]
  [accept|reject|drop]
```

## Port Forwarding Syntax

```
# Local
port=PORT:proto=tcp|udp:toport=PORT

# Remote (needs masquerade)
port=PORT:proto=tcp|udp:toport=PORT:toaddr=IP

# Rich rule version
forward-port port="PORT" protocol="tcp|udp" to-port="PORT" to-addr="IP"
```

## ICMP Types

| Name | Description |
|------|-------------|
| `echo-request` | Ping |
| `echo-reply` | Ping reply |
| `destination-unreachable` | Host/net unreachable |
| `source-quench` | Congestion control |
| `time-exceeded` | TTL exceeded (traceroute) |
| `parameter-problem` | Header error |
| `timestamp-request` | Timestamp query |
| `timestamp-reply` | Timestamp reply |
| `address-mask-request` | Subnet mask query |
| `address-mask-reply` | Subnet mask reply |
| `router-solicitation` | Router discovery |
| `router-advertisement` | Router announcement |

## Direct Rule Table Reference

| Table | Chains | Purpose |
|-------|--------|---------|
| `filter` | INPUT, FORWARD, OUTPUT | Packet filtering (default) |
| `nat` | PREROUTING, POSTROUTING, INPUT, OUTPUT | Network address translation |
| `mangle` | PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING | Packet header modification |

## Important Paths

| Path | Purpose |
|------|---------|
| `/etc/firewalld/` | User configuration (overrides defaults) |
| `/etc/firewalld/zones/` | Zone definitions |
| `/etc/firewalld/services/` | Custom service definitions |
| `/usr/lib/firewalld/` | Distro-provided defaults (do not edit) |
| `/usr/lib/firewalld/services/` | Predefined services |
| `/usr/lib/firewalld/zones/` | Default zone files |
