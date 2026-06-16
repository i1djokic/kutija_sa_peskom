# Code Quality

## Linting with Ruff

```bash
pip install ruff

ruff check src/               # lint
ruff check --fix src/         # auto-fix
ruff format src/              # format
ruff format --check src/      # check formatting
ruff check --watch src/       # watch mode
```

### Configuration (`pyproject.toml`)

```toml
[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "SIM", "ARG", "BLE", "RUF"]
ignore = ["E501"]  # line length handled by formatter

[tool.ruff.lint.per-file-ignores]
"tests/*" = ["ARG"]
```

## Type Checking with mypy

```bash
pip install mypy
mypy src/
mypy src/ --strict
```

### Configuration (`pyproject.toml`)

```toml
[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true
disallow_untyped_defs = true
no_implicit_optional = true
warn_return_any = true
warn_unused_configs = true
```

## Pre-commit (run checks before every commit)

```bash
pip install pre-commit
pre-commit install
```

See [02-ci-cd.md](./02-ci-cd.md) for config examples.

## EditorConfig

```ini
# .editorconfig
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false
```

## Security scanning

```bash
pip install bandit
bandit -r src/

pip install safety
safety check
```

## VSCode settings

```json
{
  "python.defaultInterpreterPath": ".venv/bin/python",
  "python.analysis.typeCheckingMode": "strict",
  "ruff.enable": true,
  "ruff.formatOnSave": true,
  "[python]": {
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  }
}
```

## Git hooks (manual, no pre-commit)

```bash
#!/bin/sh
# .git/hooks/pre-commit
set -euo pipefail
ruff check src/ tests/
ruff format --check src/ tests/
mypy src/
```

## Makefile quality targets

```makefile
.PHONY: lint format typecheck security

lint:
	ruff check src/ tests/

format:
	ruff format src/ tests/

typecheck:
	mypy src/

security:
	bandit -r src/ -x tests/
	safety check

quality: lint format typecheck security
```

## CI quality gates

Recommended order (fastest first):

1. Ruff linting (seconds)
2. Ruff formatting check (seconds)
3. Mypy type checking (10-30s)
4. Pytest with coverage (10-60s)
5. Bandit security scan (10-30s)
