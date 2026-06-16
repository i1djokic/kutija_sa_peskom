# Virtual Environments & Dependencies

## venv (built-in)

```bash
# Create
python -m venv .venv

# Activate
source .venv/bin/activate       # Linux/macOS
.venv\Scripts\activate          # Windows

# Deactivate
deactivate

# Remove
rm -rf .venv
```

## pip

```bash
# Install
pip install requests
pip install -r requirements.txt
pip install -e .                # editable install of current package

# Freeze
pip freeze > requirements.txt

# List outdated
pip list --outdated

# Uninstall
pip uninstall requests -y
```

## requirements.txt patterns

```txt
# Pin exact versions
requests==2.31.0
click==8.1.7

# Version ranges
pytest>=7.0,<8.0

# Extras
black[jupyter]==23.12.0

# Git repos
git+https://github.com/psf/black.git@main

# Local packages
./mylib
-e .                           # current package in editable mode
```

## Poetry (modern dependency management)

```bash
# Install
pip install poetry

# Init project
poetry init
poetry new myproject

# Add dependencies
poetry add requests
poetry add --group dev pytest ruff

# Install
poetry install

# Build & publish
poetry build
poetry publish

# Export to requirements.txt
poetry export -f requirements.txt --output requirements.txt
```

## pip-compile (pip-tools)

```bash
pip install pip-tools

# requirements.in
echo "requests" > requirements.in
echo "pytest" >> test-requirements.in

# Compile
pip-compile requirements.in        # -> requirements.txt
pip-compile test-requirements.in   # -> test-requirements.txt

# Sync
pip-sync requirements.txt test-requirements.txt
```

## uv (fast Rust-based alternative)

```bash
# Install
curl -LsSf https://astral.sh/uv/install.sh | sh

# Commands (drop-in for pip/venv)
uv venv
uv pip install requests
uv pip compile requirements.in -o requirements.txt

# Project management
uv init myproject
uv add requests
uv run python script.py
```

## Lock files

| Tool | Lock file | Purpose |
|------|-----------|---------|
| pip | `requirements.txt` | Manual freeze |
| pip-tools | `requirements.txt` | Deterministic builds |
| Poetry | `poetry.lock` | Full dependency tree lock |
| Pipenv | `Pipfile.lock` | Hash-verified locks |
| uv | `uv.lock` | Fast deterministic locks |

## Best practices

- Always use virtual environments (never `pip install --user` system-wide)
- Commit lock files for reproducible builds
- Separate dev and prod dependencies
- Pin base dependencies, let transitive ones float within lock
- Use `pip-audit` or `safety` to check for vulnerabilities
- Use `pipdeptree` to visualize dependencies

```bash
pip install pipdeptree safety
pipdeptree                      # tree view
safety check                    # vulnerability scan
```
