# Filesystem Comparison — How Different Filesystems Handle Inodes

Not all filesystems are created equal. The inode model varies dramatically between them.

## ext4 — The traditional approach

Inodes are **pre-allocated at format time** in a fixed-size table. You decide the number when you create the filesystem.

```bash
# Default: 1 inode per 16384 bytes (16 KB)
mkfs.ext4 /dev/sdX

# Custom: 1 inode per 8 KB (double the inodes)
mkfs.ext4 -i 8192 /dev/sdX

# Custom: explicit count (100 million inodes)
mkfs.ext4 -N 100000000 /dev/sdX
```

| Feature | ext4 |
|---------|------|
| Inode allocation | **Fixed** (set at `mkfs` time) |
| Resize inode count | Possible but **requires resize2fs** |
| Inode size | 256 bytes (default) |
| Max inodes | ~4 billion (theoretical, 2³²) |
| Dynamic inodes | ❌ No |
| Online defrag | Limited |
| Inline data | ✅ (small files inside inode) |
| Extents | ✅ (replaces block pointers) |

### ext4 inline data

If a file is small enough (≤ 60 bytes), ext4 can store the **file content directly inside the inode structure**, avoiding a disk block allocation entirely. This is transparent — you don't notice, but it saves resources for thousands of tiny files.

### ext4 flex_bg (flexible block groups)

Modern ext4 groups block groups into "flex block groups" (usually 16), which packs inode tables and data bitmaps together. This reduces seeks when creating files.

## XFS — The scalable approach

XFS uses **dynamic inode allocation**. Inodes are allocated on demand from "inode chunks" within allocation groups. This means:

- **No pre-formatting guesswork** — you won't run out of inodes if you didn't predict correctly
- Inodes are allocated from data space, so inode and data share the same pool

```bash
# On XFS, there's no -i or -N flag for inode count
# Inodes are allocated dynamically from available space
mkfs.xfs /dev/sdX
```

| Feature | XFS |
|---------|-----|
| Inode allocation | **Dynamic** (from data space) |
| Resize inode count | Not needed (automatic) |
| Inode size | 512 bytes (default) |
| Max inodes | Limited only by available space |
| Dynamic inodes | ✅ Yes |
| Online defrag | ✅ `xfs_fsr` |
| Inline data | ❌ No |
| Extents | ✅ B-tree based |

### XFS real-life inode behavior

```bash
$ df -i /xfs_mount
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/sdX       10M    5M    5M   50% /xfs_mount

# The "10M max inodes" seen in df -i is just the current maximum
# XFS will increase this as needed (up to available space)
```

The `Inodes` column in `df -i` on XFS shows the **current capacity**, which can grow. On ext4, it's fixed.

### Allocation Groups

XFS divides the filesystem into **allocation groups** (AGs), typically 1 GB each. Each AG manages its own inode and data space independently, allowing parallel allocations on multi-core systems.

## Btrfs — The copy-on-write (CoW) approach

Btrfs is a **copy-on-write** filesystem. It doesn't have a traditional inode table. Instead, inodes are stored in **B-trees** (along with everything else).

- Inodes are allocated dynamically (like XFS)
- Every change creates a new copy (CoW), which affects performance for small random writes
- Related: **subvolumes** and **snapshots** can share inodes via reflinks

```bash
# Btrfs: no inode count configuration
mkfs.btrfs /dev/sdX
```

| Feature | Btrfs |
|---------|-------|
| Inode allocation | **Dynamic** (B-tree based) |
| Pre-allocation | None needed |
| Inode size | Variable |
| Snapshot sharing | ✅ Same inode via reflink |
| Compression | ✅ Built-in (zlib, zstd, lzo) |
| Checksums | ✅ On data and metadata |
| Dynamic inodes | ✅ Yes |

### Btrfs CoW trick — reflinks

```bash
$ cp --reflink=always bigfile copy   # instant, zero disk usage
$ cp --reflink=auto bigfile copy     # CoW if supported, fallback to copy
```

A reflink creates a second directory entry pointing to the **same data extents**. Only when you modify one copy does Btrfs allocate new blocks for the changed parts. This is like a "lazy copy" — similar to a hard link but with copy-on-write semantics.

## ZFS — The pool + dataset approach

ZFS (ported to Linux via OpenZFS) is a **combined volume manager and filesystem**. Like Btrfs, it's CoW with dynamic inodes stored in DMU (Data Management Unit) objects.

| Feature | ZFS |
|---------|-----|
| Inode allocation | **Dynamic** ("objects" in DMU) |
| Pre-allocation | None needed |
| Checksums | ✅ Always on |
| Compression | ✅ LZ4, ZSTD, GZIP |
| Deduplication | ✅ (memory-intensive) |
| Dynamic inodes | ✅ Yes |

## Quick comparison table

| Filesystem | Inode allocation | Can run out of inodes? | Inode size | max inode number |
|-----------|-----------------|----------------------|-----------|-----------------|
| **ext2/3/4** | Fixed at mkfs | ✅ Yes (common) | 128–256 B | ~4 billion |
| **XFS** | Dynamic | ❌ Rarely (shares space with data) | 256–512 B | Available space |
| **Btrfs** | Dynamic (B-tree) | ❌ Rarely | Variable | Available space |
| **ZFS** | Dynamic (DMU objects) | ❌ Rarely | Variable | Available space |
| **tmpfs** | Dynamic (RAM) | ❌ (until RAM fills) | Variable | Available RAM |
| **FAT32** | No inodes (FAT table) | ❌ (uses cluster chain) | N/A | N/A |
| **NTFS** | MFT entries (dynamic) | ❌ Rarely | 1 KB | Available space |

## Which filesystem should you choose for many small files?

| Use case | Recommended | Why |
|----------|------------|-----|
| Mail server (millions of tiny files) | **XFS** | Dynamic inodes, good for many files |
| Database server | **XFS** or **ext4** | Stable, well-tested |
| Large file storage (video, ISOs) | **XFS** or **ext4** (sparse ratio) | ext4 with `-i 65536` to waste fewer inodes |
| Container workloads | **XFS** or **ext4 with many inodes** | Docker/podman use many overlay layers |
| Snapshots + rollback | **Btrfs** or **ZFS** | Built-in snapshot support |
| General desktop | **ext4** (default on most distros) | Simple, reliable, good enough |
| Embedded / small flash | **ext4** with inline data | Tiny files stored in inode, fewer writes |

## The ext4 vs XFS debate

### ext4 wins when:
- You can predict your file count and set inode count at format time
- You want the simplest, most widely understood filesystem
- You need maximum compatibility (all distros, all recovery tools)

### XFS wins when:
- You CAN'T predict your file count
- You have multi-threaded workloads that benefit from allocation groups
- You need to grow the filesystem online

### Common XFS pitfall

XFS's dynamic inodes mean inodes and data share the same pool. If you fill the disk with 99% data and 1% inodes, you can't create new files either — same "No space left" error, but now both resources are tapped out.

## Can I convert between filesystems?

**No, not live.** You must:
1. Back up all data
2. Reformat with the new filesystem
3. Restore data

There is no in-place converter between ext4 ↔ XFS ↔ Btrfs ↔ ZFS. The on-disk structures are fundamentally different.

## Summary

```
ext4:  "Tell me exactly how many files you'll ever have, right now."
XFS:   "Don't worry, just start using it — I'll figure out inodes as needed."
Btrfs: "I'll also deduplicate, compress, snapshot, and checksum everything."
ZFS:   "I'll do everything Btrfs does, but I need more RAM and I'm not GPL."
```
