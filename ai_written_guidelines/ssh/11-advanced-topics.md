# Advanced Topics

## Checking Host Keys (known_hosts)

The first time you connect to a server, SSH records its host key fingerprint in `~/.ssh/known_hosts`. If the fingerprint changes later (e.g., the server was re-installed), SSH warns you.

```bash
# Pre-fetch a host key (useful for automation)
ssh-keyscan -H hostname >> ~/.ssh/known_hosts

# Verify a key fingerprint manually
ssh-keyscan hostname | ssh-keygen -lf -

# Remove a host key that changed
ssh-keygen -R hostname
```

## SSH Config: Bundled Example

A practical `~/.ssh/config` block combining multiple features:

```sshconfig
Host dev
    HostName dev.example.com
    User developer
    IdentityFile ~/.ssh/dev-key
    LocalForward 3000 localhost:3000    # Forward local :3000 to dev's :3000
    LocalForward 9229 localhost:9229    # Debugger port
    ServerAliveInterval 30              # Keep connection alive
```

## Port Knocking

A technique where a firewall keeps ports closed until a sequence of connection attempts (knocks) is made.

```bash
# Example: knock on ports 7000, 8000, 9000 to open SSH
knock server.example.com 7000 8000 9000
ssh user@server.example.com
```

Requires a `knock` client and a port knocking daemon on the server.

## SSH Escape Sequences

From within an active SSH session, these commands start with `~` (press Enter, then `~` + key):

| Sequence | Action |
|----------|--------|
| `~.` | Terminate the connection (if frozen) |
| `~Ctrl+Z` | Suspend the SSH session (then `fg` to resume) |
| `~C` | Open a command line to modify port forwarding |

## Using SSH in Scripts

```bash
# Run a command over SSH
ssh user@host "systemctl restart nginx"

# With a specific key
ssh -i ~/.ssh/deploy-key user@host "deploy.sh"

# Capture remote output
remote_output=$(ssh user@host "cat /etc/hostname")

# Check if SSH is reachable
if ssh -q user@host exit; then
    echo "Server is reachable"
fi
```
