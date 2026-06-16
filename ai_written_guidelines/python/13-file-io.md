# File I/O & Path Manipulation

## Pathlib (preferred over `os.path`)

```python
from pathlib import Path

# Construction
p = Path("data/config.yaml")
home = Path.home()
cwd = Path.cwd()
temp = Path("/tmp")

# Properties
p.name          # "config.yaml"
p.stem          # "config"
p.suffix        # ".yaml"
p.parent        # Path("data")
p.absolute()    # full path

# Checking
p.exists()
p.is_file()
p.is_dir()
p.stat().st_size
```

## Reading & Writing Files

```python
# Text
data = Path("file.txt").read_text(encoding="utf-8")
Path("out.txt").write_text("hello\n", encoding="utf-8")

# Binary
data = Path("file.bin").read_bytes()
Path("out.bin").write_bytes(b"\x00\x01\x02")

# Line by line (large files)
for line in Path("large.log").open():
    process(line)
```

## Directory Operations

```python
# List contents
list(Path(".").iterdir())
list(Path(".").glob("*.py"))
list(Path(".").rglob("**/__init__.py"))

# Create directories
Path("output/logs/2025").mkdir(parents=True, exist_ok=True)

# Temp directories
import tempfile
with tempfile.TemporaryDirectory() as tmpdir:
    path = Path(tmpdir) / "data.txt"
    path.write_text("temporary data")
```

## Shutil (high-level file operations)

```python
import shutil

shutil.copy("src.txt", "dst.txt")          # file -> file
shutil.copy2("src.txt", "dst.txt")         # preserve metadata
shutil.copytree("src/", "dst/")            # directory copy
shutil.move("src.txt", "archive/")         # move / rename
shutil.rmtree("temp_dir/")                 # delete directory tree
shutil.make_archive("backup", "gztar", "src/")  # create archive
```

## File Locking (for concurrent access)

```python
import fcntl  # Linux/macOS

with open("log.txt", "a") as f:
    fcntl.flock(f.fileno(), fcntl.LOCK_EX)
    f.write("data\n")
    fcntl.flock(f.fileno(), fcntl.LOCK_UN)
```

## Temporary Files

```python
from tempfile import NamedTemporaryFile

with NamedTemporaryFile(
    mode="w", suffix=".yaml", delete=False
) as f:
    f.write(yaml_content)
    temp_path = f.name
```

## Watching Files (polling approach)

```python
import time
from pathlib import Path

def watch(path: Path, interval: float = 1.0):
    last = path.stat().st_mtime
    while True:
        current = path.stat().st_mtime
        if current != last:
            yield path
            last = current
        time.sleep(interval)

for changed in watch(Path("config.yaml")):
    reload_config()
```
