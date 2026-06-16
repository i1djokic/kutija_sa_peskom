# Basic Workflow

## Checking Status

```bash
git status                    # Full status
git status -s                 # Short status (two columns)
```

`-s` output — column 1 = staging area, column 2 = working directory:

| Column 1 | Column 2 | Meaning |
|----------|----------|---------|
| `??` | | Untracked file (not staged, not tracked) |
| `M` | | Modified (staged) |
| `A` | | Added (staged) |
| ` M` | | Modified but not staged |
| `MM` | | Modified and staged, then modified again |

## Staging Changes

```bash
git add file.txt              # Stage a specific file
git add .                     # Stage all changes in current directory
git add -A                    # Stage all changes everywhere in repo
git add -p                    # Stage interactively — review each hunk (contiguous diff section) before staging
git add -i                    # Interactive staging menu
```

## Committing

```bash
git commit -m "Add feature X"

# Stage tracked files and commit in one step
git commit -am "Fix bug in parser"

# Commit with a longer message (opens editor)
git commit

# Edit the last commit message
git commit --amend -m "New message"

# Add forgotten files to the last commit
git add forgotten-file.txt
git commit --amend --no-edit
```

## Pushing

```bash
# Push to remote
git push origin main

# Push current branch to matching remote branch
git push

# Push and set upstream (first push)
# -u links your local branch to the remote one so future git push/git pull work without args
git push -u origin feature-xyz

# Force push (use only on your own branches)
# --force-with-lease is safer than --force: it refuses if someone else has pushed new commits
git push --force-with-lease origin branch-name
```

## Pulling

```bash
# Pull and merge
git pull origin main

# Pull with rebase — reapplies your local commits on top of fetched commits (cleaner, linear history)
# (Rebase is explained in 05-branching.md)
git pull --rebase origin main

# Set rebase as default for pull
git config --global pull.rebase true
```

## Fetching

```bash
# Fetch remote changes without merging
git fetch origin

# Fetch all remotes
git fetch --all

# Fetch and prune deleted remote branches
git fetch --prune
```
