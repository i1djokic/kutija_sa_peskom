# Anatomy of an Inode — What Lives Inside

## The Inode Table

Think of the inode table like a **spreadsheet with fixed-size rows**. Each row is one inode (typically 128 or 256 bytes). When you format a partition, the filesystem carves out a contiguous region of disk just for this table.

### "But `ls` shows me the name and permissions and size..."

Yes, but `ls` is lying to you — it's assembling information from two places:

```
directory entry (name + inode number)  ──┐
inode (metadata + block pointers)     ──┼── what ls shows
disk blocks (actual file content)     ──┘
```

## Inside the Inode

The inode is a **compact binary structure** (like a C `struct`). It contains:

### 1. File type and permissions (mode field)

```c
// Simplified representation
struct inode {
    __u16  i_mode;     // file type (4 bits) + permissions (12 bits)
    __u16  i_uid;      // owner user ID
    __u16  i_gid;      // owner group ID
    __u32  i_size;     // file size in bytes
    __u32  i_atime;    // last access time
    __u32  i_mtime;    // last modification time
    __u32  i_ctime;    // last status change time (not creation time!)
    __u16  i_links;    // number of hard links pointing to this inode
    __u32  i_blocks;   // number of 512-byte blocks used (maybe different from size)
    __u32  i_flags;    // file system flags (e.g., immutable, append-only)
    // ... and the block pointers (see below)
};
```

This is simplified — the real `ext4_inode` struct has about 20 more fields (extended attributes, ACL pointers, encryption info, etc.).

### 2. Timestamps — 3 of them, not 3 you'd expect

| Field | Meaning | When updated |
|-------|---------|-------------|
| `atime` | Access time | When the file is **read** (cat, less, etc.) |
| `mtime` | Modify time | When the file **content** changes |
| `ctime` | Change time | When the **inode metadata** changes (permissions, rename, hard link change) |

Note: There is **no creation time** on traditional Linux filesystems. `ctime` is *not* creation time — it's metadata change time. (Some newer filesystems like ext4 do support a birth timestamp field now.)

### 3. Block pointers — how the filesystem finds your data

This is the most complex part. The inode doesn't store the file content — it stores **pointers to disk blocks** that contain the content.

For a file that is, say, 10 bytes, only one disk block is needed (usually 4 KB on ext4). The inode stores the block number of that block.

#### What if the file is huge (e.g., 10 GB)?

The inode is only 128 or 256 bytes. It can't hold millions of block numbers directly. The solution is **indirection**:

```
Direct blocks (12 pointers):
    ──→ small files (up to 48 KB with 4 KB blocks)

Indirect block (1 pointer):
    ──→ a block full of block pointers ──→ 1024 blocks = 4 MB

Double indirect (1 pointer):
    ──→ a block of pointers to indirect blocks ──→ 1024 × 1024 blocks = 4 GB

Triple indirect (1 pointer):
    ──→ a block of pointers to... ──→ 1024 × 1024 × 1024 blocks = 4 TB
```

This is called **multi-level indexing**. It's like a table of contents (direct), an index (indirect), an index of indexes (double indirect), etc.

| Level | Pointers in inode | Max file size reached |
|-------|------------------|----------------------|
| Direct | 12 | 48 KB |
| Indirect | 1 | ~4 MB |
| Double indirect | 1 | ~4 GB |
| Triple indirect | 1 | ~4 TB |

### 4. Smart trick: sparse files (holes)

If you create a 1 GB file, seek to position 1 GB, and write 1 byte — the file is 1 GB but the filesystem doesn't allocate 1 GB of blocks. The inode stores "holes" as zero-length block extents. Reading a hole returns null bytes, but no disk space is consumed.

```bash
$ truncate -s 1G big.txt   # creates a sparse file instantly
$ ls -lh big.txt
-rw-r--r-- 1 user user 1.0G Jun  4 12:00 big.txt   # reports 1 GB
$ du -h big.txt
0   big.txt                                           # uses 0 blocks
```

The inode records the logical size (1 GB) but the block pointers are empty for the hole sections.

## Inode number == index in the table

On most filesystems, **inode number is just an index** into the inode table. Inode #1 is usually the first entry. Inode #2 is the root directory (`/`).

```bash
$ ls -ldi /
2 drwxr-xr-x 17 root root 4096 ... /   # inode 2 is always /

$ stat /
  File: /
  Size: 4096          Blocks: 8          IO Block: 4096   directory
Device: 8,1   Inode: 2          Links: 17
```

Well-known inode numbers:

| Inode | Purpose |
|-------|---------|
| 0 | Not used (null value) |
| 1 | Bad blocks list (historical) |
| 2 | Root directory (`/`) |
| 3–10 | Reserved (filesystem metadata) |
| 11+ | First usable inodes for user files |

## What's NOT stored in the inode

| Not in the inode | Where it lives |
|-----------------|---------------|
| File name | Parent directory's data blocks (as a directory entry) |
| Full path | Nowhere — it's reconstructed by walking directories |
| File content | Disk blocks pointed to by the inode's block pointers |
| Creation time | Not stored by default on ext3/older; ext4 has a `crtime` field |

> A file doesn't know its own name. An inode can have many names (hard links), so it can't store a single name.

## Visual summary

```
┌─────────────────────────────────────────────────────┐
│ Inode #8472 (128 bytes total)                       │
├─────────────────────────────────────────────────────┤
│ mode:    -rw-r--r--        │ type + permissions     │
│ uid:     1000              │ owner (your user)      │
│ gid:     1000              │ group                  │
│ size:    40960 bytes       │ 40 KB                 │
│ atime:   2026-06-04 10:00  │ last read             │
│ mtime:   2026-06-04 09:30  │ last write            │
│ ctime:   2026-06-04 09:31  │ last metadata change  │
│ links:   1                 │ hard link count       │
│ blocks:  80                │ disk blocks (512B ea) │
├─────────────────────────────────────────────────────┤
│ Block pointers:                                      │
│  ┌─────┬──────┬───────┬────────┐                    │
│  │  12 │  543 │ 22341 │ 401002 │  ... (direct)      │
│  └─────┴──────┴───────┴────────┘                    │
│  ┌──────────┐                                       │
│  │ #indirect: 89211 ──→ [more block pointers...]    │
│  └──────────┘                                       │
│  ...                                                 │
└─────────────────────────────────────────────────────┘
         │
         ▼
Disk block #12: [first 4 KB of file content]
Disk block #543: [next 4 KB of file content]
... and so on
```
