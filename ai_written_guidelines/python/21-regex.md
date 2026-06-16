# Regular Expressions

## Basics

```python
import re

pattern = r"\d{3}-\d{4}"   # raw string (no escape issues)
text = "Phone: 555-1234"

match = re.search(pattern, text)
if match:
    print(match.group())    # "555-1234"
```

## Common Patterns

| Pattern | Matches |
|---------|---------|
| `\d+` | One or more digits |
| `\w+` | One or more word chars `[a-zA-Z0-9_]` |
| `\s+` | One or more whitespace |
| `.` | Any char except newline |
| `^` | Start of string |
| `$` | End of string |
| `[a-z]` | Range |
| `[^0-9]` | Negation |
| `(foo\|bar)` | Alternation |
| `(?:...)` | Non-capturing group |

## Core Functions

```python
# re.search  - first match anywhere
m = re.search(r"error", log_line)

# re.match   - match at start of string
m = re.match(r"\d+", line)

# re.findall - all matches as strings
ips = re.findall(r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", text)

# re.finditer - all matches as match objects
for m in re.finditer(r"\d+", text):
    print(m.group(), m.start(), m.end())

# re.split
parts = re.split(r"[,;]\s*", csv_line)

# re.sub
cleaned = re.sub(r"\s+", "_", text)
```

## Compiled Patterns

```python
LOG_PATTERN = re.compile(
    r"^(\S+) (\S+) (\S+) \[([^\]]+)\]"  # host ident user date
    r' "(\S+) (\S+) (\S+)"'               # method path proto
    r" (\d{3}) (\d+)"                     # status size
)

m = LOG_PATTERN.search(line)
if m:
    host, method, path, status = m.group(1), m.group(5), m.group(6), m.group(8)
```

## Named Groups

```python
pattern = re.compile(
    r"^(?P<ip>\S+) \S+ \S+ \[(?P<date>[^\]]+)\]"
    r' "(?P<method>\S+) (?P<path>\S+)"'
    r" (?P<status>\d{3})"
)

m = pattern.search(line)
if m:
    print(m.groupdict())
    # {"ip": "...", "date": "...", "method": "GET", "path": "...", "status": "200"}
```

## Practical Examples for DevOps

### Parsing /etc/hosts

```python
HOSTS_LINE = re.compile(r"^\s*(\S+)\s+(\S+)")

hosts = {}
for line in Path("/etc/hosts").read_text().splitlines():
    if line.strip() and not line.startswith("#"):
        m = HOSTS_LINE.match(line)
        if m:
            hosts[m.group(2)] = m.group(1)
```

### Parsing key=value configs

```python
KV = re.compile(r"^\s*(\w+)\s*=\s*(.*?)\s*$")

config = {}
for line in text.splitlines():
    m = KV.match(line)
    if m:
        config[m.group(1)] = m.group(2)
```

### URL validation

```python
URL_RE = re.compile(
    r"^https?://"
    r"(?:[-\w.]|%[a-fA-F0-9]{2})+"
    r"(?::\d+)?"
    r"(?:/[-\w./~%+]*)?"
    r"(?:\?[-\w=&.~%+]*)?"
    r"(?:#\w+)?$"
)
```

## Flags

```python
re.IGNORECASE  / re.I   # case insensitive
re.MULTILINE   / re.M   # ^/$ match per line
re.DOTALL      / re.S   # . matches newline
re.VERBOSE     / re.X   # allow comments in pattern
```

## Performance tip

```python
# Always compile patterns used in loops
pattern = re.compile(r"...")
for line in large_file:
    if pattern.search(line):
        ...
```
