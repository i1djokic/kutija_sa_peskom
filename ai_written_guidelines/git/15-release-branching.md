# Release Branching

## Overview

A strategy for maintaining multiple supported release versions simultaneously.

**Who it's for:** Software with multiple supported versions (e.g., v1.x, v2.x).

## Diagram

```
main:         m1---m2---m3---m4---m5---
                     \           (v3 features)
release/v2.x          r1---r2---r3---
                           \     (backports)
release/v1.x                b1---b2
```

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Current development (next major version) |
| `release/v2.x` | Maintenance of v2 |
| `release/v1.x` | Maintenance of v1 |

## Workflow

```bash
# Create a release branch from a specific commit
git checkout -b release/v2.0 v2.0.0
git push -u origin release/v2.0  # -u sets upstream so future git push works without args

# Apply a bugfix to the release branch
git checkout release/v2.0
git cherry-pick <bugfix-commit>
git commit -m "Backport fix to v2.0"
git push origin release/v2.0
git tag -a v2.0.1 -m "Patch v2.0.1"
```

## Backporting

When a fix is made on `main`, backport it to older release branches:

```bash
# Find the fix commit on main, then:
git checkout release/v1.x
git cherry-pick -x <fix-commit-hash>
# The -x adds "cherry picked from commit ..." to the message
```

## Best For

- Open-source libraries with LTS versions
- Enterprise software supporting multiple releases
- Projects where users can't always upgrade to the latest version
