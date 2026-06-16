# How Directories Work — The Directory Entry (Dirent)

## A directory is just a list of names and inode numbers

On disk, a **directory** is a simple table — not much different from a CSV file. Each row is called a **directory entry** (dirent).

```
Directory "/home/user" (inode #48291)
┌────────────────────────────────────────────┐
│ Name          │ Inode number │ Type        │
├────────────────────────────────────────────┤
│ .             │ 48291        │ directory   │
│ ..            │ 48283        │ directory   │
│ documents     │ 84321        │ directory   │
│ file.txt      │ 8472         │ regular     │
│ notes.md      │ 8473         │ regular     │
│ lost+found    │ 11           │ directory   │
└────────────────────────────────────────────┘
```

Every directory has:
- **`.`** — points to its own inode
- **`..`** — points to its parent's inode

## What happens when you type a path

When you run `cat /home/user/file.txt`, the kernel:

1. **Reads inode #2** (root `/`) — finds the inode for root from the mount table
2. **Reads directory data** of `/` — looks for entry named `home`
3. **Finds inode #48283** for `/home`
4. **Reads directory data** of `/home` — looks for entry named `user`
5. **Finds inode #48291** for `/home/user`
6. **Reads directory data** of `/home/user` — looks for entry named `file.txt`
7. **Finds inode #8472** for `/home/user/file.txt`
8. **Reads the inode** #8472 — gets block pointers
9. **Reads disk blocks** — gets file content

This process is called **path resolution** or **namei** (name-to-inode).

### Performance consideration

Each step is a disk read (or cache hit in the dentry cache). A deep path like `/a/b/c/d/e/f/g/file.txt` requires **8 directory reads** before touching the file data. That's why:

- Deeply nested directories are slow
- The **dentry cache** (dcache) caches resolved paths in memory
- `/` is always inode #2

## The dentry cache

The kernel keeps a cache of recently resolved paths so it doesn't have to walk the directory tree every time:

```
dcache (in memory):
  "/"              → inode 2
  "/home"          → inode 48283
  "/home/user"     → inode 48291
  "/home/user/file.txt" → inode 8472
```

Next time you access `/home/user/file.txt`, the kernel finds it in the dentry cache and skips the directory walk. This cache is why `ls` on a warm directory is fast but cold is slow.

## Directory structure inside a directory entry

An actual dirent structure (ext4):

```c
struct ext4_dir_entry_2 {
    __le32  inode;         // inode number (0 means unused entry)
    __le16  rec_len;       // length of this record (for alignment)
    __u8    name_len;      // length of the name
    __u8    file_type;     // type hint (regular, dir, symlink, etc.)
    char    name[255];     // the actual name
};
```

Each entry is **variable-length** (name can be up to 255 bytes). Entries are packed into 4 KB blocks.

### Deleted files

When you delete a file (`rm`), the kernel:
1. Sets `inode` to 0 in the directory entry (marks it unused)
2. Decrements the inode's link count
3. If link count reaches 0 and no process has the file open: frees the inode and data blocks

The directory entry is **not removed from the directory data** — it's just marked as empty. The space will be reused when a new file is created in that directory.

```
Before rm:
┌────────────────────────────────────┐
│ file.txt   │ inode=8472 │ ...     │
│ notes.md   │ inode=8473 │ ...     │
└────────────────────────────────────┘

After rm file.txt:
┌────────────────────────────────────┐
│ (empty)    │ inode=0    │ ...     │  ← space will be reused
│ notes.md   │ inode=8473 │ ...     │
└────────────────────────────────────┘
```

## Why can't you hard-link directories?

If you could hard-link a directory, you could create a cycle:

```
/usr
  ├── bin
  └── lib ──→ /usr    # hard link back to /usr? cycle!
```

This would break any algorithm that walks the directory tree (find, du, backup tools, the kernel itself). Special entries `.` and `..` are the only allowed hard links to directories, and the kernel manages them directly.

## The maximum filename length

On most Linux filesystems, filenames are limited to **255 bytes** (not characters!). For UTF-8 encoded text, that's usually 255 ASCII characters or ~85 CJK characters (3 bytes each).

The maximum path length is typically **4096 bytes** (the `PATH_MAX` constant).

## Why `rmdir` only works on empty directories

`rmdir` needs the directory's data blocks to only contain `.` and `..`. If there's any other entry, `rmdir` refuses:

```bash
$ mkdir mydir
$ touch mydir/file.txt
$ rmdir mydir
rmdir: failed to remove 'mydir': Directory not empty
```

`rm -rf` works because `rm` deletes the entries first, then removes the directory.

## Fun fact: creating files = writing to the directory

You need **write permission on the directory**, not on the file itself, to create a file:

```bash
$ ls -ld /home/user
drwxr-xr-x user user ...    # you need 'w' here to create files

$ ls -l /home/user/file.txt
-rw-r--r-- user user ...    # you DON'T need 'w' here to delete this file
```

This is because creating/deleting a file only changes the **directory's data** (adds/removes a dirent) — it doesn't touch the file's inode or data blocks.

## Bottom line

| Concept | File | Directory |
|---------|------|-----------|
| Has an inode | ✅ | ✅ |
| Has data blocks | File content | List of dirents |
| Treated as a file | Yes (type `-`) | Yes (type `d`) |
| Opened with `open()` | ✅ | ❌ (uses `opendir`/`readdir`) |
| Symlinkable | ✅ | ✅ |
| Hard-linkable | ✅ | ❌ (except `.` and `..`) |
