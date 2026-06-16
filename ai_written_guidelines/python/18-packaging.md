# Python Packaging

## Project structure

```
myproject/
  pyproject.toml
  README.md
  src/
    myproject/
      __init__.py
      cli.py
      config.py
  tests/
    test_cli.py
    test_config.py
```

## pyproject.toml (setuptools)

```toml
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.backends._legacy:_Backend"

[project]
name = "myproject"
version = "0.1.0"
description = "Automation tool"
readme = "README.md"
requires-python = ">=3.10"
license = {text = "MIT"}
authors = [
    {name = "Your Name", email = "you@example.com"},
]
keywords = ["automation", "devops"]

dependencies = [
    "click>=8.0",
    "pyyaml>=6.0",
    "requests>=2.31",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "ruff>=0.3",
    "mypy>=1.8",
    "pre-commit>=3.0",
]

[project.scripts]
myproject = "myproject.cli:main"

[tool.setuptools.packages.find]
where = ["src"]
```

## pyproject.toml (poetry)

```toml
[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.poetry]
name = "myproject"
version = "0.1.0"
description = "Automation tool"
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.10"
click = "^8.0"
pyyaml = "^6.0"
requests = "^2.31"

[tool.poetry.group.dev.dependencies]
pytest = "^7.0"
ruff = "^0.3"
mypy = "^1.8"

[tool.poetry.scripts]
myproject = "myproject.cli:main"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

## Entry points (console scripts)

```python
# src/myproject/cli.py
def main() -> int:
    ...

# After pip install, users can run:
#   myproject deploy --env prod
```

## Building

```bash
# Build wheel + sdist
python -m build

# Install editable (development)
pip install -e .

# With dev dependencies
pip install -e ".[dev]"

# Poetry
poetry build
poetry install
```

## version.py pattern

```python
# src/myproject/version.py
__version__ = "0.1.0"
VERSION = __version__

# src/myproject/__init__.py
from .version import __version__
```

Then in `pyproject.toml`:
```toml
# For setuptools with dynamic version
dynamic = ["version"]

[tool.setuptools.dynamic]
version = {attr = "myproject.__version__"}
```

## src/ layout vs flat layout

```
# src layout (recommended)
src/
  myproject/
    __init__.py    # import myproject works

# flat layout (can cause import confusion)
myproject/
  __init__.py      # import myproject or myproject.myproject?
```

## .gitignore for Python projects

```gitignore
# Python
__pycache__/
*.pyc
*.pyo
.venv/
venv/
*.egg-info/
dist/
build/

# Tools
.ruff_cache/
.mypy_cache/
.pytest_cache/
.coverage
htmlcov/

# IDE
.vscode/
.idea/

# Environment
.env
*.local.yaml
```

## Publishing (to PyPI or private index)

```bash
# Build
python -m build

# Check
twine check dist/*

# Upload
twine upload dist/*                          # PyPI
twine upload --repository-url <url> dist/*   # private index
```
