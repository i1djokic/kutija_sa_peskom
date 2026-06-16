# Networking & Diagnostics

## Ping Sweep

```bash
# Basic sweep (serial)
for ip in 192.168.1.{1..254}; do
    ping -c1 -W1 "$ip" &>/dev/null && echo "$ip up" || true
done

# Parallel (much faster)
for ip in 192.168.1.{1..254}; do
    (ping -c1 -W1 "$ip" &>/dev/null && echo "$ip up") &
done
wait
```

## Port Checking

```bash
# Using /dev/tcp (bash built-in)
check_port() {
    local host="$1" port="$2"
    timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null \
        && echo "$host:$port open" \
        || echo "$host:$port closed"
}

# Using nc
nc -zvw2 "$host" "$port"                    # quick check
nc -zv "$host" 22 80 443                    # check multiple ports

# Using ss (modern netstat)
ss -tlnp                                    # listening TCP with process
ss -tun                                     # all TCP/UDP connections
ss -tn state established                    # established connections only
```

## DNS Lookups

```bash
# Basic
dig example.com
dig -x 8.8.8.8                # reverse lookup
dig example.com MX            # mail records
dig example.com @1.1.1.1      # use specific resolver

# Short output
dig +short example.com
dig +short -x 8.8.8.8

# System resolver
host example.com
nslookup example.com

# Check DNS propagation
for ns in 8.8.8.8 1.1.1.1 9.9.9.9; do
    echo -n "$ns: "; dig +short @$ns example.com
done
```

## HTTP Headers & Debugging

```bash
# Fetch headers only
curl -sI https://example.com

# Full trace
curl -v https://example.com                       # verbose
curl --trace-ascii /dev/stdout https://example.com # full trace

# Measure timing
curl -s -w "\n---\nDNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" -o /dev/null https://example.com
```

## Traceroute & Path

```bash
# Standard
traceroute example.com

# Faster (parallel probes)
mtr example.com               # combines traceroute + ping

# Path MTU discovery
tracepath example.com
```

## Connection Monitoring

```bash
# Number of connections per state
ss -tan | awk '{print $1}' | sort | uniq -c

# Connections per IP
ss -tan | awk 'NR>1 {print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# Check for SYN flood (too many SYN_RECV)
syn_count=$(ss -tan state syn-recv | wc -l)
if (( syn_count > 100 )); then
    echo "WARNING: $syn_count SYN_RECV connections (possible flood)"
fi
```

## Bandwidth Monitoring

```bash
# Real-time (using /proc)
# Requires two samples
rx1=$(awk 'NR==3 {print $2}' /proc/net/dev)   # received bytes
sleep 1
rx2=$(awk 'NR==3 {print $2}' /proc/net/dev)
echo "Speed: $(( (rx2 - rx1) / 1024 )) KB/s"

# Using tools
iftop -n                                       # per-connection bandwidth
nload                                           # interface bandwidth
bmon                                           # bandwidth monitor
```

## Connectivity Test Script

```bash
network_check() {
    local fail=0

    # DNS
    host example.com &>/dev/null && echo "DNS: OK" || { echo "DNS: FAIL"; ((fail++)); }

    # Internet
    ping -c1 -W2 8.8.8.8 &>/dev/null && echo "Internet: OK" || { echo "Internet: FAIL"; ((fail++)); }

    # Local gateway
    local gw
    gw=$(ip route | awk '/default/ {print $3}')
    ping -c1 -W1 "$gw" &>/dev/null && echo "Gateway: OK" || { echo "Gateway: FAIL"; ((fail++)); }

    # Specific port
    nc -zvw2 example.com 443 &>/dev/null && echo "HTTPS: OK" || { echo "HTTPS: FAIL"; ((fail++)); }

    return "$fail"
}
```
