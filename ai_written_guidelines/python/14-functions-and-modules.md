# Functions & Modules

## Functions

### Definition

```python
def add(a: int, b: int) -> int:
    return a + b
```

### Default & Keyword Arguments

```python
def connect(host: str, port: int = 443, timeout: float = 30.0) -> Connection:
    ...

# Call with keyword args
connect("example.com", timeout=10.0)
```

### `*args` and `**kwargs`

```python
def log_all(level: str, *messages: str, **metadata: str) -> None:
    print(f"[{level}]", *messages)
    for k, v in metadata.items():
        print(f"  {k}={v}")

log_all("INFO", "start", "end", user="alice", env="prod")
```

### Lambda

```python
square = lambda x: x**2
sorted(items, key=lambda x: x[1])
```

### Decorators

```python
import functools
import time

def timer(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.3f}s")
        return result
    return wrapper

@timer
def slow_operation():
    time.sleep(1)
```

### Partial Application

```python
from functools import partial

def power(base: float, exp: float) -> float:
    return base ** exp

square = partial(power, exp=2)
cube = partial(power, exp=3)
```

## Modules & Packages

### Structure

```
project/
  pyproject.toml
  src/
    mypkg/
      __init__.py
      cli.py
      utils.py
  tests/
```

### `__init__.py`

```python
# src/mypkg/__init__.py
from .cli import main
from .utils import helper

__all__ = ["main", "helper"]
```

### Import variations

```python
import os
from pathlib import Path
from mypkg import main
from mypkg.utils import helper as h
```

### `if __name__ == "__main__"`

```python
def main() -> int:
    ...

if __name__ == "__main__":
    import sys
    sys.exit(main())
```

## Best Practices

- Functions should do **one thing**
- Use type hints for all public APIs
- Keep functions small (< 30 lines ideally)
- Use descriptive names (`calculate_total`, not `calc`)
- Prefer `pathlib` over `os.path`
- Use `functools.wraps` in decorators
- Export only what's needed via `__all__`
