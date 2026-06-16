# Error Handling & Logging

## Exceptions

### Try / Except / Else / Finally

```python
try:
    result = risky_operation()
except ValueError as e:
    log.error("Invalid value: %s", e)
    raise
except (IOError, OSError) as e:
    log.error("IO error: %s", e)
    return None
else:
    log.info("Success: %s", result)
    return result
finally:
    cleanup()
```

### Raising Exceptions

```python
def validate_port(port: int) -> None:
    if not 1 <= port <= 65535:
        raise ValueError(f"Invalid port: {port}")

# Chain exceptions (Python 3.11+)
try:
    connect()
except ConnectionError as e:
    raise RuntimeError("Failed to connect") from e
```

### Custom Exceptions

```python
class AutomationError(Exception):
    """Base exception for automation tools."""

class ConfigError(AutomationError):
    """Configuration related errors."""

class ExecutionError(AutomationError):
    """Command execution failures."""

    def __init__(self, command: str, exit_code: int, stderr: str = "") -> None:
        self.command = command
        self.exit_code = exit_code
        self.stderr = stderr
        super().__init__(f"'{command}' failed with code {exit_code}: {stderr}")
```

### Common patterns

```python
# Suppress known errors
from contextlib import suppress

with suppress(FileNotFoundError):
    Path("temp.txt").unlink()

# Retry logic
import time
from functools import wraps

def retry(max_attempts: int = 3, delay: float = 1.0):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts:
                        raise
                    log.warning("Attempt %d failed: %s", attempt, e)
                    time.sleep(delay * attempt)
            return None
        return wrapper
    return decorator
```

## Logging

### Basic setup

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)
```

### Best practices

```python
# Module-level logger
log = logging.getLogger(__name__)

# Level usage
log.debug("Detailed debug info")       # development
log.info("Operation completed")         # normal operation
log.warning("Disk space low")           # unexpected but not error
log.error("Failed to connect")          # error, but continue
log.critical("System halted")           # unrecoverable

# Always use %-formatting (lazy evaluation)
log.debug("Processing %d items", count)  # good
log.debug(f"Processing {count} items")   # bad (always evaluated)
```

### Logging to file + stdout

```python
def setup_logging(verbose: bool = False, log_file: str | None = None) -> None:
    handlers: list[logging.Handler] = [
        logging.StreamHandler(),
    ]
    if log_file:
        handlers.append(logging.RotatingFileHandler(
            log_file, maxBytes=10_485_760, backupCount=5,
        ))
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
        handlers=handlers,
    )
```

### Structured logging

```python
import structlog  # third-party, commonly used in production

log = structlog.get_logger()
log.info("request", method="GET", path="/health", status=200)
```

### Logging configuration via dict

```python
import logging.config

LOGGING_CONFIG = {
    "version": 1,
    "formatters": {
        "standard": {"format": "%(asctime)s  %(levelname)-8s  %(message)s"},
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "standard",
            "level": "INFO",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
}

logging.config.dictConfig(LOGGING_CONFIG)
```
