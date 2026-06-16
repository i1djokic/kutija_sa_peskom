# Practical Examples

Real-world rsync use cases — from simple to complex.

## Mirror a Directory

Make destination an exact copy of source:

```bash
rsync -av --delete /src/ /dst/
```

## Sync Two Directories Both Ways

Keep two directories in sync (run both directions):

```bash
# First direction
rsync -avu /dir1/ /dir2/
# Second direction
rsync -avu /dir2/ /dir1/
```

**Note:** This is not true bidirectional sync. For that, use `unison` or a sync tool.

## Deploy a Website

Push local files to a web server:

```bash
rsync -avz --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.env' \
    ./build/ user@server:/var/www/html/
```

## Download Logs from a Server

Fetch log files with a date filter:

```bash
# Download logs from the last 7 days
rsync -avz --include='*.log' --exclude='*' \
    user@server:/var/log/myapp/ ./logs/
```

## Migrate a Server

Copy everything from one server to another:

```bash
# Direct server-to-server (traffic goes through your machine)
rsync -avz user@old-server:/home/ user@new-server:/home/

# Or pull from old to local, then push to new
rsync -avz user@old-server:/home/ ./backup-home/
rsync -avz ./backup-home/ user@new-server:/home/
```

## Resume a Failed Transfer

If a large transfer is interrupted:

```bash
# --partial keeps what was transferred, --append continues from where it stopped
rsync -avP --append /src/ user@host:/dst/
```

## Sync with Exclusions

Typical project sync:

```bash
rsync -av \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.DS_Store' \
    --exclude='*.log' \
    --exclude='dist/' \
    --exclude='.env' \
    /project/ user@server:/project/
```

## Automated Nightly Backup

Add to crontab:

```bash
# Every night at 2am
0 2 * * * /usr/bin/rsync -avz --delete /home/user/data/ user@server:/backups/data/
```

## Copy Only New Files

```bash
# Only copy files that don't exist on destination
rsync -av --ignore-existing /src/ /dst/

# Only copy files that are newer on source
rsync -avu /src/ /dst/
```

## Show Changes Without Copying

```bash
rsync -avi --dry-run /src/ /dst/
```

Output:
```
.d..t...... ./
>f+++++++++ new-file.txt
>f.st...... modified-file.txt
*deleting   deleted-file.txt
```

## Copy While Preserving Permissions

```bash
rsync -a /src/ /dst/                    # Preserves most things
rsync -a --chown=user:group /src/ /dst/ # Change owner on destination
rsync -a --chmod=755 /src/ /dst/        # Set specific permissions
```
