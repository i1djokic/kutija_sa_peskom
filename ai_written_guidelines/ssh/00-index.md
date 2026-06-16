# SSH Guide

Practical SSH documentation covering basics, key management, tunneling, remote mounts, and advanced use cases.

## Contents

| File | What it covers |
|------|----------------|
| [01-basics.md](./01-basics.md) | What is SSH, installing, basic connect syntax, ports |
| [02-key-management.md](./02-key-management.md) | Generating keys, key types, ssh-agent, adding to remote hosts |
| [03-configuration.md](./03-configuration.md) | ~/.ssh/config file, Host blocks, aliases, wildcards |
| [04-scp.md](./04-scp.md) | Secure copy — one-shot file transfers |
| [05-rsync.md](./05-rsync.md) | Incremental sync, backups, resuming transfers |
| [06-sftp.md](./06-sftp.md) | Interactive file browsing, transfer, and remote management |
| [07-port-forwarding.md](./07-port-forwarding.md) | Local (-L), remote (-R), dynamic (-D/SOCKS) tunnels |
| [08-jump-hosts.md](./08-jump-hosts.md) | ProxyJump, bastion hosts, multi-hop |
| [09-connection-multiplexing.md](./09-connection-multiplexing.md) | Reusing connections, ControlMaster, agent forwarding |
| [10-mounting-remote-folders.md](./10-mounting-remote-folders.md) | sshfs, mounting/unmounting, fstab, alternatives |
| [11-advanced-topics.md](./11-advanced-topics.md) | known_hosts, port knocking, escape sequences, scripting |
| [12-troubleshooting.md](./12-troubleshooting.md) | Permission errors, connection refused, verbose mode |

## Quick Start

```bash
# Connect to a server
ssh user@hostname

# Generate a key pair
ssh-keygen -t ed25519 -C "your@email.com"

# Copy the public key to a server
ssh-copy-id user@hostname

# Now connect without a password
ssh user@hostname
```

## Resources

- [OpenSSH Manual](https://man.openbsd.org/ssh)
- [ssh_config man page](https://man.openbsd.org/ssh_config)
