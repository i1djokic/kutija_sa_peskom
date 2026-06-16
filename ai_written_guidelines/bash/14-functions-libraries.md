# Functions & Libraries

## Function Basics

```bash
# Define
log() {
    local level="$1" msg="$2"
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] [$level] $msg"
}

# Call
log "INFO" "Deployment started"

# Return value
is_root() {
    [[ "$EUID" -eq 0 ]]
}
if is_root; then ...; fi

# Return data (use stdout)
get_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    fi
}
os=$(get_os)
```

## Best Practices

```bash
# Always use local (prevents polluting global scope)
myfunc() {
    local var="$1"
    readonly CONSTANT=42       # Prevent reassignment
    declare -a items           # Local array
    declare -A map             # Local associative array
}

# Name return value variables distinct from global
myfunc() {
    local input="$1" _result
    _result="processed_${input}"
    echo "$_result"
}
```

## Libraries / Shared Scripts

```bash
# In lib/common.sh
log()   { echo "[$(date +%Y-%m-%dT%H:%M:%S)] $*"; }
die()   { echo "[FATAL] $*" >&2; exit 1; }
usage() { echo "Usage: $0 [-v] [-c CONFIG]"; exit 1; }

# In your main script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/lib/common.sh"

log "INFO" "Script started"
```

## Guard Against Repeated Sourcing

```bash
# In lib/common.sh
[[ -n "$_COMMON_SH" ]] && return
_COMMON_SH=1

# script continues...
```

## Passing Functions to Other Commands

```bash
# Use export -f for subprocesses
filter_json() {
    jq '.items[] | select(.status == "running")'
}
export -f filter_json

somecmd --format json | bash -c filter_json
```

## Function Composition & Pipelines

```bash
# Pipe-friendly functions
strip_comments() { grep -v '^\s*#'; }
skip_empty()     { grep -v '^\s*$'; }
sort_unique()    { sort -u; }

cat config.conf | strip_comments | skip_empty | sort_unique
```
