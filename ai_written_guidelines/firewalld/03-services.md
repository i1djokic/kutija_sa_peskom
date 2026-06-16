# Services

A **service** is a named shortcut for one or more ports and protocols. Instead of remembering "tcp port 3306", you just use the `mysql` service.

## Listing Available Services

```bash
# List all predefined services
sudo firewall-cmd --get-services

# List services enabled in a zone
sudo firewall-cmd --zone=public --list-services

# View a service definition
sudo firewall-cmd --info-service=http
# http
#   ports: 80/tcp
#   protocols:
#   source-ports:
#   modules:
#   destination:
```

Predefined service definitions live in `/usr/lib/firewalld/services/`. Each is an XML file (e.g., `http.xml`).

## Common Services

| Service | Ports | Purpose |
|---------|-------|---------|
| `ssh` | 22/tcp | Secure Shell |
| `http` | 80/tcp | HTTP web traffic |
| `https` | 443/tcp | HTTPS web traffic |
| `dhcp` | 67/udp, 68/udp | DHCP client/server |
| `dns` | 53/tcp, 53/udp | DNS |
| `mysql` | 3306/tcp | MySQL/MariaDB |
| `postgresql` | 5432/tcp | PostgreSQL |
| `smtp` | 25/tcp | Mail submission |
| `smtps` | 465/tcp | Mail submission (SSL) |
| `imap` | 143/tcp | IMAP mail retrieval |
| `imaps` | 993/tcp | IMAP over SSL |
| `pop3s` | 995/tcp | POP3 over SSL |
| `nfs` | 2049/tcp | NFS file sharing |
| `samba` | 137-138/udp, 139,445/tcp | SMB/CIFS |
| `ftp` | 21/tcp | FTP control |

## Adding and Removing Services

```bash
# Add service to zone (runtime)
sudo firewall-cmd --zone=public --add-service=http

# Add service to zone (permanent)
sudo firewall-cmd --permanent --zone=public --add-service=http

# Remove a service
sudo firewall-cmd --permanent --zone=public --remove-service=http

# Apply permanent changes
sudo firewall-cmd --reload
```

If no `--zone` is specified, the default zone is used.

## Adding Ports Directly

When no service exists for your port, add the port by number:

```bash
# Add a single port (runtime)
sudo firewall-cmd --zone=public --add-port=3000/tcp

# Add a port range
sudo firewall-cmd --permanent --zone=public --add-port=3000-3010/tcp

# Add a UDP port
sudo firewall-cmd --permanent --zone=public --add-port=123/udp

# Remove a port
sudo firewall-cmd --permanent --zone=public --remove-port=3000/tcp

sudo firewall-cmd --reload
```

## Creating a Custom Service

For applications that need multiple ports or custom protocols, create a service file:

```bash
# Copy an existing service as a starting point
sudo cp /usr/lib/firewalld/services/http.xml /etc/firewalld/services/myapp.xml

# Or create from scratch
sudo firewall-cmd --permanent --new-service=myapp
```

Edit `/etc/firewalld/services/myapp.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>MyApp</short>
  <description>My custom application</description>
  <port protocol="tcp" port="9000"/>
  <port protocol="tcp" port="9001"/>
  <port protocol="udp" port="9000"/>
</service>
```

Then reload and use it:

```bash
sudo firewall-cmd --reload
sudo firewall-cmd --permanent --zone=public --add-service=myapp
sudo firewall-cmd --reload
```

## Port vs Service

Use a **service** when:
- The application needs multiple ports/protocols
- You manage multiple servers with the same app
- You want human-readable names

Use a **port** when:
- It's a one-off or temporary rule
- You're testing something
- No service file exists and creating one feels like overkill
