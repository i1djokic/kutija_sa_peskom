# Troubleshooting SSH

## Permission Denied

### "Permission denied (publickey)"

- The server doesn't have your public key. Run: `ssh-copy-id user@hostname`
- Wrong key is being used. Specify the correct one: `ssh -i ~/.ssh/mykey user@host`
- Private key has wrong permissions: `chmod 600 ~/.ssh/id_ed25519`

### "Bad permissions"

SSH requires strict permissions on `~/.ssh/`:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519      # Any private key
chmod 644 ~/.ssh/id_ed25519.pub  # Any public key
chmod 644 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts
```

### "Server refused our key"

- The server's `~/.ssh/authorized_keys` has wrong permissions: `chmod 600 ~/.ssh/authorized_keys`
- The home directory is too permissive: `chmod 755 ~` (not 777)
- SELinux is blocking SSH: `restorecon -R -v ~/.ssh`

## Connection Refused

```bash
ssh: connect to host hostname port 22: Connection refused
```

- SSH server isn't running: `sudo systemctl status sshd`
- Firewall is blocking port 22: `sudo ufw status`
- Wrong port: try `ssh -p <port> user@hostname`
- Server is not reachable: `ping hostname`

## Connection Hangs / Times Out

```bash
ssh: connect to host hostname port 22: Connection timed out
```

- Network issue: check `ping hostname`
- Firewall is dropping the connection (not refusing)
- Wrong IP/hostname

## Host Key Changed Warning

```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

This means the remote server's host key doesn't match what's in `~/.ssh/known_hosts`. Possible causes:

- The server was reinstalled (legitimate)
- A malicious actor is intercepting your connection (man-in-the-middle)

If you're sure it's legitimate (e.g., you re-installed the server):

```bash
ssh-keygen -R hostname    # Remove the old key
ssh user@hostname         # Connect again and accept the new key
```

## Verbose Mode

Add `-v` (or `-vv`, `-vvv`) to see detailed debug output:

```bash
ssh -vvv user@hostname
```

This shows:
- Which keys are being tried
- Where SSH is looking for config
- What the server is responding
- Where authentication is failing

## SSH Agent Not Found

```bash
# Start the agent
eval "$(ssh-agent -s)"

# Check if agent is running
ssh-add -l
```

On macOS, add to `~/.ssh/config`:

```sshconfig
Host *
    AddKeysToAgent yes
    UseKeychain yes
```

## Slow Connections

- **DNS lookup delay:** `ssh -o GSSAPIAuthentication=no user@hostname`
- **Config fix for slow logins:**

```sshconfig
Host *
    GSSAPIAuthentication no
    ControlMaster auto
    ControlPath ~/.ssh/control/%r@%h:%p
    ControlPersist 10m
```

## Common Error Reference

| Error | Likely cause | Fix |
|-------|-------------|-----|
| `Permission denied (publickey)` | Key not authorized | `ssh-copy-id` or check `authorized_keys` |
| `Connection refused` | No SSH server on that port | Start sshd or check the port |
| `Connection timed out` | Network/firewall blocking | Check connectivity and firewall |
| `Host key changed` | Server was re-installed | `ssh-keygen -R hostname` |
| `Bad permissions` | Wrong file modes | `chmod 600` private keys, `700 ~/.ssh` |
| `No such file or directory` | Key file not found | Check the path in `-i` or config |
