# SSH Basics

## What is SSH?

SSH (Secure Shell) is a protocol for securely connecting to remote machines over an encrypted network. It provides:

- Remote shell access (like a terminal on the remote machine)
- File transfer (scp, rsync, sftp)
- Port forwarding / tunneling
- Remote command execution

## Installing SSH

### macOS / Linux
SSH client is usually pre-installed. To check:

```bash
ssh -V
```

If missing on Linux:

```bash
sudo apt install openssh-client   # Debian/Ubuntu
sudo dnf install openssh-clients  # Fedora
```

### Windows (10/11)
OpenSSH Client is available via:

```bash
# Optional Features > Add "OpenSSH Client"
# Or via PowerShell as admin:
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

## Basic Connection Syntax

```bash
ssh user@hostname
ssh user@hostname -p 2222       # Non-default port (default is 22)
ssh -i ~/.ssh/mykey user@host   # Use a specific private key

# Run a single command on the remote and exit
ssh user@hostname "ls -la /var/log"

# With port forwarding (see 07-port-forwarding.md)
ssh -L 8080:localhost:80 user@hostname
```

## Common Host Formats

```bash
ssh user@192.168.1.10            # IP address
ssh user@server.example.com      # Domain name
ssh user@server.local            # Local network hostname
ssh server                       # If configured in ~/.ssh/config
```

## SSH Port

- Default port: `22`
- Change with `-p <port>` or via config file
- Many servers use non-default ports to reduce automated attacks

## Exit a Session

```bash
exit          # End the SSH session
logout        # Same thing
Ctrl+D        # Shortcut
```
