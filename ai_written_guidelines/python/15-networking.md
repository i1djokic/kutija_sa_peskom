# Networking

## socket module

```python
import socket

# TCP client
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(5)
try:
    sock.connect(("example.com", 80))
    sock.sendall(b"GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
    response = sock.recv(4096)
finally:
    sock.close()
```

### TCP server

```python
import socket

def tcp_server(host: str = "0.0.0.0", port: int = 9999) -> None:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(5)
    log.info("Listening on %s:%s", host, port)

    while True:
        client, addr = server.accept()
        with client:
            log.info("Connection from %s", addr)
            data = client.recv(1024)
            client.sendall(b"ACK: " + data)
```

### Port checker

```python
import socket

def port_open(host: str, port: int, timeout: float = 2.0) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        return sock.connect_ex((host, port)) == 0

# Scan common ports
for port in [22, 80, 443, 8080, 5432]:
    status = "open" if port_open("localhost", port) else "closed"
    print(f"Port {port}: {status}")
```

### DNS resolution

```python
import socket

ip = socket.gethostbyname("example.com")
print(ip)  # "93.184.216.34"

# All IPs
ips = socket.gethostbyname_ex("example.com")
print(ips)  # ('example.com', [], ['93.184.216.34'])

# Reverse DNS
host = socket.gethostbyaddr("93.184.216.34")
print(host[0])  # "example.com"
```

## Creating a simple TCP health check

```python
import socket
import time

def tcp_health_check(host: str, port: int, timeout: float = 5.0) -> bool:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return True
    except (TimeoutError, ConnectionRefusedError, OSError):
        return False

def wait_for_port(host: str, port: int, timeout: float = 30.0, interval: float = 1.0) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if tcp_health_check(host, port):
            return True
        time.sleep(interval)
    return False
```

## HTTP server (stdlib)

```python
from http.server import HTTPServer, BaseHTTPRequestHandler

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status": "ok"}')
        else:
            self.send_response(404)
            self.end_headers()

server = HTTPServer(("0.0.0.0", 8080), HealthHandler)
log.info("Starting health server...")
server.serve_forever()
```

## URL parsing

```python
from urllib.parse import urlparse, urljoin, parse_qs

url = urlparse("https://user:pass@api.example.com:8443/path?key=val&page=1#section")
print(url.scheme)    # "https"
print(url.hostname)  # "api.example.com"
print(url.port)      # 8443
print(url.path)      # "/path"
print(url.query)     # "key=val&page=1"

params = parse_qs(url.query)
print(params)        # {"key": ["val"], "page": ["1"]}

# Join URLs
full = urljoin("https://api.example.com/v1", "/health")
```

## SSL/TLS context

```python
import ssl
import socket

# Secure socket
context = ssl.create_default_context()
with socket.create_connection(("example.com", 443)) as sock:
    with context.wrap_socket(sock, server_hostname="example.com") as secure:
        secure.sendall(b"GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
        response = secure.read(4096)

# Get certificate info
cert = secure.getpeercert()
print(cert.get("subject"))
print(cert.get("notAfter"))
```

## IP address handling (ipaddress module)

```python
import ipaddress

# Validate
ip = ipaddress.ip_address("192.168.1.1")
print(ip.is_private)    # True
print(ip.is_loopback)   # False

# Network
net = ipaddress.ip_network("192.168.1.0/24", strict=False)
for host in net.hosts():
    print(host)  # 192.168.1.1 ... 192.168.1.254

# CIDR check
net = ipaddress.ip_network("10.0.0.0/8")
if ipaddress.ip_address("10.1.2.3") in net:
    print("in range")
```

## ICMP ping (via subprocess)

```python
import subprocess

def ping(host: str, count: int = 3) -> bool:
    result = subprocess.run(
        ["ping", "-c", str(count), "-W", "2", host],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0
```

## mDNS / service discovery (zeroconf)

```python
# pip install zeroconf
from zeroconf import Zeroconf, ServiceBrowser

def on_service_change(zeroconf, service_type, name, state_change):
    print(f"{state_change}: {name}")

zc = Zeroconf()
browser = ServiceBrowser(zc, "_http._tcp.local.", handlers=[on_service_change])
```
