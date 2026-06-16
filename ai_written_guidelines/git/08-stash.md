# Stash

Temporarily save uncommitted changes so you can switch branches or pull changes. Think of it as a clipboard for your working directory.

## Saving Changes

```bash
# Save all tracked changes
git stash

# Save with a message
git stash -m "WIP: refactoring auth module"

# Save including untracked files
git stash -u

# Save including ignored files (e.g., build artifacts)
git stash -a
```

## Listing Stashes

```bash
git stash list
```

Output:

```
stash@{0}: On feature-xyz: WIP: refactoring auth module
stash@{1}: On main: fix typo in config
```

## Applying Stashes

```bash
# Apply the latest stash and remove it from the stack
git stash pop

# Apply without removing from the stack
git stash apply

# Apply a specific stash
git stash apply stash@{2}

# Apply to a different branch
git checkout other-branch
git stash pop
```

## Dropping Stashes

```bash
# Drop the latest stash
git stash drop

# Drop a specific stash
git stash drop stash@{0}

# Clear all stashes
git stash clear
```

## Creating a Branch from a Stash

Useful if you stashed on the wrong branch:

```bash
git stash branch new-branch stash@{0}
```

This creates a new branch, applies the stash, and drops it from the stack.

## Partial Stash

Stash only specific files or hunks:

```bash
# Stash specific files
git stash -p

# Stash only unstaged changes (leave staged changes alone)
# --keep-index means "leave the staging area (index) as-is, stash everything else"
git add file.txt                # Stage what you want to keep
git stash --keep-index          # Stash everything that isn't staged
```
