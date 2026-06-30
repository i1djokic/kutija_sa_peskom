# Dockerfile & Compose — DevOps Cheatsheet

## Dockerfile

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
COPY --from=builder /usr/local /usr/local
COPY . .
USER 1000
EXPOSE 8080
HEALTHCHECK --interval=30s CMD curl -f http://localhost:8080/health
CMD ["python", "app.py"]
```

### Key Instructions

| Instruction | Purpose |
|------------|---------|
| `FROM` | base image, optional `AS stage` |
| `RUN` | execute cmd at build time |
| `CMD` | default runtime command (overridable) |
| `ENTRYPOINT` | runtime entrypoint (harder to override) |
| `COPY` | copy files into image |
| `ADD` | like COPY + tar auto-extract + URLs |
| `WORKDIR` | set working dir (creates if missing) |
| `ARG` | build-time var, `--build-arg` |
| `ENV` | env var at build & runtime |
| `EXPOSE` | document port (no effect) |
| `VOLUME` | declare mount point |
| `USER` | switch user |
| `LABEL` | metadata |
| `SHELL` | change shell for RUN (e.g. `["/bin/bash", "-c"]`) |

### Best Practices

- Use `.dockerignore`
- Multi-stage builds to minimise size
- Pin base image tags (`python:3.12-slim`, not `latest`)
- Combine `RUN` cmds to reduce layers
- Use `--no-cache-dir`, `apt-get clean`, `rm -rf /var/lib/apt/lists/*`
- Prefer `COPY` over `ADD`
- Run as non-root (`USER 1000`)
- Add `HEALTHCHECK`
- Use `exec` form (`["cmd", "arg"]`) over shell form

## Docker Compose

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - VERSION=1.0
    image: myapp:latest
    container_name: myapp
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=db
    env_file: .env
    volumes:
      - ./data:/app/data
      - logs:/var/log
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      retries: 3
      timeout: 10s
    networks:
      - front
      - back

  db:
    image: postgres:16
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_pass
    secrets:
      - db_pass
    healthcheck:
      test: ["CMD-SHELL", "pg_isready"]

volumes:
  pgdata:
  logs:

networks:
  front:
  back:

secrets:
  db_pass:
    file: ./secrets/db_pass.txt
```

### Key Compose Directives

| Directive | Purpose |
|-----------|---------|
| `build` | build context + optional args |
| `image` | use existing image |
| `ports` | `"host:container"` |
| `volumes` | bind mount / named volume / tmpfs |
| `environment` | inline env vars |
| `env_file` | load env from file |
| `depends_on` | startup ordering |
| `restart` | no / always / on-failure / unless-stopped |
| `healthcheck` | container health |
| `networks` | attach to networks |
| `secrets` | secrets (swarm/compose) |
| `deploy` | swarm only (replicas, resources) |
| `profiles` | conditional service activation |

### Common Commands

```bash
docker compose up -d
docker compose down -v        # -v removes volumes
docker compose build
docker compose logs -f
docker compose exec app bash
docker compose ps
docker compose restart
docker compose pull
docker compose config          # validate + show resolved
```
