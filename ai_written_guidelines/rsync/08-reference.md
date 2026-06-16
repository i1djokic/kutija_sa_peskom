# Reference

## Command Cheat Sheet

### Local

| Command | What it does |
|---------|-------------|
| `rsync -av /src/ /dst/` | Copy contents of src into dst |
| `rsync -av --delete /src/ /dst/` | Mirror — make dst identical to src |
| `rsync -avu /src/ /dst/` | Update — only copy newer files |
| `rsync -av --dry-run /src/ /dst/` | Show what would happen |
| `rsync -av --exclude='*.log' /src/ /dst/` | Exclude files |

### Remote

| Command | What it does |
|---------|-------------|
| `rsync -avz ./ user@host:/dest/` | Upload to remote |
| `rsync -avz user@host:/src/ ./` | Download from remote |
| `rsync -avz -e "ssh -p 2222" ./ user@host:/dest/` | Custom port |
| `rsync -avz -e "ssh -i key" ./ user@host:/dest/` | Custom key |
| `rsync -avz -e "ssh -J bastion" ./ user@internal:/dest/` | Via jump host |

### Backups

| Command | What it does |
|---------|-------------|
| `rsync -av --backup /src/ /dst/` | Backup replaced files |
| `rsync -av --link-dest=/prev/ /src/ /today/` | Incremental with hard links |
| `rsync -av --backup-dir=/backups/ /src/ /dst/` | Backup to specific dir |

## All Flags Quick Reference

| Flag | Description |
|------|-------------|
| `-a, --archive` | Preserve everything, recursive |
| `-v, --verbose` | Show output |
| `-z, --compress` | Compress during transfer |
| `-h, --human-readable` | Human-readable sizes |
| `-n, --dry-run` | Trial run (no changes) |
| `-P` | `--progress` + `--partial` combined |
| `-u, --update` | Skip files newer on destination |
| `-i, --itemize-changes` | Show what changed |
| `--delete` | Remove files not in source |
| `--delete-excluded` | Also delete excluded files |
| `--exclude=PATTERN` | Skip matching files |
| `--include=PATTERN` | Include matching files |
| `--exclude-from=FILE` | Read excludes from file |
| `--max-size=SIZE` | Skip files larger than SIZE |
| `--min-size=SIZE` | Skip files smaller than SIZE |
| `--progress` | Show per-file progress |
| `--partial` | Keep partial transfers |
| `--append` | Resume partial files |
| `--bwlimit=KBPS` | Limit bandwidth |
| `--backup` | Backup replaced files |
| `--backup-dir=DIR` | Save backups to DIR |
| `--link-dest=DIR` | Hard-link unchanged files from DIR |
| `--remove-source-files` | Delete source after transfer |
| `--ignore-existing` | Skip files that exist on destination |
| `--sparse` | Handle sparse files efficiently |
| `--chown=USER:GROUP` | Set owner/group on destination |
| `--chmod=PERMS` | Set permissions on destination |
| `--files-from=FILE` | Read file list from file |
| `-e, --rsh=COMMAND` | Specify remote shell |

## rsync vs Other Tools

| Tool | Best for | Preserves attributes | Incremental | Remote |
|------|----------|---------------------|-------------|--------|
| `rsync` | Transfers, sync, backups | Yes | Yes | Yes |
| `cp` | Local copies | Partial | No | No |
| `scp` | Quick remote copy | No | No | Yes |
| `sftp` | Interactive browsing | No | No | Yes |

## Trailing Slash Summary

| Command | Result |
|---------|--------|
| `rsync -av /src/ /dst/` | Contents of src into dst |
| `rsync -av /src /dst/` | src itself into dst → dst/src |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Syntax or usage error |
| 2 | Protocol incompatibility |
| 3 | Errors selecting input/output files |
| 5 | Error starting client-server protocol |
| 10 | Error in socket I/O |
| 20 | Received SIGUSR1 or SIGINT |
| 21 | Some files could not be transferred |
| 23 | Some files could not be transferred (partial) |
| 24 | Vanished source files |
| 30 | Timeout in data send/receive |
