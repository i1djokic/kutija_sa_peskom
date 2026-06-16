# Linux Inodes — Index

A beginner-to-advanced guide on Linux inodes, filesystem metadata, links, directories, and troubleshooting.

## How to use this

| If you are... | Start with |
|---------------|------------|
| **Absolute beginner** | [05-inode-analogies.md](./05-inode-analogies.md) |
| **Hitting "No space left" but disk is empty** | [07-troubleshooting.md](./07-troubleshooting.md) |
| **Confused about hard links vs symlinks** | [04-hard-links-vs-symlinks.md](./04-hard-links-vs-symlinks.md) |
| **Curious what's inside an inode** | [01-anatomy-of-an-inode.md](./01-anatomy-of-an-inode.md) |
| **Choosing a filesystem** | [03-filesystem-comparison.md](./03-filesystem-comparison.md) |
| **Debugging path resolution** | [02-directory-structure.md](./02-directory-structure.md) |
| **Writing tools that touch files** | [06-inode-lifecycle.md](./06-inode-lifecycle.md) |

## Files

| # | File | Level | Covers |
|---|------|-------|--------|
| 1 | [05-inode-analogies.md](./05-inode-analogies.md) | Beginner | Parking lots, libraries, mailboxes — zero jargon |
| 2 | [01-anatomy-of-an-inode.md](./01-anatomy-of-an-inode.md) | Intermediate | Data structure, block pointers, timestamps, sparse files |
| 3 | [04-hard-links-vs-symlinks.md](./04-hard-links-vs-symlinks.md) | Intermediate | Hard links, symbolic links, link count, comparison table |
| 4 | [02-directory-structure.md](./02-directory-structure.md) | Intermediate | Dentries, path resolution, `.` and `..`, dcache |
| 5 | [06-inode-lifecycle.md](./06-inode-lifecycle.md) | Advanced | Birth→life→death, orphaned inodes, fsck, zombie files |
| 6 | [07-troubleshooting.md](./07-troubleshooting.md) | Advanced | Detective work, emergency recovery, real-world npm/Docker/mail examples |
| 7 | [03-filesystem-comparison.md](./03-filesystem-comparison.md) | Advanced | ext4 vs XFS vs Btrfs vs ZFS inode strategies |

## Quick reference

```bash
df -i           # inode usage
df -h           # disk usage
ls -li file     # see inode number
du --inodes -d 1 / | sort -rn | head -10   # find inode hogs
stat file       # full inode metadata
```
