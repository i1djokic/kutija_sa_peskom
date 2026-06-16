# Hard Links vs Symbolic Links — The Inode Connection

## What is a link?

A "link" is just a **directory entry** — a mapping from a **name** to an **inode number**. Every file name you see is technically a link.

```bash
# "file.txt" is a directory entry that links to inode #8472
$ ls -li file.txt
8472 -rw-r--r-- 1 user user 0 Jun  4 10:00 file.txt
```

The `1` in `ls -li` output is the **link count** — how many directory entries point to this inode.

## Hard Links

A hard link is **another name for the same inode**. It's not a copy — it's a second directory entry pointing to the same inode number.

```bash
$ echo "hello world" > original.txt
$ ln original.txt hardlink.txt   # create a hard link
$ ls -li
8472 -rw-r--r-- 2 user user 12 Jun  4 10:00 original.txt
8472 -rw-r--r-- 2 user user 12 Jun  4 10:00 hardlink.txt
#       ↑                        ↑
# same inode number              link count is now 2
```

### Key properties of hard links

| Property | Explanation |
|----------|-------------|
| Same inode | Both names point to inode #8472 |
| Same data | Changing one changes the other (it's the same file) |
| Link count | `ls -l` shows `2` — two names for this inode |
| Cannot cross filesystems | Inodes exist in a single filesystem's table |
| Cannot link directories | Would create cycles in the filesystem tree |
| No special syntax | Hard links are invisible — you can't tell which is "original" |

### What happens when you delete one hard link?

```bash
$ rm original.txt
# Directory entry "original.txt" removed
# Link count drops from 2 → 1
# Data is NOT deleted — it's still accessible via "hardlink.txt"
$ cat hardlink.txt
hello world

$ rm hardlink.txt
# Directory entry "hardlink.txt" removed
# Link count drops from 1 → 0
# Kernel now knows the inode is unused
# Disk blocks are marked as free
```

**A file is only truly deleted when its link count reaches 0 and no process has the file open.**

### Practical use of hard links

- **Backup with `rsync --link-dest` / `cp -l`**: Instead of copying identical files, create hard links to save space.
- **Git**: Uses hard links in object storage in some configurations (though usually symlinks now).
- **`ln` command**: Making a file appear in two places without duplicating disk space.

## Symbolic Links (Symlinks)

A symlink is a **special file** whose content is a path string. It has its **own inode** and points to a **name** (which happens to be another file's path).

```bash
$ echo "hello world" > original.txt
$ ln -s original.txt symlink.txt   # create a symbolic link
$ ls -li
8472 -rw-r--r-- 1 user user 12 Jun  4 10:00 original.txt
8473 lrwxrwxrwx 1 user user 12 Jun  4 10:01 symlink.txt → original.txt
#       ↑                         ↑
# different inode!                type is 'l' (link)
```

### Key properties of symbolic links

| Property | Explanation |
|----------|-------------|
| Different inode | Symlink has its own inode (here #8473) |
| Different data | Content is the **path string** "original.txt" |
| Link count always 1 | The symlink inode only has one name |
| Can cross filesystems | It's just a path string, not an inode reference |
| Can link directories | Allowed (unlike hard links) |
| Dangling possible | If target is deleted, the symlink still exists but points nowhere |
| Special type | Shows as `lrwxrwxrwx` in `ls -l` |

### What happens when the target is deleted?

```bash
$ rm original.txt
$ cat symlink.txt
cat: symlink.txt: No such file or directory
$ ls -l symlink.txt
lrwxrwxrwx 1 user user 12 Jun  4 10:01 symlink.txt → original.txt  # still exists!
```

The symlink is **broken** (dangling). It still exists as a file (it has its own inode), but the path it points to doesn't exist. No automated cleanup — you have to delete the symlink manually.

### Symlinks and `..` — a trap

```bash
$ ln -s /tmp/missing/link .
$ ls -l link
lrwxrwxrwx 1 user user ... link -> /tmp/missing
$ cd link
-bash: cd: link: No such file or directory

# But "ls -l" shows it exists... confusing!
# The symlink exists, but the target doesn't.
```

## Side-by-side comparison

| Feature | Hard Link | Symbolic Link |
|---------|-----------|---------------|
| Inode number | Same as target | Different |
| Points to | An inode number | A path name |
| Size | 0 bytes (uses target's size) | Length of path string |
| `ls -l` type | `-` (regular) | `l` (link) |
| Permission | Same as target | Always `rwxrwxrwx` (but ineffective) |
| Cross filesystem | ❌ No | ✅ Yes |
| Directory links | ❌ Not allowed (except `.` and `..`) | ✅ Yes |
| Dangling state | Impossible (inode either exists or not) | ✅ Possible |
| Space overhead | None (just a dirent) | Path string length + 1 inode |
| Delete target | Content remains (accessible via other links) | Symlink becomes broken |
| Can tell which is "original"? | No | Yes (follow the path) |

## The "original" misconception

**There is no such thing as "the original" with hard links.** Both names are equally valid. The file is the inode — names are just labels.

```bash
$ echo "data" > a
$ ln a b
$ rm a
# "b" still has the data. "a" was just another name.
```

Think of it like: the inode is a house, directory entries are addresses. Hard links mean the house has two addresses. If you tear down one address sign, the house is still there.

## Which one should I use?

| You want to... | Use |
|----------------|-----|
| Save disk space by deduplicating files | Hard link |
| Make a file appear in another directory without copying | Hard link |
| Create a shortcut to a file across partitions | Symlink |
| Link a directory | Symlink |
| Make a link you can delete without affecting the original | Symlink |
| Create a symlink that moves with its target (relative) | Symlink with relative path |
| Version your files without duplication | Hard link (or CoW like Btrfs) |

## Symlink trap: absolute vs relative paths

```bash
$ ln -s /home/user/docs/file.txt link      # absolute path
$ ln -s ../docs/file.txt link              # relative path

# Relative symlinks survive if you move the entire directory tree:
$ mv /home/user /mnt/backup/
# Absolute symlink is now broken (/home/user/docs/file.txt doesn't exist)
# Relative symlink still works (../docs/file.txt resolves from new location)
```
