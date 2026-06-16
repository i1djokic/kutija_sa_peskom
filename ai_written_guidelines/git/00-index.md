# Git Guide

Practical Git documentation covering basics, common troubleshooting scenarios, and branching strategies.

## Key Concepts

| File | What it covers |
|------|----------------|
| [00-concepts.md](./00-concepts.md) | HEAD, origin, staging area, ~ notation, .. range, fast-forward, upstream, hunk, -- separator |

## Basics

| File | What it covers |
|------|----------------|
| [01-configuration.md](./01-configuration.md) | Identity, aliases, default branch, editor, pull behavior, merge tool |
| [02-starting-a-project.md](./02-starting-a-project.md) | Installing Git, init, clone |
| [03-basic-workflow.md](./03-basic-workflow.md) | Status, staging, committing, pushing, pulling |
| [04-viewing-history.md](./04-viewing-history.md) | log, diff, show |
| [05-branching.md](./05-branching.md) | Create/switch/merge/delete branches, remotes |

## Common Scenarios

| File | What it covers |
|------|----------------|
| [06-undoing-changes.md](./06-undoing-changes.md) | Wrong branch, amend, revert pushed commits, discard local changes |
| [07-merge-conflicts.md](./07-merge-conflicts.md) | Resolving merge conflicts |
| [08-stash.md](./08-stash.md) | Save/apply/drop stashes |
| [09-rebasing-and-cherry-pick.md](./09-rebasing-and-cherry-pick.md) | Interactive rebase, split commits, cherry-pick |
| [10-misc-scenarios.md](./10-misc-scenarios.md) | Detached HEAD, clean, rename, tags, secrets, submodules |

## Branching Strategies

| File | What it covers |
|------|----------------|
| [11-github-flow.md](./11-github-flow.md) | Simple PR-based flow with main branch |
| [12-git-flow.md](./12-git-flow.md) | Feature/release/hotfix branches with develop |
| [13-gitlab-flow.md](./13-gitlab-flow.md) | Environment-based branching (staging/production) |
| [14-trunk-based-development.md](./14-trunk-based-development.md) | Short-lived branches, feature flags |
| [15-release-branching.md](./15-release-branching.md) | Multiple supported release versions |

## Reference

| File | What it covers |
|------|----------------|
| [16-quick-reference.md](./16-quick-reference.md) | Full command cheat sheet |

## Quick Start

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main

git init my-project && cd my-project
# or
git clone <repo-url>

# Basic loop
git add <file>
git commit -m "message"
git push origin main
```

## Resources

- [Official Git Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book/en/v2) (free)
