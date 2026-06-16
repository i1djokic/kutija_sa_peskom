# rsync

More powerful than scp — supports incremental transfers, resuming, and preserving file attributes.

## Basic Usage

```bash
# Basic sync (local to remote)
rsync -avz ./local/ user@hostname:/remote/path/

# Remote to local
rsync -avz user@hostname:/remote/path/ ./local/

# Delete files on the destination that no longer exist on the source
rsync -avz --delete ./local/ user@hostname:/remote/path/

# Exclude files
rsync -avz --exclude='*.log' ./local/ user@hostname:/remote/path/

# Dry run (show what would be transferred)
rsync -avz --dry-run ./local/ user@hostname:/remote/path/

# Resume a partial transfer
rsync -avz --partial ./local/ user@hostname:/remote/path/

# Over SSH with a custom port
rsync -avz -e "ssh -p 2222" ./local/ user@hostname:/remote/path/
```

## Flags Explained

| Flag | Meaning |
|------|---------|
| `-a` | Archive mode (preserves permissions, timestamps, symlinks) |
| `-v` | Verbose |
| `-z` | Compress during transfer |
| `--delete` | Remove files on destination not present on source |
| `--dry-run` | Show what would happen without transferring |
| `--partial` | Keep partially transferred files (resume later) |
| `--exclude` | Skip files matching a pattern |
| `--progress` | Show progress for each file |
| `-e` | Specify the remote shell to use (e.g., `ssh -p 2222`) |

## Trailing Slash Behavior

The trailing `/` matters:

```bash
rsync -avz ./src/ user@host:/dest/   # Copy contents of src/ into dest/
rsync -avz ./src  user@host:/dest/   # Copy src/ itself into dest/ -> dest/src/
```

## When to Use rsync

- Large transfers or backups
- Incremental sync (only transfers changed parts)
- Resuming interrupted transfers
- Mirroring directories

## See Also

- [scp](./04-scp.md) — simpler, one-shot copies
- [sftp](./06-sftp.md) — interactive browsing and file management
