# Docker & Python

## Dockerfile for Python

```dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && \
    poetry export -f requirements.txt --output requirements.txt && \
    pip install --user -r requirements.txt

FROM python:3.12-slim

WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY src/ ./src/

ENV PATH=/root/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER nobody
CMD ["python", "-m", "mypackage"]
```

## Smaller image with multi-stage

```dockerfile
FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv ./.venv
COPY src/ ./src/
ENV PATH="/app/.venv/bin:$PATH"
CMD ["python", "-m", "mypackage"]
```

## docker-compose for development

```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/app
      - LOG_LEVEL=DEBUG
    volumes:
      - ./src:/app/src
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

## .dockerignore

```
__pycache__
.venv
.git
.env
*.pyc
.pytest_cache
.ruff_cache
.mypy_cache
*.egg-info
dist
build
```

## Health check in Docker

```python
# health.py
import sys
import requests

try:
    resp = requests.get("http://localhost:8080/health", timeout=5)
    sys.exit(0 if resp.status_code == 200 else 1)
except Exception:
    sys.exit(1)
```

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python /app/health.py
```

## Docker SDK for Python

```python
import docker  # pip install docker

client = docker.from_env()

# Manage containers
container = client.containers.run("nginx:alpine", detach=True, ports={"80": "8080"})
print(container.id)
container.stop()
container.remove()

# Build image
image, logs = client.images.build(path="./app", tag="myapp:latest")
for line in logs:
    print(line)

# Run command in container
result = container.exec_run("cat /etc/hosts")
print(result.output.decode())
```

## Best practices

- Use slim images (`python:3.X-slim`)
- Multi-stage builds to reduce size
- Never run as root (use `USER nobody` or create a user)
- Set `PYTHONUNBUFFERED=1` and `PYTHONDONTWRITEBYTECODE=1`
- Use `.dockerignore` to exclude unnecessary files
- Layer ordering: dependencies first, code last (leverage cache)
- Use health checks for service readiness
- Pin base image versions (avoid `:latest`)
- Use `exec` form of `CMD` and `ENTRYPOINT`
