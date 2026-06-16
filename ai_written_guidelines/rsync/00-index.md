# Rsync Guide

Complete documentation for rsync — a fast, versatile tool for local and remote file copying, syncing, and backups.

## Contents

| File | What it covers |
|------|----------------|
| [01-basics.md](./01-basics.md) | What is rsync, installing, local and remote syntax |
| [02-trailing-slash-rule.md](./02-trailing-slash-rule.md) | The most common confusion — when `/` matters |
| [03-common-options.md](./03-common-options.md) | All essential flags with examples |
| [04-exclude-include.md](./04-exclude-include.md) | Excluding and including files by pattern |
| [05-backups.md](./05-backups.md) | Incremental backups with --link-dest and --backup |
| [06-practical-examples.md](./06-practical-examples.md) | Backup scripts, mirroring, migration, real scenarios |
| [07-rsync-over-ssh.md](./07-rsync-over-ssh.md) | Custom ports, keys, jump hosts, ssh config |
| [08-reference.md](./08-reference.md) | Quick command reference and comparison table |

## Quick Start

```bash
# Local: copy contents of src/ into dest/
rsync -av ./src/ ./dest/

# Remote: upload to a server
rsync -avz ./local/ user@hostname:/remote/path/

# Remote: download from a server
rsync -avz user@hostname:/remote/path/ ./local/

# Dry run first (no changes made)
rsync -av --dry-run ./src/ ./dest/
```

## Resources

- [Rsync man page](https://man.openbsd.org/rsync)
- [Rsync official site](https://rsync.samba.org/)
