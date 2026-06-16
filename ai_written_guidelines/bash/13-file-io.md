# File I/O & Path Manipulation

## Reading Files

```bash
# Line by line (safest — handles missing trailing newline)
while IFS= read -r line; do
    echo "$line"
done < /etc/hosts

# Read into array
mapfile -t lines < /etc/hosts

# Entire file into variable
content=$(< /etc/hosts)
```

## Writing Files

```bash
# Overwrite
echo "content" > file.txt

# Append
echo "content" >> file.txt

# Multi-line
cat > file.txt << 'EOF'
line1
line2
EOF

# Append multi-line
cat >> file.txt << 'EOF'
line3
EOF

# With sudo
echo "config" | sudo tee -a /etc/myapp.conf > /dev/null
```

## Path Manipulation

```bash
# Parameter expansion (no external commands)
path="/home/user/docs/file.txt"

echo "${path##*/}"        # file.txt           (basename)
echo "${path%/*}"         # /home/user/docs    (dirname)
echo "${path%.*}"         # /home/user/docs/file  (strip ext)
echo "${path##*.}"        # txt                (extension)

# Or use real commands
basename "$path"          # file.txt
dirname "$path"           # /home/user/docs
realpath "$path"          # absolute path (resolves symlinks)
readlink -f "$path"       # resolve all symlinks
```

## Temp Files (Safe)

```bash
# Always use mktemp — never hardcode /tmp/
tempfile=$(mktemp)
trap 'rm -f "$tempfile"' EXIT

tempdir=$(mktemp -d)
trap 'rm -rf "$tempdir"' EXIT

# Clean up on specific signals too
cleanup() { rm -rf "$tempdir"; }
trap cleanup EXIT INT TERM
```

## File Locking (Prevent Concurrent Runs)

```bash
lockfile="/var/run/myapp.lock"
exec 200>"$lockfile"
if ! flock -n 200; then
    echo "Script already running" >&2
    exit 1
fi

# Lock released automatically when script exits
```

## Globbing Patterns

```bash
shopt -s nullglob    # empty glob = nothing (not literal pattern)
shopt -s dotglob     # include hidden files
shopt -s globstar    # ** for recursive

# Count files
files=( *.log )
echo "${#files[@]}"  # number of .log files

# Multi-pattern
for f in /etc/*.conf /etc/*.cfg; do
    echo "$f"
done
```
