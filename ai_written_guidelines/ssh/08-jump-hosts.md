# Jump Hosts

Reach an internal server by hopping through a public-facing bastion (jump) host.

## ProxyJump (Modern, Recommended)

```bash
# One hop
ssh -J bastion.example.com user@internal-server

# Multiple hops
ssh -J jump1,jump2 user@target

# With different users on different hops
ssh -J user1@bastion user2@internal
```

### Config File

```sshconfig
Host internal
    HostName 10.0.1.50
    User myuser
    ProxyJump bastion.example.com
```

Now just `ssh internal` automatically hops through the bastion.

## Legacy ProxyCommand

On older SSH versions without `ProxyJump`:

```bash
ssh -o ProxyCommand="ssh -W %h:%p bastion.example.com" user@internal-server
```

## Tunneling Through a Jump Host

Combine with port forwarding to reach services on the internal network:

```bash
ssh -J bastion.example.com -L 5432:db.internal:5432 user@internal-server
```

## Security

- Jump hosts often have strict logging and access controls
- No need for agent forwarding — ProxyJump handles authentication hop-by-hop
- Each hop can use different keys or authentication methods
