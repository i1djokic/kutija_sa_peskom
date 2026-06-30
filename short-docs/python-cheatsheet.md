# Python — DevOps Cheatsheet

## File & Dir Ops

```python
import os, shutil, glob

os.path.exists(path)
os.path.isfile(path)
os.path.isdir(path)
os.makedirs(path, exist_ok=True)
shutil.copy(src, dst)
shutil.move(src, dst)
shutil.rmtree(path)
glob.glob("**/*.log", recursive=True)
```

## Subprocess

```python
import subprocess

subprocess.run(["ls", "-l"], check=True)
subprocess.run(cmd, capture_output=True, text=True)
subprocess.run(cmd, shell=True)          # avoid if possible

r = subprocess.run(cmd, capture_output=True, text=True)
r.returncode, r.stdout, r.stderr
```

## Env & Args

```python
import os, sys

os.environ.get("KEY", "default")
os.environ["PATH"]
sys.argv[1:]
sys.exit(1)
```

## JSON / YAML

```python
import json, yaml

json.loads(s)
json.dumps(obj, indent=2)
yaml.safe_load(f)
yaml.dump(obj)
```

## HTTP

```python
import requests

requests.get(url, params={}, headers={}, timeout=5)
requests.post(url, json={})
r.status_code, r.text, r.json()
```

## Pathlib

```python
from pathlib import Path

p = Path("dir/file.txt")
p.exists(), p.is_file(), p.is_dir()
p.read_text(), p.write_text("data")
p.parent, p.name, p.suffix, p.stem
p.iterdir(), p.glob("*.log"), p.rglob("**/*")
Path("a/b").mkdir(parents=True, exist_ok=True)
```

## Regex

```python
import re

re.search(r"pattern", s)       # first match / None
re.findall(r"pattern", s)      # all matches
re.sub(r"old", "new", s)       # replace
re.match(r"^pattern", s)       # anchored at start
```

## Error Handling

```python
try:
    ...
except Exception as e:
    print(f"err: {e}", file=sys.stderr)
    sys.exit(1)
```

## One-liners

```python
# parse JSON from curl
subprocess.run(["curl", "-s", url], capture_output=True, text=True) | jq
# -> better: requests.get(url).json()

# iterate files
Path(".").glob("*.log") and ...   # use rglob for recursive

# env fallback
os.getenv("HOME", "/tmp")
```
