# Git Flow

## Overview

A feature-rich branching model with dedicated branches for features, releases, and hotfixes.

**Who it's for:** Projects with scheduled releases, multiple versions in production.

## Diagram

```
main:     m1--------------------m2---m3---
           \                  /     /
develop     d1---d2---d3---d4---d5-d6
                 \         /
feature-xyz       f1---f2-f3
```

## Branches

| Branch | Base | Purpose |
|--------|------|---------|
| `main` | — | Production-ready code; tagged at each release |
| `develop` | `main` | Integration branch for daily work |
| `feature/*` | `develop` | New features |
| `release/*` | `develop` | Release preparation (bug fixes, version bump) |
| `hotfix/*` | `main` | Urgent production fixes |

## Feature Workflow

```bash
# Start a feature
git checkout -b feature/awesome develop

# Work and commit
git add .
git commit -m "Add awesome feature"

# Merge back to develop
git checkout develop
git merge --no-ff feature/awesome  # --no-ff forces a merge commit (avoids fast-forward, preserves branch history)
git branch -d feature/awesome
```

## Release Workflow

```bash
# Start a release
git checkout -b release/1.2.0 develop

# Polish, bump version, fix bugs
git add .
git commit -m "Bump version to 1.2.0"

# Merge to main and tag
git checkout main
git merge --no-ff release/1.2.0  # --no-ff forces a merge commit (preserves branch history)
git tag -a v1.2.0 -m "Release 1.2.0"

# Merge back to develop
git checkout develop
git merge --no-ff release/1.2.0  # --no-ff forces a merge commit (preserves branch history)

# Delete release branch
git branch -d release/1.2.0
```

## Hotfix Workflow

```bash
# Start a hotfix from main
git checkout -b hotfix/1.2.1 main

# Fix and commit
git add .
git commit -m "Fix critical security bug"

# Merge to main and tag
git checkout main
git merge --no-ff hotfix/1.2.1  # --no-ff forces a merge commit (preserves branch history)
git tag -a v1.2.1 -m "Hotfix 1.2.1"

# Merge to develop too
git checkout develop
git merge --no-ff hotfix/1.2.1  # --no-ff forces a merge commit (preserves branch history)

# Delete hotfix branch
git branch -d hotfix/1.2.1
```

## Best For

- Larger teams
- Versioned releases
- Mobile apps and libraries
- Projects needing structured release management
