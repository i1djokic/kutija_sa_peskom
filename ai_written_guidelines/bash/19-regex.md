# Regular Expressions in Bash

## grep — Search with Regex

```bash
# Basic regex (BRE) — default
grep 'error\.[0-9]\+' log.txt          # \+ is BRE for "one or more"
grep '^[^#]' config.conf               # lines not starting with #

# Extended regex (ERE) — grep -E
grep -E 'error\.[0-9]+' log.txt        # + is literal in ERE
grep -E 'ERROR|CRITICAL' log.txt       # alternation
grep -E '^[A-Z]{3}-[0-9]{4}' data.txt  # e.g., ABC-1234

# Perl-compatible (PCRE) — grep -P
grep -P '\d{3}-\d{4}' file.txt         # \d is digit
grep -P '(?<=error:)\s*\w+' log.txt    # lookbehind
```

## sed — In-Place Regex

```bash
# Substitute
sed 's/foo/bar/' file.txt               # first occurrence
sed 's/foo/bar/g' file.txt              # all occurrences
sed -E 's/[0-9]+/NUM/g' file.txt       # ERE in sed with -E
sed -E 's/^#(.*)/\1/' file.txt         # strip leading comment
sed -E 's/^(\w+) (\w+)/\2 \1/' file.txt # swap words

# Capture groups — sed uses \(\) (BRE) or () (with -E)
# BRE:
sed 's/\(foo\)bar/\1baz/' file.txt
# ERE (preferred):
sed -E 's/(foo)bar/\1baz/' file.txt

# Delete matching lines
sed '/^#\|^$/d' file.txt                # delete comments + empties
sed -E '/^[0-9]{3}-/d' file.txt         # delete lines starting with 3 digits + dash
```

## [[ =~ ]] — Bash Internal Regex

```bash
# Pattern matching in [[ ]] uses ERE (no escaping needed)
if [[ "$line" =~ ^[A-Z]+-[0-9]+ ]]; then
    echo "Matches pattern"
fi

# Capture groups — BASH_REMATCH
if [[ "$line" =~ ^([A-Z]+)-([0-9]+)$ ]]; then
    echo "Prefix: ${BASH_REMATCH[1]}"
    echo "Number: ${BASH_REMATCH[2]}"
fi

# Validate input
validate_email() {
    local email="$1"
    [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_ipv4() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
    # Verify each octet
    IFS=. read -r o1 o2 o3 o4 <<< "$ip"
    (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 ))
}
```

## Common Regex Patterns

| Purpose | Pattern | Tool |
|---------|---------|------|
| IPv4 address | `^([0-9]{1,3}\.){3}[0-9]{1,3}$` | grep -E, [[ =~ ]] |
| Email | `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$` | [[ =~ ]] |
| URL | `https?://[a-zA-Z0-9./?=_-]+` | grep -oE |
| Hostname (FQDN) | `^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$` | grep -E |
| UUID | `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}` | grep -E |
| ISO date | `^\d{4}-\d{2}-\d{2}$` | grep -E |
| Timestamp | `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}` | grep -E |
| MAC address | `^([0-9a-f]{2}:){5}[0-9a-f]{2}$` | grep -E |
| Port number | `^[0-9]{1,5}$` (check range separately) | grep -E + numeric check |

## In-Action Examples

```bash
# Extract all URLs from log
grep -oE 'https?://[a-zA-Z0-9./?=_-]+' access.log | sort -u

# Parse key=value lines
if [[ "$line" =~ ^([a-zA-Z_]+)=(.+)$ ]]; then
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    echo "Key: $key, Value: $value"
fi

# Strip ANSI color codes
sed -E 's/\x1b\[[0-9;]*m//g' colored_output.txt

# Find lines with duplicate words
grep -P '(\b\w+\b)\s+\1' file.txt

# Validate semver
semver="^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z.-]+))?(\+([0-9A-Za-z.-]+))?$"
if [[ "$version" =~ $semver ]]; then
    echo "Major: ${BASH_REMATCH[1]}"
    echo "Minor: ${BASH_REMATCH[2]}"
    echo "Patch: ${BASH_REMATCH[3]}"
fi
```
