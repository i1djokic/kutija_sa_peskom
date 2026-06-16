# CLI Tools & Scripting

## Argument Parsing with getopts

```bash
#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 [-v] [-c CONFIG] [-n] [name]"
    echo "  -v          Verbose mode"
    echo "  -c CONFIG   Config file path"
    echo "  -n          Dry run"
    exit 1
}

# Initialize
VERBOSE=0
CONFIG=""
DRY_RUN=0

while getopts "vc:nh" opt; do
    case "$opt" in
        v) VERBOSE=1 ;;
        c) CONFIG="$OPTARG" ;;
        n) DRY_RUN=1 ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

# Optional positional arg
NAME="${1:-default}"

# Dry run wrapper
run() {
    if (( DRY_RUN )); then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

run systemctl restart nginx
```

## Manual Argument Parsing (for complex needs)

```bash
#!/bin/bash
set -euo pipefail

usage() { echo "Usage: $0 --env=ENV --action=ACTION"; exit 1; }

# Parse --key=value style
for arg in "$@"; do
    case "$arg" in
        --env=*) ENV="${arg#*=}" ;;
        --action=*) ACTION="${arg#*=}" ;;
        --help) usage ;;
        *) echo "Unknown: $arg"; usage ;;
    esac
done

# Parse --key value style
while [[ $# -gt 0 ]]; do
    case "$1" in
        --env) ENV="$2"; shift 2 ;;
        --action) ACTION="$2"; shift 2 ;;
        --) shift; break ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done
```

## Standard CLI Conventions

```bash
# Follow POSIX/Unix conventions
# - Short flags: single dash, single letter
# - Long flags: double dash, word
# - Positional args after flags
# - -- signals end of options
# - Exit 0 for success, non-zero for error

# Color output
if [[ -t 1 ]]; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    NC=$(tput sgr0)  # no color
else
    GREEN="" RED="" NC=""
fi

echo "${GREEN}OK${NC}"
echo "${RED}FAIL${NC}"
```

## Progress / Spinner

```bash
spinner() {
    local pid=$1
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r[%c] %s" "${spin:$i:1}" "$2"
        i=$(( (i+1) % ${#spin} ))
        sleep 0.1
    done
    printf "\r"
}

# Usage
long_running_task &
spinner $! "Processing..."
wait
echo "Done"
```

## Idempotency in CLI Scripts

```bash
# Accept --force to override idempotent checks
FORCE=0

# Pattern: skip if already done
if [[ -L "/etc/nginx/sites-enabled/default" ]] && (( ! FORCE )); then
    echo "Already configured — skipping (use --force to override)"
    exit 0
fi
```
