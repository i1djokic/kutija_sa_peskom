# Networking — DevOps Cheatsheet

## OSI Model

| Layer | Name | Example |
|-------|------|---------|
| 7 | Application | HTTP, DNS, SSH |
| 4 | Transport | TCP, UDP |
| 3 | Network | IP, ICMP |
| 2 | Data Link | Ethernet, ARP |
| 1 | Physical | cables, signals |

*Memorise by mnemonics: "Please Do Not Throw Sausage Pizza Away" (7→1)*

## TCP vs UDP

| | TCP | UDP |
|--|-----|-----|
| Connection | connection-oriented | connectionless |
| Reliability | guaranteed delivery | best-effort |
| Ordering | in-order | unordered |
| Speed | slower | faster |
| Use cases | HTTP, SSH, SQL | DNS, VoIP, streaming |

## IP Addressing

```
10.0.0.0/8       — private (big)
172.16.0.0/12    — private (medium)
192.168.0.0/16   — private (small)
127.0.0.0/8      — loopback
169.254.0.0/16   — link-local (APIPA)

CIDR:  192.168.1.0/24  → mask 255.255.255.0 → 254 hosts
/24 = 256 IPs, /16 = 65536, /8 = 16M, /32 = 1
```

## Common Ports

| Port | Protocol |
|------|----------|
| 22 | SSH |
| 80 | HTTP |
| 443 | HTTPS |
| 53 | DNS |
| 25 | SMTP |
| 3306 | MySQL |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 27017 | MongoDB |
| 8080 | HTTP alt / proxy |
| 8443 | HTTPS alt |
| 6443 | Kubernetes API |
| 2379-2380 | etcd |
| 10250 | Kubelet |
| 30000-32767 | NodePort range |

## DNS

```
A     → IPv4
AAAA  → IPv6
CNAME → alias
MX    → mail server
TXT   → arbitrary text
NS    → name server
SOA   → zone authority
SRV   → service location
PTR   → reverse lookup
```

### Resolution Order
1. Local cache
2. `/etc/hosts`
3. DNS resolver → root → TLD → authoritative

### Common Commands
```bash
dig example.com A +short
nslookup example.com
host example.com
resolvectl status
```

## HTTP

### Methods
| Method | Purpose |
|--------|---------|
| GET | read |
| POST | create |
| PUT | replace |
| PATCH | partial update |
| DELETE | delete |

### Status Codes

| Range | Meaning |
|-------|---------|
| 1xx | informational |
| 2xx | success (200 OK, 201 Created) |
| 3xx | redirect (301 moved, 304 not modified) |
| 4xx | client error (400 bad request, 401 unauth, 403 forbidden, 404 not found) |
| 5xx | server error (500 internal, 502 bad gateway, 503 unavailable, 504 timeout) |

### Headers (common)
```
Cache-Control: no-cache
Content-Type: application/json
Authorization: Bearer <token>
X-Forwarded-For: client-ip
X-Real-IP: client-ip
```

## SSL/TLS

```
Handshake:
1. ClientHello → ciphers + TLS version
2. ServerHello → cert + chosen cipher
3. ClientKeyExchange → pre-master secret
4. Certificate Verify (mutual TLS)
5. ChangeCipherSpec → encrypted comms
```

```bash
openssl s_client -connect example.com:443 -servername example.com
echo | openssl s_client -showcerts -connect example.com:443 2>/dev/null \
  | openssl x509 -noout -text
```

## Load Balancing

| Algorithm | Behaviour |
|-----------|-----------|
| Round Robin | sequential |
| Least Connections | fewest active |
| IP Hash | consistent source IP |
| Weighted | proportional |

### Proxy Types

| Type | Behaviour |
|------|-----------|
| Forward Proxy | client → proxy → internet |
| Reverse Proxy | internet → proxy → backend |
| Transparent | invisible, no config needed |

## Common Commands

```bash
# Connectivity
ping -c 4 google.com
traceroute google.com           # trace path
mtr google.com                  # combined ping + traceroute
nc -zv host 443                 # port reachable
nc -l 8080                      # listen on port
telnet host 443                 # raw connection

# DNS
dig example.com ANY +short
dig -x 8.8.8.8                  # reverse lookup
nslookup example.com

# HTTP
curl -v http://example.com      # full request/response
curl -I https://example.com     # headers only
curl -X POST -H "Content-Type: application/json" -d '{"k":"v"}' url
curl -o /dev/null -s -w "%{http_code}\n" https://example.com
curl -w "@curl-format.txt" -o /dev/null -s url   # timing (connect, TTFB, total)

# Routes & ARP
ip addr                          # interfaces + IPs
ip route                         # routing table
ip neigh                         # ARP table
ss -tulpn                        # listening sockets (alternative to netstat)
ss -tnp                          # established connections

# Firewall (iptables / nftables)
sudo iptables -L -n -v
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -j DROP

# Bandwidth
iperf3 -s                        # server
iperf3 -c host                   # client
nload                             # real-time bandwidth
iftop                             # per-connection bandwidth

# Packet capture
tcpdump -i eth0 port 80 -n
tcpdump -i any -c 100 -w dump.pcap
tshark -r dump.pcap
ngrep -d eth0 port 80

# Performance
ss -ti                           # TCP info (cwnd, rtt)
ip route show cache
```

## AWS Networking (VPC)

| Component | Purpose |
|-----------|---------|
| VPC | virtual network CIDR |
| Subnet | AZ-scoped IP range (public/private) |
| Route Table | network routing rules |
| IGW | internet gateway |
| NAT Gateway | outbound from private subnet |
| SG | stateful instance firewall |
| NACL | stateless subnet firewall |
| VPC Peering | connect VPCs |
| Transit Gateway | hub-and-spoke |
| VPN | site-to-site / client |
| Direct Connect | dedicated physical link |
| ELB / ALB / NLB | load balancer |
| Route53 | DNS |

## Troubleshooting Flow

```
1. Ping → reachable?
2. DNS → resolves?
3. Traceroute → where does it stop?
4. Port (nc) → listening?
5. Firewall (iptables/SG) → blocked?
6. App logs → error?
```

## Key Concepts

| Concept | Definition |
|---------|------------|
| Latency | time to deliver packet |
| Throughput | data per second |
| Bandwidth | max data capacity |
| MTU | max packet size (1500 typical) |
| RTT | round-trip time |
| TTL | max hops (default 64/128) |
| NAT | translate private → public IP |
| SNAT/DNAT | source/dest NAT |
| Stateful | tracks connections (SG) |
| Stateless | checks each packet (NACL) |
