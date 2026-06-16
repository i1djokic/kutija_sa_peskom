# Port Forwarding (Tunneling)

SSH tunneling forwards network traffic through an encrypted SSH connection. This lets you access remote services securely or bypass firewalls.

## Local Forwarding

Forward a port on your local machine to a remote destination through the SSH server.

```bash
# Syntax: ssh -L local_port:destination:destination_port user@ssh-server

# Example: Access a database on a private server through a bastion
ssh -L 5432:db.internal:5432 user@bastion.example.com
# Now connect your local app to localhost:5432 — it reaches db.internal:5432

# Example: Access an internal web app
ssh -L 8080:internal-web:80 user@bastion.example.com
# Open http://localhost:8080 in your browser

# In config file (~/.ssh/config):
Host tunnel
    HostName bastion.example.com
    User user
    LocalForward 5432 db.internal:5432
    LocalForward 8080 internal-web:80
```

```
Your Machine            SSH Server          Target
:5432  ────encrypted───>  bastion  ────>  db.internal:5432
```

## Remote Forwarding

Forward a port on the remote SSH server to a destination on your local network.

```bash
# Syntax: ssh -R remote_port:local_destination:local_port user@ssh-server

# Example: Expose your local dev server to the internet via a public server
ssh -R 8080:localhost:3000 user@public-server.com
# Now anyone accessing public-server.com:8080 reaches your local port 3000

# Example: Let a colleague access your local machine
ssh -R 2222:localhost:22 user@public-server.com
# They can then: ssh -p 2222 localhost (from the public server, which forwards to your SSH)
```

```
Your Machine            SSH Server          Internet
localhost:3000  <────  public-server:8080  <── anyone
```

## Dynamic Forwarding (SOCKS Proxy)

Create a SOCKS proxy that tunnels all traffic through the SSH server.

```bash
# Syntax: ssh -D local_port user@ssh-server

# Start a SOCKS proxy on localhost:1080
ssh -D 1080 user@ssh-server

# Configure your browser to use SOCKS proxy:
#   Protocol: SOCKS v5
#   Host: localhost
#   Port: 1080
```

Now all browser traffic flows through the SSH server. This is useful for:
- Bypassing network restrictions
- Accessing region-locked content
- Securing traffic on untrusted networks (e.g., public WiFi)

## Common Tunnel Use Cases

### Access a remote database

```bash
# The database only listens on localhost (secure)
ssh -L 3306:localhost:3306 user@db-server
# Connect: mysql -h localhost -P 3306
```

### Access an internal service through a jump host

```bash
# Two hops: your machine -> bastion -> internal-server
ssh -L 9000:internal-server:9000 user@bastion
```

### Reverse tunnel for a webhook

```bash
# Expose local port 80 to a public server
ssh -R 8080:localhost:80 user@public-server
# Configure webhook -> http://public-server:8080
```

## Important Notes

- `localhost` in the tunnel destination is relative to the SSH server, not your machine
- Tunnels stay open as long as the SSH session is alive
- Use `-N` to open a tunnel without starting a shell: `ssh -N -L 5432:db:5432 user@host`
- Use `-f` to background the SSH session: `ssh -f -N -L 5432:db:5432 user@host`
