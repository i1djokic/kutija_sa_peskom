# Connection Multiplexing & Agent Forwarding

## Connection Multiplexing

Reuse a single SSH connection for multiple sessions, eliminating the TCP handshake and key exchange overhead.

Add to `~/.ssh/config`:

```sshconfig
Host *
    ControlMaster auto
    ControlPath ~/.ssh/control/%r@%h:%p
    ControlPersist 10m
```

```bash
mkdir -p ~/.ssh/control  # Create the control directory
```

### How It Works

| Setting | What it does |
|---------|-------------|
| `ControlMaster auto` | Automatically use a master connection if one exists |
| `ControlPath` | Where to store the shared connection socket |
| `ControlPersist 10m` | Keep the master connection alive 10 minutes after the last session closes |

### Behavior

- First connection opens a master connection (slightly slower)
- Subsequent connections to the same host reuse it (nearly instant)
- The master stays alive for 10 minutes after the last session closes

### Manual Control

```bash
# Close the master connection
ssh -O exit hostname

# Check status
ssh -O check hostname
```

## Agent Forwarding

Forward your local SSH agent so you can authenticate from the remote server using your local keys.

```bash
# Connect with agent forwarding
ssh -A user@hostname

# In config:
Host *
    ForwardAgent yes
```

### Security Warning

**Only use agent forwarding with servers you trust.** An administrator on the remote server could use your agent to authenticate elsewhere as you.

### Safer Alternative

Use `ProxyJump` instead of agent forwarding for reaching internal servers:

```bash
# No agent forwarding needed
ssh -J bastion user@internal
```
