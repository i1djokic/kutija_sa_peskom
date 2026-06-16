# The Trailing Slash Rule

The trailing `/` on the source path is the #1 source of rsync confusion. It changes what gets copied.

## The Rule

```
With trailing slash:   copy the contents of the source
Without trailing slash: copy the source directory itself
```

## Example

```
/source/
├── file1.txt
├── file2.txt
└── subdir/
```

### Without trailing slash

```bash
rsync -av /source /dest/
```

Result:
```
/dest/
└── source/                  ← source directory itself
    ├── file1.txt
    ├── file2.txt
    └── subdir/
```

### With trailing slash

```bash
rsync -av /source/ /dest/
```

Result:
```
/dest/                       ← contents of source
├── file1.txt
├── file2.txt
└── subdir/
```

## On the Destination

The trailing `/` on destination doesn't change behavior — both are equivalent:

```bash
rsync -av /source/ /dest/     # Same result
rsync -av /source/ /dest      # Same result
```

## Practical Tip

**Always use trailing slashes** on both source and destination unless you specifically want to create a subdirectory. This makes behavior predictable:

```bash
# Copy contents of src/ into dest/
rsync -av ./src/ ./dest/

# Not: rsync -av ./src ./dest/  (creates dest/src/)
```

## Quick Table

| Command | What happens |
|---------|-------------|
| `rsync -av /src/ /dst/` | Contents of `src` go into `dst` |
| `rsync -av /src /dst/` | `src` itself goes into `dst` → `dst/src` |
| `rsync -av /src/ /dst` | Same as first (contents into dst) |
| `rsync -av /src /dst` | Same as second (src into dst) |
