# Script Safety & Strict Mode

## Non-Negotiable Header

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
```

| Directive | Effect |
|-----------|--------|
| `set -e` | Exit immediately on any command failure |
| `set -u` | Treat unset variables as an error (with expansion) |
| `set -o pipefail` | Return exit code of the *last* (or any) failed command in a pipeline |
| `IFS=$'\n\t'` | Only newline/tab for word splitting (spaces no longer split words) |

## Exceptions to `set -e`

```bash
# Commands that may fail without being fatal
cmd || true                           # ok if cmd fails
if cmd; then ... fi                   # conditional — safe
while cmd; do ... done                # loop condition — safe
```

## Quoting Rules

```bash
# Always quote — even when you think you don't need to
"$var"           # correct
"${array[@]}"    # array expansion — quote!
"$@"             # positional params — quote!
"$*"             # all args as single string
"$(cmd)"         # command substitution — quote!

# The one exception: [[ ]] doesn't need quotes on lhs
[[ $var == "$pattern" ]]    # fine (word splitting already disabled)
[[ -f $file ]]              # fine inside [[ ]]
```

## Common Pitfalls

```bash
# Pitfall 1: for loops with globs
# Wrong: fails if no .log files
for f in *.log; do echo "$f"; done
# Correct:
shopt -s nullglob
for f in *.log; do echo "$f"; done

# Pitfall 2: reading output with spaces
while IFS= read -r line; do ... done < file  # preserves spaces

# Pitfall 3: cd may fail
cd /nonexistent && do_something        # safe
cd /nonexistent || die "cd failed"     # explicit

# Pitfall 4: unbound variables in conditionals
# Wrong: triggers -u error
if [[ "$optional" == "yes" ]]; then ...
# Correct: use default
if [[ "${optional:-}" == "yes" ]]; then ...
```

## Idempotency Pattern

```bash
# Only act if needed — safe to run repeatedly
create_user() {
    local user="$1" key="$2"
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash "$user"
    fi
    mkdir -p "/home/$user/.ssh"
    echo "$key" > "/home/$user/.ssh/authorized_keys"
    chown -R "$user:" "/home/$user/.ssh"
    chmod 700 "/home/$user/.ssh"
    chmod 600 "/home/$user/.ssh/authorized_keys"
}

# Same pattern for other resources
[[ -d "$dir" ]] || mkdir -p "$dir"
[[ -L "$link" ]] || ln -s "$target" "$link"
command -v pkg &>/dev/null || install_pkg "$pkg"
```

## Naming Conventions

| Scope | Convention | Example |
|-------|-----------|---------|
| Global constants | `UPPER_CASE` | `readonly MAX_RETRIES=3` |
| Global variables | `lower_case` | `config_file="/etc/myapp.conf"` |
| Local variables | `lower_case` | `local username="$1"` |
| Environment | `UPPER_CASE` | `DEBUG=1`, `DRY_RUN=true` |
| Internal/private | prefix with `_` | `_internal_func` |

## Cross-Platform Portability

```bash
# OS detection
case "$OSTYPE" in
    linux*)   SEP="/"; SED="sed" ;;
    darwin*)  SEP="/"; SED="gsed" ;;  # need coreutils
    cygwin*)  SEP="\\" ;;
    *)        die "Unsupported OS: $OSTYPE" ;;
esac

# Shebang must be absolute
#!/bin/bash          # correct
#!/usr/bin/env bash   # more portable (prefer for scripts shared across systems)
```
