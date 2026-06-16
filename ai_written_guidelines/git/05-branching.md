# Branching

## Listing Branches

```bash
git branch                       # Local branches
git branch -r                    # Remote branches
git branch -a                    # All branches
git branch -v                    # Branches with last commit
git branch --merged              # Branches already merged into current
git branch --no-merged           # Branches not yet merged
```

## Creating and Switching

```bash
# Create a branch
git branch feature-xyz

# Switch to a branch
git checkout feature-xyz
git switch feature-xyz           # Modern alternative (Git 2.23+)

# Create and switch (one step)
git checkout -b feature-xyz
git switch -c feature-xyz        # Modern alternative

# Create from a specific commit/tag
git checkout -b feature-xyz <commit-hash>
git checkout -b release-v1.0 v1.0
```

## Renaming

```bash
# Rename current branch
git branch -m new-name

# Rename another branch
git branch -m old-name new-name
```

## Merging

```bash
git checkout main
git merge feature-xyz            # Merge feature into main

# --no-ff forces a merge commit even if a fast-forward is possible
# Fast-forward = main hasn't diverged, so git just moves the pointer forward
# --no-ff preserves the branch history visually
git merge --no-ff feature-xyz

# Squash merge (all changes as one commit)
git merge --squash feature-xyz
git commit -m "Add feature XYZ"

# Abort a merge with conflicts
git merge --abort
```

## Rebasing

Rebasing takes your branch's commits and replays them on top of another branch. This creates a linear history without merge commits.

```bash
# Rebase current branch onto another
git checkout feature-xyz
git rebase main
```

Each commit gets a new hash (shown as `f'--g'--h'` in the diagram below) because it's being applied on top of a different base.

```bash
# Abort a rebase
git rebase --abort

# Continue after resolving conflicts
git rebase --continue
```

## Merge vs Rebase

```
Merge:
main:   a---b---c---d---e---
             \         /
feature       f---g---h

Rebase:
main:   a---b---c---d---e---
                     |
feature              f'--g'--h'
```

- **Merge** — preserves the exact branch history including when branches diverged and merged. Safe for shared branches because no history is rewritten.
- **Rebase** — rewrites history by creating new commits with new hashes. Produces a clean linear history, but **never** rebase branches that others have already pulled — their history will diverge from yours.
- Use **merge** for public/shared branches (e.g., `main`, `develop`).
- Use **rebase** for local/feature branches before sharing.

## Deleting Branches

```bash
# Delete local branch (safe - refuses if unmerged)
git branch -d feature-xyz

# Force delete local branch
git branch -D feature-xyz

# Delete remote branch
git push origin --delete feature-xyz
```

## Remotes

```bash
# Show remotes
git remote -v

# Add a remote
git remote add origin <url>

# Remove a remote
git remote remove origin

# Change remote URL
git remote set-url origin <new-url>

# Show remote branches
git branch -r
```
