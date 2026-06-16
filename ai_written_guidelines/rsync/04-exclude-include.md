# Exclude & Include

Filter files by name, path, or pattern.

## Excluding Files

```bash
# Exclude a single pattern
rsync -av --exclude='*.log' /src/ /dst/

# Exclude a directory
rsync -av --exclude='node_modules' /src/ /dst/

# Exclude multiple patterns
rsync -av \
    --exclude='*.log' \
    --exclude='.git' \
    --exclude='tmp/' \
    /src/ /dst/
```

## Including Files

Use `--include` with `--exclude` to only sync specific files:

```bash
# Only sync .txt files, exclude everything else
rsync -av --include='*.txt' --exclude='*' /src/ /dst/
```

Order matters: the first matching rule wins. Rsync processes `--include` and `--exclude` rules in order.

## Pattern Rules

```bash
# Wildcards
--exclude='*.tmp'           # Exclude all .tmp files anywhere
--exclude='build/'          # Exclude build directories (trailing / = directory only)

# Anchored vs unanchored
--exclude='.git'            # Exclude .git anywhere in the tree
--exclude='/.git'           # Exclude .git only at the root (leading / anchors to root)

# Negation
--include='/src/'            # Include src directory so its contents are traversed
--exclude='*'                # Then exclude everything else
```

## Using a Filter File

For complex rules, put them in a file:

```
# rsync-filter.txt
+ /src/**
- *.tmp
- .git/
- node_modules/
```

```bash
rsync -av --filter='. rsync-filter.txt' /src/ /dst/
```

## --exclude-from

Read exclude patterns from a file:

```
# excludes.txt
*.log
.git
node_modules
tmp/
```

```bash
rsync -av --exclude-from=excludes.txt /src/ /dst/
```

## --include-from

Same for include patterns:

```bash
rsync -av --include-from=includes.txt --exclude='*' /src/ /dst/
```

## --max-size / --min-size

Filter by file size:

```bash
# Skip files larger than 10MB
rsync -av --max-size=10M /src/ /dst/

# Skip files smaller than 1KB
rsync -av --min-size=1K /src/ /dst/
```

## --filter

The `--filter` option gives you fine-grained control with rules like:

```bash
# Exclude everything except .txt files
rsync -av --filter='+ */' --filter='+ *.txt' --filter='- *' /src/ /dst/
```

## Common Exclude Patterns

```bash
# Typical project sync
rsync -av \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.DS_Store' \
    --exclude='*.log' \
    --exclude='tmp/' \
    --exclude='.cache' \
    /src/ /dst/
```

## Tips

- Patterns without `/` match anywhere in the tree
- Leading `/` anchors the pattern to the transfer root
- Trailing `/` only matches directories
- `*` matches within a single path component
- `**` matches across path components
