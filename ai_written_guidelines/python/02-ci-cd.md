# CI/CD Pipelines

## Makefile for local automation

```makefile
.PHONY: help install lint typecheck test clean docker-build

help:           ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:        ## Install dependencies
	pip install -e ".[dev]"

lint:           ## Run linter
	ruff check src/ tests/
	ruff format --check src/ tests/

typecheck:      ## Run type checker
	mypy src/

test:           ## Run tests
	pytest -v --cov=src/ --cov-report=term

clean:          ## Clean build artifacts
	rm -rf dist/ build/ *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

docker-build:   ## Build Docker image
	docker build -t myapp .

all: lint typecheck test  ## Run all checks
```

## Pre-commit hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-added-large-files
      - id: detect-private-key

  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.6
    hooks:
      - id: bandit
        args: ["-s", "B101"]
```

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files   # run on all files
pre-commit autoupdate        # update hook versions
```

## Local CI script

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Linting ==="
ruff check src/ tests/

echo "=== Formatting ==="
ruff format --check src/ tests/

echo "=== Type Checking ==="
mypy src/

echo "=== Tests ==="
pytest -v --cov=src/ --cov-report=term

echo "=== Security ==="
bandit -r src/ -x tests/

echo "=== All checks passed ==="
```

## Pipeline design principles

### Stages

```
lint → typecheck → test → build → deploy
```

### Rules

- Fast feedback: lint and typecheck first (< 1 min)
- Tests run in isolation (clean environment each time)
- Build once, deploy many (immutable artifacts)
- Fail fast, fail early
- Pipeline should be reproducible locally

## Pipeline checklist

- [ ] Dependencies are pinned (lock files)
- [ ] Tests are deterministic
- [ ] Secrets are injected via environment, not in code
- [ ] Docker images are tagged with commit SHA
- [ ] Rollback procedure is defined
- [ ] Notifications on failure (Slack, email, etc.)
- [ ] Pipeline code is version-controlled

## Best practices

- Keep pipeline fast (parallelize where possible)
- Cache dependencies between runs
- Use matrix builds for multiple Python versions
- Always run linting + type checking before tests
- Pin tool versions (ruff, mypy, etc.)
- Make pipeline self-documenting (clear stage names)
- Use `--dry-run` flag for deployment stages
- Always restore state on failure (idempotent operations)
