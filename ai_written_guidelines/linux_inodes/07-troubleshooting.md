# Troubleshooting Inode Exhaustion — Detective Work

## Symptoms

Applications start failing with:

```
touch: cannot touch 'test': No space left on device
write error: No space left on device
```

But `df -h` shows plenty of free space. The user is confused. The admin must investigate.

## Step 1: Confirm it's inodes

```bash
df -h /var/spool
df -i /var/spool
```

Compare `Use%` on both. If `df -h` is 24% but `df -i` is 100%: you've found the problem.

## Step 2: Find the source of inode consumption

### Find top-level directories with the most inodes

```bash
du --inodes -d 1 /var 2>/dev/null | sort -rn | head -10
```

This gives you the immediate children of `/var`. Look for the biggest offender.

### Drill down recursively

```bash
du --inodes /var/spool 2>/dev/null | sort -rn | head -20
```

Keep drilling: `du --inodes /var/spool/mail | sort -rn | head -20`

### Alternative: find with counts

```bash
# Count files in each subdirectory of current dir
for d in */; do echo "$(find "$d" -xdev | wc -l) $d"; done | sort -rn | head -10
```

### Don't forget hidden files

```bash
# Count EVERYTHING including hidden files
find /var/spool -xdev | wc -l
```

## Step 3: Find old files to delete

```bash
# Files not accessed in 90 days
find /var/spool -xdev -atime +90 -type f

# Delete them (CAREFUL!)
find /var/spool -xdev -atime +90 -type f -delete

# Or move them to a different partition with more inodes
find /var/spool -xdev -atime +90 -type f -exec mv {} /backup/ \;
```

## Step 4: Is it tiny files or directories?

```bash
# Count directories vs files
find /var/spool -xdev -type d | wc -l   # directories
find /var/spool -xdev -type f | wc -l   # regular files
```

Each directory also consumes an inode. 10 million directories is just as bad as 10 million files.

## Step 5: Check inode ratio of the filesystem

```bash
# See current inode count and ratio
sudo dumpe2fs -h /dev/sda1 | grep -E "(Inode count|Inode size|Inodes per group|Inode ratio)"
```

Output example:
```
Inode count:              32768000
Inode size:               256
Inodes per group:         16384
Inode ratio:              16384    ← 1 inode per 16 KB
```

The **inode ratio** tells you the spacing. `16384` means 1 inode per 16 KB. If your files average 2 KB, you'll run out of inodes long before you fill the disk.

## Step 6: Use `df -i` proactively

Monitor inode usage the same way you monitor disk usage:

```bash
# Alert when inode usage exceeds 90%
df -i | awk 'NR>1 {if ($5+0 > 90) print $1, $5, "inode usage high"}'
```

Set up a cron job or monitoring (Nagios, Prometheus, etc.) to watch inode counts on busy partitions.

## Quick one-liner summary

```bash
# Full diagnostic in one shot
echo "=== DISK ===" && df -h /var/spool && echo "=== INODES ===" && df -i /var/spool && echo "=== TOP CONSUMERS ===" && du --inodes -d 3 /var/spool 2>/dev/null | sort -rn | head -15 && echo "=== FILE COUNT ===" && find /var/spool -xdev | wc -l
```

## Recovery actions (sorted by urgency)

| Action | Effect | Downtime |
|--------|--------|----------|
| Delete old/unneeded files | Frees inodes immediately | None |
| Move files to another partition | Frees inodes | None |
| Archive + delete | `tar czf archive.tgz old/ && rm -rf old/` | None |
| `find -delete` | Mass deletion | None |
| Reformat with more inodes | Full fix | Required |
| Switch filesystem | e.g., XFS (dynamic inodes) | Required |
| Consolidate into fewer files | e.g., DB instead of individual files | Architectural |

## Prevention

```bash
# When formatting, calculate needed inodes:
# Expected number of files = (average file count per GB) × (total GB)
mkfs.ext4 -N 50000000 /dev/sdX          # explicit count
mkfs.ext4 -i 8192 /dev/sdX              # 1 inode per 8 KB (more inodes)
mkfs.ext4 -i 65536 /dev/sdX             # 1 inode per 64 KB (fewer inodes, for large files)

# Check ratio before formatting:
mkfs.ext4 -n /dev/sdX | grep inode      # dry run, shows what would be created
```

## Real-world examples of inode exhaustion

### npm / node_modules

```bash
# A single project with many dependencies can use 50,000+ inodes
$ du --inodes node_modules | tail -1
52381   node_modules

# 100 projects on a shared filesystem with default ratio:
# 100 × 50,000 = 5,000,000 inodes just for node_modules
```

### Docker

```bash
# Each container's overlay filesystem consumes inodes
# Old containers, images, and volumes accumulate
$ docker system prune   # cleans dangling images and containers
$ du --inodes /var/lib/docker | sort -rn | head -10
```

### Mail servers

Each email stored as a separate file (Maildir format) in `/var/spool/mail/`:

```bash
# 10 million emails = 10 million inodes
$ ls /var/spool/mail/user/cur/ | wc -l
8347291
```

Solution: Switch to a database-backed mail store (Dovecot with dbox/mdbox) or implement aggressive retention policies.

## Emergency procedure when completely stuck

You're at 100% inodes. You can't create files, can't run programs that log, can't even create temp files.

```bash
# Commands that don't need to create files:
du --inodes     # read-only, works
find -delete    # needs to stat files but doesn't create new ones
rm              # deleting doesn't need new inodes
df -i           # read-only, works

# If even rm fails (rare):
# 1. Check if there are processes holding deleted files open
lsof +L1         # shows files with link count 0 but still open
# 2. Restart those processes or kill them
# 3. Empty trash: rm -rf ~/.local/share/Trash/*
# 4. Clear temp directories: rm -rf /tmp/* /var/tmp/*
```
