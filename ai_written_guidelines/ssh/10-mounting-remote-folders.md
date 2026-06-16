# Mounting Remote Folders

Mount a remote directory as if it were a local folder using SSHFS.

## Installing SSHFS

```bash
# macOS
brew install sshfs

# Linux (Debian/Ubuntu)
sudo apt install sshfs

# Fedora
sudo dnf install fuse-sshfs
```

## Basic Usage

```bash
# Create a mount point
mkdir ~/remote-project

# Mount a remote folder
sshfs user@hostname:/remote/path ~/remote-project

# Now ~/remote-project behaves like a local folder — browse, edit, save
ls ~/remote-project
```

## Unmounting

```bash
# macOS / Linux
umount ~/remote-project

# If "device is busy" (Linux)
fusermount -u ~/remote-project

# macOS alternative
diskutil unmount ~/remote-project
```

## Using a Specific Key

```bash
sshfs -o IdentityFile=~/.ssh/mykey user@hostname:/remote/path ~/remote-project
```

## Mount with Custom SSH Options

```bash
# Use a non-default port
sshfs -p 2222 user@hostname:/remote/path ~/remote-project

# Mount via a jump host
sshfs -o ProxyJump=bastion.example.com user@internal:/remote/path ~/remote-project
```

## Performance Options

SSHFS over high-latency connections benefits from caching:

```bash
sshfs -o cache=yes,compression=yes,reconnect user@hostname:/remote/path ~/remote-project
```

| Option | What it does |
|--------|-------------|
| `cache=yes` | Enable caching (faster repeated reads) |
| `compression=yes` | Compress data during transfer |
| `reconnect` | Auto-reconnect if the connection drops |
| `ServerAliveInterval=15` | Keep connection alive |

## Auto-Mount via fstab

```bash
# Add to /etc/fstab:
sshfs#user@hostname:/remote/path  /home/user/remote-project  fuse  IdentityFile=/home/user/.ssh/id_ed25519,uid=1000,gid=1000,_netdev,reconnect  0  0
```

Then mount with:

```bash
mount /home/user/remote-project
```

## Using rsync Instead (for Bulk Transfers)

For large transfers, `rsync` is faster than SSHFS:

```bash
# One-time sync
rsync -avz user@hostname:/remote/path/ ~/local-copy/

# Or mount and then rsync to keep a local copy in sync
sshfs user@hostname:/remote/path ~/remote-project
rsync -avz --delete ~/remote-project/ ~/local-backup/
```

## Security Note

SSHFS is encrypted in transit (it uses SSH), but files appear as local files to other local processes. Don't mount sensitive data on a shared/multi-user machine unless you trust all users.
