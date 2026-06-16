# Inode Lifecycle — From Birth to Death

## Birth: When an inode is allocated

An inode is allocated when a new file or directory is created. The filesystem's **inode allocator** picks a free inode from the inode bitmap (a simple bitfield where each bit = 1 inode).

```bash
# Creating a file triggers inode allocation
$ touch myfile.txt   # kernel calls: ext4_new_inode()
```

### What happens internally

1. **Kernel receives syscall** (`open()` with `O_CREAT` or `creat()`)
2. **Filesystem driver** calls its `create` operation
3. **Inode allocator** finds a free bit in the inode bitmap
4. **Inode table entry** is initialized with defaults (mode, uid, gid, timestamps)
5. **Directory entry** is added to the parent directory
6. **Link count** is set to 1

### Inode bitmap

```
Inode bitmap (simplified):
  0  1  2  3  4  5  6  7  8  9  10  11  12 ...
 [x][x][x][x][x][ ][ ][ ][ ][ ][  ][  ][  ] ...
  ↑  ↑  ↑  ↑  ↑  └─── free inodes ────┘
  │  │  │  │  └ inode 5 = used
  │  │  │  └ inode 4 = used
  │  │  └ inode 3 = used (lost+found)
  │  └ inode 2 = used (/)
  └ inode 1 = used (bad blocks)

Inode 6 would be allocated next.
```

On ext4, the bitmap is split into **block groups**. Each group has its own inode bitmap and data block bitmap. This locality means files in the same directory tend to be in the same block group (good for performance).

## Life: What changes during a file's life

### Each operation touches different parts

| Operation | Inode changes | Data blocks | Directory |
|-----------|--------------|-------------|-----------|
| `touch file` | Allocate inode, set times | None | Add entry |
| `echo "hi" > file` | Update size, mtime, ctime | Allocate blocks | None |
| `chmod 755 file` | Update mode, ctime | None | None |
| `chown user file` | Update uid/gid, ctime | None | None |
| `mv file newname` | None (inode unchanged) | None | Modify directory entry |
| `cp file copy` | Allocate new inode | Allocate + copy | Add entry |
| `ln file link` | Increment link count, ctime | None | Add entry |
| `read file` | Update atime | Read blocks | None |

### mv: the most efficient operation

A `mv` within the same filesystem only changes the **directory entry**. The inode and data blocks stay exactly where they are. That's why `mv` is instant even for multi-gigabyte files.

```bash
$ mv /home/user/100gb_file.iso /mnt/backup/   # if same fs: instant!
```

A `mv` across filesystems = `cp + rm` (copy data, allocate new inode, delete old).

### atime writes — the hidden cost

Every time you read a file, the kernel updates `atime` (access time) in the inode. That's a disk write on every read. Most modern Linux systems use `relatime` (default since kernel 2.6.30), which limits atime updates to once per day or when mtime/ctime changes.

```bash
$ mount | grep relatime
/dev/sda1 on / type ext4 (rw,relatime,errors=remount-ro)
```

## Death: When an inode is freed

### Normal deletion

```bash
$ rm myfile.txt
```

The kernel:
1. **Removes the directory entry** from the parent directory's data
2. **Decrements the link count** in the inode (e.g., from 1 to 0)
3. Link count == 0 and no open file handles → **Frees the inode**
4. Marks all data blocks as free in the block bitmap
5. Clears the inode bitmap bit

### Deletion while the file is still open

This is a common pattern in Linux:

```bash
# Process A opens a log file
$ tail -f /var/log/app.log &

# Process B deletes it
$ rm /var/log/app.log

# Process A is still writing to it!
```

Even though the directory entry is gone (link count = 0), the **inode and data blocks still exist** because the kernel keeps a reference while the file descriptor is open.

```bash
$ lsof +L1   # shows files with link count 0 but still open
COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NLINK   NODE NAME
tail    12345   user   3r   REG   8,1    45678     0  8472 /var/log/app.log (deleted)
```

The data is only freed when the last process closes the file descriptor. Until then, the disk space is in use but invisible — no `ls` can find it.

### Inode reuse

After an inode is freed, it stays free until a new file needs it. The allocator may:
- Reuse the same inode number immediately (if it's the first free one)
- Prefer inode numbers close to the parent directory (locality)

```bash
$ touch a b; rm a; touch c  # c may get a's inode number
$ ls -li
8472 -rw-r--r-- ... c       # inode 8472 was a's, now c's
```

## What happens during a crash (fsck)

If the system crashes between steps 1–3 above, the filesystem is inconsistent. `fsck` (filesystem consistency check) runs at boot:

1. **Checks inode bitmaps** against actual inode allocations
2. **Checks block bitmaps** against actual block allocations
3. **Checks directory entries** reference valid inodes
4. **Fixes orphaned inodes** (inode allocated but no directory entry points to it → placed in `lost+found`)

```bash
$ ls /lost+found/
#84512   # orphaned inode recovered by fsck
```

`lost+found` files have no meaningful name — the directory entry was lost in the crash, but fsck recovered the inode and its data.

## Timeline visualization

```
Time ──────────────────────────────────────────────────────────►

CREATE:
  Inode Allocated ──► Directory Entry Added ──► File Ready
  (bitmap cleared)    (link count = 1)           (read/write)

LIFE:
  open/read/write/close/chmod/chown/link/unlink
  (inode stays allocated throughout)

DELETE (link count → 0):
  Directory Entry Removed ──► Inode Freed
  (rm/ unlink)                (bitmap set, blocks freed)

DELETE (file still open):
  Directory Entry Removed ──► (link count = 0)
  (rm/ unlink)                but inode stays until
                              last file descriptor closed
                              ──► Inode Freed

RECOVERY (fsck):
  Crash ──► fsck finds orphan ──► Creates dirent in lost+found ──► Link count restored
```

## Summary

| Stage | What happens to inode | Link count |
|-------|----------------------|------------|
| Before creation | Free (bitmap = 0) | — |
| File created | Allocated, initialized | 1 |
| Hard link added | Still same inode | +1 |
| File deleted (1 link) | Freed | → 0 |
| File deleted (>1 links) | Still alive | → n−1 |
| File deleted (open) | Still alive (zombie) | → 0, but referenced |
| Last close after delete | Finally freed | 0 |
