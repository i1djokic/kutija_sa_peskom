# SSH Configuration

The `~/.ssh/config` file defines per-host settings so you don't have to type flags every time.

## Basic Structure

```sshconfig
Host myserver
    HostName 192.168.1.10
    User myuser
    Port 2222
    IdentityFile ~/.ssh/mykey
```

Now you can just type `ssh myserver` instead of `ssh myuser@192.168.1.10 -p 2222 -i ~/.ssh/mykey`.

## Common Directives

| Directive | What it does |
|-----------|-------------|
| `HostName` | The actual hostname or IP |
| `User` | Login username |
| `Port` | SSH port (default: 22) |
| `IdentityFile` | Path to the private key |
| `ForwardAgent` | Enable agent forwarding (yes/no) |
| `LocalForward` | Set up local port forwarding |
| `RemoteForward` | Set up remote port forwarding |
| `ProxyJump` | Jump through another host |
| `ServerAliveInterval` | Keep connection alive (seconds) |

## Examples

### Simple alias

```sshconfig
Host prod
    HostName prod.example.com
    User deploy
    IdentityFile ~/.ssh/prod-key
```

### With port forwarding baked in

```sshconfig
Host db-tunnel
    HostName bastion.example.com
    User admin
    LocalForward 5432 db.internal:5432
```

Now `ssh db-tunnel` connects to the bastion and forwards port 5432.

### Jump host

```sshconfig
Host internal
    HostName 10.0.1.50
    User myuser
    ProxyJump bastion.example.com
```

### Wildcards

```sshconfig
# Apply to all *.internal hosts
Host *.internal
    User admin
    IdentityFile ~/.ssh/internal-key

# Apply to all hosts (defaults)
Host *
    ServerAliveInterval 60
    ForwardAgent no
```

## Permissions

SSH is strict about file permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519      # Private key
chmod 644 ~/.ssh/id_ed25519.pub  # Public key
chmod 644 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts
```
