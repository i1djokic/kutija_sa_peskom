# Python Basics

## Environment Setup

```bash
# Check version
python --version
python3 --version

# Interactive shell
python
python -c "print('hello')"
```

## Virtual Environment (quick start)

```bash
python -m venv .venv
source .venv/bin/activate   # Linux/macOS
.venv\Scripts\activate      # Windows
```

## Data Types

```python
# Basic types
int: 42
float: 3.14
str: "hello"
bytes: b"raw"
bool: True / False
None: None

# Collections
list: [1, 2, 3]
tuple: (1, 2, 3)
dict: {"key": "value"}
set: {1, 2, 3}
frozenset: frozenset([1, 2, 3])
```

## Type Annotations

```python
name: str = "Alice"
count: int = 10
items: list[str] = ["a", "b"]
mapping: dict[str, int] = {"x": 1}

def greet(name: str) -> str:
    return f"Hello, {name}"
```

## Control Flow

```python
# if / elif / else
if x > 0:
    print("positive")
elif x == 0:
    print("zero")
else:
    print("negative")

# match (Python 3.10+)
match status:
    case 200:
        print("OK")
    case 404:
        print("Not found")
    case _:
        print("Unknown")

# for loop
for item in items:
    print(item)

for i, item in enumerate(items, start=1):
    print(f"{i}: {item}")

# while loop
while count > 0:
    count -= 1

# Comprehensions
squares = [x**2 for x in range(10)]
evens = [x for x in range(10) if x % 2 == 0]
mapping = {k: v for k, v in pairs}
```

## Context Managers

```python
with open("file.txt") as f:
    data = f.read()

# Custom context manager
from contextlib import contextmanager

@contextmanager
def managed_resource():
    resource = acquire()
    try:
        yield resource
    finally:
        release(resource)
```

## Useful stdlib modules for automation

| Module | Purpose |
|--------|---------|
| `os` | OS interfaces, env vars, paths |
| `sys` | Interpreter control, argv |
| `pathlib` | Modern path handling |
| `shutil` | High-level file ops |
| `subprocess` | Run shell commands |
| `glob` | File pattern matching |
| `fnmatch` | Unix-style pattern matching |
| `json` / `csv` / `configparser` | Data formats |
| `argparse` | CLI argument parsing |
| `logging` | Logging framework |
| `re` | Regular expressions |
| `tempfile` | Temporary files/dirs |
| `functools` | Higher-order functions |
| `itertools` | Iterator tools |

## Script boilerplate

```python
#!/usr/bin/env python3
"""Short description of this script."""

import argparse
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s",
)
log = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Script description")
    parser.add_argument("input", help="Input file path")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    log.debug("Starting with args: %s", args)
    # ... logic here ...
    log.info("Done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```
