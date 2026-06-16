# GitHub Flow

## Overview

A simple, lightweight branching strategy focused on continuous delivery.

**Who it's for:** Teams deploying frequently (CI/CD), simple projects.

## Diagram

```
main:   m1---m2---m3---m4---m5---
                \         /
feature-xyz      f1---f2---f3
```

## Rules

1. One eternal branch: `main` (always deployable)
2. Feature branches off `main`
3. Open a Pull Request for code review
4. Merge to `main` and deploy immediately

## Workflow

```bash
# 1. Create a feature branch
git checkout -b feature-xyz main

# 2. Work and commit
git add .
git commit -m "Add feature XYZ"

# 3. Push and open a Pull Request
git push -u origin feature-xyz   # -u sets upstream so future git push works without args
# Go to GitHub/GitLab and open a PR

# 4. After review, merge to main
git checkout main
git merge feature-xyz
git push origin main

# 5. Clean up
git branch -d feature-xyz
git push origin --delete feature-xyz
```

## Best For

- Small teams
- SaaS products
- Continuous deployment
- Projects without versioned releases
