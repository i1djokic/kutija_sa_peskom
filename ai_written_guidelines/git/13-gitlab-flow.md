# GitLab Flow

## Overview

A middle-ground between GitHub Flow and Git Flow, adding environment branches for staged deployments.

**Who it's for:** Teams wanting environment tracking (staging, production) with a simpler model than Git Flow.

## Diagram

```
main:             m1---m2---m3---m4---m5---
                         \
pre-production           p1---p2---p3---
                                    \
production                          prod1---
```

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Latest code, active development |
| `pre-production` | Staging environment for pre-release testing |
| `production` | Production environment |
| `feature/*` | Feature branches off `main` |

## Workflow

```bash
# 1. Feature branch (same as GitHub Flow)
git checkout -b feature/new-dashboard main
# ... work, commit ...
git push -u origin feature/new-dashboard  # -u sets upstream so future git push works without args
# Open merge request, review, merge to main

# 2. Deploy to staging
git checkout pre-production
git merge main
git push origin pre-production
# Test in staging environment

# 3. Deploy to production
git checkout production
git merge pre-production
git push origin production
```

## Environment Branches vs Tags

GitLab Flow recommends environment branches instead of tags for deployments:

- **Environment branch** — reflects the current state of an environment (e.g., `production`, `staging`)
- **Tag** — marks a specific point in history (e.g., `v1.0.0`)

Use tags alongside environment branches for versioned releases.

## Best For

- Teams with multiple environments (staging, production)
- Enterprise deployments
- Teams that find Git Flow too complex but need more structure than GitHub Flow
