# GitOps Overview

GitOps is a paradigm for managing infrastructure and application deployments where **Git serves as the single source of truth**. The entire system state is described declaratively in a Git repository, and automated processes reconcile the actual state with the desired state defined in Git.

## Core Concepts

- **Declarative configuration** — the system is described in config files (YAML, HCL, JSON); you specify *what* not *how*
- **Git as source of truth** — the repository is the authoritative system state; all changes go through Git
- **Automated reconciliation** — a controller watches the repo and applies changes to the live environment
- **Observability** — drift detection alerts when live state diverges from the repo

## Why GitOps?

| Benefit | Description |
|---------|-------------|
| Audit trail | Every change is a Git commit with author, timestamp, and diff |
| Rollback | Revert to any prior state with `git revert` |
| Familiar tooling | Developers use `git push` and PRs |
| Security | Cluster pulls from repo (no exposed API credentials in CI) |
| Disaster recovery | Reproduce any environment from the repo instantly |

## Pull Model

An operator inside the cluster pulls desired state from Git:

```text
Git Repo <---- (pull) ---- Operator <----> Kubernetes API
                               |
                        (reconciles drift)
```

This eliminates exposing cluster API credentials to external CI/CD systems.

## When to Use

- Kubernetes clusters (most mature ecosystem: ArgoCD, Flux)
- Multi-environment deployments (dev/staging/prod)
- Compliance-heavy orgs (full audit trail)
- Platform teams (self-service via PR workflows)
