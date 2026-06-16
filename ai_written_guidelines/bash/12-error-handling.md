# Error Handling & Debugging

## Exit Codes

```bash
# Every command returns a code
success  # exits 0
failure  # exits non-zero

# Check exit code
cmd
if [[ $? -eq 0 ]]; then
    echo "Success"
fi

# Use directly in conditions (preferred)
if cmd; then
    echo "Success"
fi
```

## Strict Mode

```bash
#!/bin/bash
set -euo pipefail

# -e : exit on error
# -u : error on undefined variable
# -o pipefail : fail if any pipe stage fails
# -E : inherit trap on ERR
```

## Custom Error Handling

```bash
# Die helper
die() {
    echo "[FATAL] $*" >&2
    exit 1
}

cmd || die "cmd failed"
cmd || { echo "cmd failed"; exit 1; }

# Error handler with line info
error_handler() {
    echo "Error on line $1"
    exit 1
}
trap 'error_handler $LINENO' ERR
```

## Trap

```bash
cleanup() {
    rm -f /tmp/lock-$$
    echo "Cleaned up"
}
trap cleanup EXIT          # Always runs on exit
trap ':' INT               # Ignore SIGINT
trap 'echo "Signal received"; exit 1' TERM INT

# Multiple signals, different handlers
trap 'cleanup; exit 1' INT TERM
trap 'cleanup' EXIT
```

## Assertions

```bash
assert() {
    if [[ ! "$1" ]]; then
        echo "Assertion failed: $1" >&2
        exit 1
    fi
}

# Usage
assert "[[ -f /etc/config.yml ]]"
assert "[[ -n "${DB_HOST:-}" ]]"
```

## Debugging

```bash
# Trace execution (prints commands before running)
bash -x script.sh
# Or inline
set -x
# ... commands to debug ...
set +x

# Dry run
if [[ -n "${DRY_RUN:-}" ]]; then
    echo "Would run: cmd $args"
else
    cmd "$args"
fi

# Verbose logging
debug() {
    [[ -n "${DEBUG:-}" ]] && echo "[DEBUG] $*"
}
VERBOSE=${VERBOSE:-0}
(( VERBOSE > 0 )) && echo "Detailed info"
```
