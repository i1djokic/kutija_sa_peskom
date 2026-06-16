# Common Options

All essential rsync flags with explanations and examples.

## Archive Mode (-a)

The most important flag. It combines: `-rlptgoD`

```bash
rsync -a /src/ /dst/
```

What `-a` preserves:

| Flag part | What it does |
|-----------|-------------|
| `-r` | Recursive (descend into directories) |
| `-l` | Copy symlinks as symlinks |
| `-p` | Preserve permissions |
| `-t` | Preserve timestamps |
| `-g` | Preserve group |
| `-o` | Preserve owner (requires root) |
| `-D` | Preserve device files (requires root) |

## Verbose (-v, -vv)

```bash
rsync -av /src/ /dst/          # Show transferred files
rsync -avv /src/ /dst/         # More detail
rsync -avvv /src/ /dst/        # Debug output
```

## Compression (-z)

Compress data during transfer. Adds CPU overhead but saves bandwidth.

```bash
# Recommended for remote transfers
rsync -avz /src/ user@host:/dst/

# Skip for local (no benefit)
rsync -av /src/ /dst/
```

## Progress (--progress, -P)

Show transfer progress for each file:

```bash
rsync -av --progress /src/ /dst/

# -P combines --progress and --partial
rsync -avP /src/ /dst/
```

## Delete (--delete)

Remove files in the destination that don't exist in the source. Makes dest an exact mirror.

```bash
# Mirror mode
rsync -av --delete /src/ /dst/
```

**Caution:** Combine with `--dry-run` first.

Variations:

| Flag | Behavior |
|------|----------|
| `--delete` | Delete extraneous files from destination |
| `--delete-before` | Delete before transferring (saves space) |
| `--delete-during` | Delete while transferring (default) |
| `--delete-excluded` | Also delete excluded files from destination |
| `--delete-delay` | Delete after transfer completes |

## Update Only (-u)

Skip files that are newer on the destination:

```bash
rsync -avu /src/ /dst/
```

## Dry Run (-n, --dry-run)

Show what would happen without making changes:

```bash
rsync -av --dry-run /src/ /dst/
```

Always use this before `--delete`.

## Human-Readable (-h)

Show file sizes in human-readable format (KB, MB, GB):

```bash
rsync -avh /src/ /dst/
```

## Itemize Changes (-i)

Show what rsync is doing to each file:

```bash
rsync -avi /src/ /dst/
```

Output format:

| Code | Meaning |
|------|---------|
| `>f` | File transfer |
| `cd` | Directory creation |
| `*deleting` | File being deleted |
| `.` | Attribute change (permissions, timestamp) |

## Partial Transfer (--partial)

Keep partially transferred files so the transfer can be resumed:

```bash
# Keep partial files
rsync -av --partial /src/ /dst/

# Same, but shorter: -P
rsync -avP /src/ /dst/
```

## Quick Reference Table

| Flag | Short | What it does |
|------|-------|-------------|
| `--archive` | `-a` | Preserve everything, recursive |
| `--verbose` | `-v` | Show output |
| `--compress` | `-z` | Compress during transfer |
| `--delete` | | Remove files not in source |
| `--dry-run` | `-n` | Show what would happen |
| `--progress` | | Show per-file progress |
| `--partial` | | Keep partial files (resume) |
| `--update` | `-u` | Skip newer files on dest |
| `--human-readable` | `-h` | Human-readable sizes |
| `--itemize-changes` | `-i` | Show change codes |
| `--exclude` | | Skip matching files |
| `--include` | | Only include matching files |
| `--max-size` | | Skip files larger than N |
| `--min-size` | | Skip files smaller than N |
| `--bwlimit` | | Limit bandwidth (KB/s) |
| `--remove-source-files` | | Delete source after transfer |
