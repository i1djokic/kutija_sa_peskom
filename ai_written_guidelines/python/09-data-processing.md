# Data Processing

## JSON

```python
import json

# Read
with open("data.json") as f:
    data = json.load(f)

# Write
with open("out.json", "w") as f:
    json.dump(data, f, indent=2)

# Strings
data = json.loads('{"key": "value"}')
text = json.dumps(data, indent=2)

# CLI one-liner
# python -m json.tool data.json
```

## YAML

```python
import yaml  # pip install pyyaml

# Read
with open("config.yaml") as f:
    config = yaml.safe_load(f)

# Write
with open("out.yaml", "w") as f:
    yaml.safe_dump(config, f, default_flow_style=False)
```

## TOML

```python
import tomllib  # Python 3.11+

with open("pyproject.toml", "rb") as f:
    data = tomllib.load(f)

# Python 3.10 and below: pip install tomli
import tomli
with open("pyproject.toml", "rb") as f:
    data = tomli.load(f)
```

## CSV

```python
import csv

# Read
with open("data.csv", newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(row["name"], row["age"])

# Write
with open("out.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "age"])
    writer.writeheader()
    writer.writerow({"name": "Alice", "age": "30"})
```

## INI / ConfigParser

```python
from configparser import ConfigParser

config = ConfigParser()
config.read("settings.ini")

db_host = config.get("database", "host")
db_port = config.getint("database", "port")
debug = config.getboolean("app", "debug")
```

## XML

```python
import xml.etree.ElementTree as ET

tree = ET.parse("config.xml")
root = tree.getroot()

for child in root:
    print(child.tag, child.attrib, child.text)

# Build
root = ET.Element("config")
sub = ET.SubElement(root, "setting", name="timeout")
sub.text = "30"
ET.dump(root)
```

## Data processing with itertools

```python
from itertools import groupby, chain, batched

# Group consecutive elements
for key, group in groupby(sorted(data, key=itemgetter("env")), key=itemgetter("env")):
    print(key, list(group))

# Batch processing (Python 3.12+)
for batch in batched(items, n=100):
    process_batch(batch)
```

## Working with streams (stdin/stdout)

```python
import sys

for line in sys.stdin:
    cleaned = line.strip()
    if cleaned:
        print(process(cleaned))
```
