# Rsync Basics

## What is rsync?

Rsync copies files locally or between machines. It only transfers the differences between source and destination, making it much faster than `cp` or `scp` for repeated transfers.

Key features:
- Incremental transfers (only sends changed parts)
- Preserves permissions, timestamps, symlinks, ownership
- Compression during transfer
- Works locally and over SSH
- Can delete, exclude, and back up files

## Installing

```bash
# macOS
brew install rsync

# Linux (usually pre-installed)
sudo apt install rsync       # Debian/Ubuntu
sudo dnf install rsync       # Fedora

# Windows (via WSL or Cygwin)
```

Check: `rsync --version`

## Local Usage

Copy files between directories on the same machine.

```bash
# Copy a directory
rsync -av /source/path/ /destination/path/

# Copy a single file
rsync -av file.txt /destination/

# Sync with deletion (mirror)
rsync -av --delete /source/ /destination/
```

## Remote Usage

Transfer files to/from a remote machine over SSH (default).

```bash
# Local to remote (upload)
rsync -avz ./local/ user@hostname:/remote/path/

# Remote to local (download)
rsync -avz user@hostname:/remote/path/ ./local/

# Remote to remote (traffic goes through your machine)
rsync -avz user1@host1:/path/ user2@host2:/path/
```

## Minimal Flags

The most common flags:

```bash
rsync -avz /source/ /dest/
```

| Flag | What it does |
|------|-------------|
| `-a` | Archive mode — preserve everything (recursive, permissions, timestamps, etc.) |
| `-v` | Verbose — show what's being transferred |
| `-z` | Compress during transfer (recommended for remote, skip for local) |

## The Three Operations

```bash
rsync -av /src/ /dest/          # Copy — add files that don't exist at dest
rsync -avu /src/ /dest/         # Update — only copy files that are newer
rsync -av --delete /src/ /dest/ # Mirror — make dest exactly match src
```

## Dry Run First

Always do a dry run before destructive operations:

```bash
rsync -av --dry-run /src/ /dest/
```
