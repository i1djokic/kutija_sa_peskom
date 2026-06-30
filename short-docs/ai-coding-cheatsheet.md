# AI-Assisted Coding — DevOps Cheatsheet

## Prompting Principles

```
Be specific   → "Write a Python function that parses nginx access logs and returns top 10 IPs"
Provide context → "We use FastAPI, SQLAlchemy async, and PostgreSQL"
Give examples  → "Input: X → Output: Y"
Set constraints → "No external deps, must handle 10K req/s, <50ms p99"
Iterate        → Start broad, refine with follow-ups
```

## Structuring Requests

### Bad
```
Write a bash script
```

### Good
```
Write a bash script that:
- Takes a directory path as $1
- Finds all .log files older than 7 days
- Compresses each with gzip
- Moves compressed files to /archive/{dirname}/
- Logs actions to syslog
- Dry-run mode with -n flag
```

## Code Review Checklist (for AI output)

- [ ] Secure (no secrets, no injection, no shell=True without validation)
- [ ] Error handling (exceptions, exit codes, retries)
- [ ] Idempotent (safe to re-run)
- [ ] Observable (logs, metrics, traceable)
- [ ] Performant (handles scale, no O(n²) in hot path)
- [ ] No over-engineering (YAGNI)
- [ ] Matches existing code style (same patterns, naming, imports)
- [ ] Has tests or is testable
- [ ] Proper exit codes (0=ok, non-zero=fail)
- [ ] No hardcoded values in wrong places (use config/env/params)

## Dev-Specific Patterns

```
# Terraform — ask with provider + version pinning
"Write a Terraform module for an AWS ECS Fargate service with:
 - Service connect, task role, execution role
 - Autoscaling based on CPU
 - CloudWatch logging
 - Outputs: service ARN, task definition ARN"

# Docker — ask with multi-stage + non-root
"Write a Dockerfile for a Go app:
 - Multi-stage (build → run)
 - Distroless runtime
 - HEALTHCHECK
 - USER non-root
 - .dockerignore"

# Kubernetes — ask with specific resource
"Write a K8s Deployment + Service + HPA for:
 - Stateless Go app on port 8080
 - 2-10 replicas, 70% CPU threshold
 - Readiness + liveness probes
 - Resource requests/limits
 - Rolling update strategy"

# Bash — ask with safety
"Write a bash script that:
 - Uses set -euo pipefail
 - Checks prerequisites
 - Handles SIGINT cleanup
 - Prints usage on -h
 - Idempotent operations"

# CI/CD — ask with context
"Write a GitHub Actions workflow that:
 - Triggers on push to main and PRs
 - Runs lint, test, build in parallel
 - Caches npm
 - Publishes Docker image to GHCR
 - Deploys to staging with manual approval"
```

## Iteration Patterns

```
1. "Generate a first draft"
2. "Add error handling"
3. "Make it parallel"
4. "Add logging"
5. "Add tests"
6. "Optimize for X"

# or reverse:
1. "Generate the simplest version"
2. What's missing? → ask AI to add it
```

## Commit Messages (Conventional Commits)

```
feat:     new feature
fix:      bug fix
chore:    maintenance
docs:     documentation
refactor: code change (no fix/feat)
test:     tests
perf:     performance
ci:       CI/CD config
infra:    infrastructure as code
```

```
feat(api): add rate limiting
fix(db): handle connection timeout
ci(actions): cache Docker layers
```

## Common Don'ts

```
Don't assume:
  - Library availability (check package.json / requirements.txt first)
  - Specific versions (pin them)
  - Production readiness without review

Don't copy blindly:
  - AI might hallucinate package names, functions, or APIs
  - Always verify imports and method signatures

Don't skip:
  - Tests ("Are there tests for this code?")
  - Linting ("Run the linter")
  - Security ("Check for injection vectors")
```

## DevOps-Specific Pitfalls

| Pitfall | Why | Fix |
|---------|-----|-----|
| Hardcoded secrets | exposed in code | Use env vars / secrets manager |
| No retry logic | transient failures | Add retry with backoff |
| Not idempotent | re-run causes errors | Check before create |
| Missing error paths | silent failures | trap, catch, exit codes |
| No resource cleanup | orphaned resources | defer/teardown/finally |
| Overly permissive IAM | security risk | least privilege principle |
| No observability | can't debug | logs, metrics, traces |
| Ignoring rate limits | API throttling | add throttling / pagination |
| Not testing rollback | broken deploy | test rollback separate |
