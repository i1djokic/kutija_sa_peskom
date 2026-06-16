# Trunk-Based Development

## Overview

A minimalist branching model where all work happens on or near `main` with very short-lived branches.

**Who it's for:** High-throughput CI/CD, small commits, short-lived branches.

## Diagram

```
main:   m1---m2---m3---m4---m5---m6---m7
              \    /
               f1-f2
```

## Rules

1. All work on `main` (or branches lasting less than a day)
2. No long-running branches
3. Feature flags to hide incomplete work
4. Continuous integration and deployment

## Workflow

```bash
# Direct commit to main (common for small changes)
git add .
git commit -m "Fix typo in header"
git push origin main

# Short-lived branch (for changes needing review)
git checkout -b fix-header main
git add .
git commit -m "Fix header alignment"
git push -u origin fix-header  # -u sets upstream so future git push works without args
# Open PR, review, merge quickly (same day)
git checkout main
git merge fix-header
git push origin main
git branch -d fix-header
```

## Feature Flags

Incomplete features are hidden behind flags instead of branches:

```python
if feature_flag_enabled("new_dashboard"):
    render_new_dashboard()
else:
    render_old_dashboard()
```

This allows merging incomplete work to main without affecting users.

## Best For

- Elite DevOps teams
- Very frequent deployments (multiple times per day)
- Continuous delivery with automated testing
- Teams experienced with feature flags
