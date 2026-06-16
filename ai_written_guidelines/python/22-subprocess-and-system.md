# Subprocess & System Automation

## subprocess (modern usage)

```python
import subprocess
import shlex

# Run command, get output
result = subprocess.run(
    ["ls", "-la", "/tmp"],
    capture_output=True,
    text=True,
    check=False,
)
print(result.returncode)
print(result.stdout)
print(result.stderr)

# With shell (use with caution)
result = subprocess.run(
    "cat *.log | grep error",
    shell=True,
    capture_output=True,
    text=True,
)
```

## subprocess.run() parameters

| Parameter | Purpose |
|-----------|---------|
| `args` | Command as list or string (with `shell=True`) |
| `capture_output=True` | Capture stdout/stderr |
| `text=True` | Return strings instead of bytes |
| `check=True` | Raise `CalledProcessError` on non-zero exit |
| `timeout=N` | Timeout in seconds |
| `env=dict` | Custom environment variables |
| `cwd=path` | Working directory |
| `input=str` | Send data to stdin |

## Handling errors

```python
import subprocess

def run_cmd(cmd: list[str], timeout: int = 30) -> str:
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
            timeout=timeout,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        log.error("Command failed: %s\n%s", e.cmd, e.stderr)
        raise
    except subprocess.TimeoutExpired as e:
        log.error("Command timed out after %ds: %s", timeout, e.cmd)
        raise
```

## Running commands silently

```python
subprocess.run(
    cmd,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    check=True,
)
```

## Piping commands

```python
p1 = subprocess.Popen(["grep", "error"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
p2 = subprocess.Popen(["wc", "-l"], stdin=p1.stdout, stdout=subprocess.PIPE, text=True)
p1.stdout.close()
output, _ = p2.communicate(input=large_text)
print(output.strip())
```

## shlex (safe shell argument parsing)

```python
import shlex

# Safe split of command string
cmd = shlex.split('ls -la "/path/with spaces/file"')

# Quote for shell
safe = shlex.quote(user_input)
subprocess.run(f"grep {safe} /var/log/syslog", shell=True)
```

## os module

```python
import os

# Environment
os.environ.get("PATH")
os.environ["MY_VAR"] = "value"
os.unsetenv("MY_VAR")

# Process
os.getpid()
os.getcwd()
os.chdir("/tmp")
os.listdir(".")

# Filesystem
os.mkdir("dir", mode=0o755)
os.makedirs("a/b/c", exist_ok=True)
os.remove("file.txt")
os.rename("old", "new")
os.symlink("target", "link")

# Permissions
os.chmod("script.sh", 0o755)
os.chown("file", uid, gid)
```

## shutil

```python
import shutil

shutil.which("python3")        # Find executable in PATH
shutil.disk_usage("/")         # Disk usage named tuple
shutil.get_terminal_size()     # Terminal dimensions
```

## Signal handling

```python
import signal
import sys

def handle_sigterm(signum: int, frame) -> None:
    log.info("Received SIGTERM, shutting down...")
    cleanup()
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)
signal.signal(signal.SIGINT, handle_sigterm)  # Ctrl+C

# Ignore a signal
signal.signal(signal.SIGHUP, signal.SIG_IGN)
```

## Daemonization (running in background)

```python
import os
import sys

def daemonize() -> None:
    if os.fork() > 0:
        sys.exit(0)  # exit parent
    os.setsid()      # create new session
    if os.fork() > 0:
        sys.exit(0)  # exit session leader
    sys.stdin.close()
    sys.stdout.close()
    sys.stderr.close()
```

## Practical automation patterns

```python
# Find and kill process by name
import subprocess

def kill_process(name: str, sig: str = "TERM") -> bool:
    result = subprocess.run(
        ["pkill", f"-{sig}", name],
        capture_output=True,
    )
    return result.returncode == 0

# Wait for port
import socket
import time

def wait_for_port(host: str, port: int, timeout: float = 30.0) -> bool:
    start = time.monotonic()
    while time.monotonic() - start < timeout:
        try:
            with socket.create_connection((host, port), timeout=2):
                return True
        except (ConnectionRefusedError, OSError):
            time.sleep(1)
    return False
```
