# Bash Best Practices

## DRY — Don't Repeat Yourself

```bash
# Bad: repeated logic
echo "Backing up /var/lib/mysql..."
rsync -av /var/lib/mysql/ /backup/mysql/
echo "Backup of /var/lib/mysql complete"

echo "Backing up /var/www..."
rsync -av /var/www/ /backup/www/
echo "Backup of /var/www complete"

# Good: reusable function
backup_dir() {
    local src="$1" dest="$2"
    echo "Backing up $src..."
    rsync -av "$src" "$dest/"
    echo "Backup of $src complete"
}

backup_dir /var/lib/mysql /backup/mysql
backup_dir /var/www /backup/www
```

## Idempotency — Safe to Run Repeatedly

```bash
# Bad: fails on second run
mkdir /opt/myapp
useradd -m myapp

# Good: safe to run repeatedly
[[ -d /opt/myapp ]] || mkdir -p /opt/myapp
id myapp &>/dev/null || useradd -m myapp

# Pattern: only act if needed
create_symlink() {
    local target="$1" link="$2"
    [[ -L "$link" && "$(readlink "$link")" == "$target" ]] && return 0
    ln -sf "$target" "$link"
}

append_line() {
    local file="$1" line="$2"
    grep -qxF "$line" "$file" || echo "$line" >> "$file"
}
```

## Error Handling Pattern

```bash
# Consistent error pattern: always exit with clear message
cmd || { echo "Error: cmd failed"; exit 1; }

# Or use a die helper
die() {
    echo "[FATAL] $*" >&2
    exit 1
}

cmd || die "cmd failed"
```

## Naming Conventions

```bash
# Constants — uppercase
readonly MAX_RETRIES=3
readonly DEFAULT_PORT=8080

# Global variables — lowercase (export if needed)
config_file="/etc/myapp.conf"
verbose=0

# Local variables — lowercase, use local
myfunc() {
    local user="$1" key="$2"
}

# Environment variables — uppercase, exported
export DEBUG=1
export DRY_RUN=true

# Internal/private — prefix with underscore
_validate_input() { ... }
```

## Modularization

```
project/
├── bin/           # Entry point scripts
├── lib/           # Shared libraries
│   ├── common.sh  # log, die, usage
│   ├── db.sh      # database functions
│   └── deploy.sh  # deployment functions
├── conf/          # Configuration
│   └── config.sh
└── tests/         # Test scripts
    └── test_deploy.sh
```

```bash
# lib/common.sh
[[ -n "$_COMMON_SH" ]] && return
_COMMON_SH=1

log()   { echo "[$(date +%Y-%m-%dT%H:%M:%S)] $*"; }
die()   { echo "[FATAL] $*" >&2; exit 1; }
usage() { echo "Usage: $0 [-v] [-c CONFIG]"; exit 1; }

# bin/deploy.sh
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/lib/common.sh"
```

## Idempotency Table

| Operation | Idempotent Pattern |
|-----------|-------------------|
| Create dir | `mkdir -p "$dir"` |
| Create user | `id "$user" &>/dev/null \|\| useradd ...` |
| Install pkg | `dpkg -s "$pkg" &>/dev/null \|\| apt install -y "$pkg"` |
| Set config | `grep -qFx "setting" "$file" \|\| echo "setting" >> "$file"` |
| Create symlink | `ln -sf "$target" "$link"` |
| Copy file | `cp -u "$src" "$dst"` (update only) |
| Cron job | `(crontab -l 2>/dev/null \| grep -F "$job") \|\| ...` |
| Start service | `systemctl is-active --quiet "$svc" \|\| systemctl start "$svc"` |

## Common Anti-Patterns

```bash
# 1. Parsing ls output
# Bad:
for f in $(ls *.txt); do ...
# Good:
for f in *.txt; do ...

# 2. Unquoted variables
# Bad:
if [ $var = "yes" ]; ...
# Good:
if [[ "$var" == "yes" ]]; ...

# 3. Using bc for simple integer math
# Bad:
result=$(echo "$a + $b" | bc)
# Good:
result=$(( a + b ))

# 4. cat with pipe
# Bad:
cat file | grep pattern
# Good:
grep pattern file

# 5. eval
# Bad:
eval "cmd=$user_input"
# Never use eval with user input

# 6. Backticks (deprecated)
# Bad:
output=`cmd`
# Good:
output=$(cmd)
```

## Performance Tips

```bash
# Use built-in over external commands
# Bad:
grep -c "foo" file.txt
# Good:
count=0; while IFS= read -r line; do [[ "$line" == *foo* ]] && ((count++)); done < file.txt
# (Only for huge files — grep is usually fine)

# Parallelize independent tasks
task1 &
task2 &
wait

# Use mapfile for reading files (faster than while-read)
mapfile -t lines < file.txt

# Avoid pipes in loops (use process substitution instead)
while IFS= read -r line; do
    ...
done < <(cmd)
```
