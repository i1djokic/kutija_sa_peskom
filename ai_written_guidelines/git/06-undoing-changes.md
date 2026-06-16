# Undoing Changes

**About `~` notation:** `HEAD~1` means "one commit before HEAD", `HEAD~2` means "two commits before". `HEAD~` is shorthand for `HEAD~1`. See [00-concepts.md](./00-concepts.md) for more.

## Scenario: I committed to the wrong branch

```bash
# Undo the last commit but keep changes staged
git reset --soft HEAD~1

# Undo and unstage (keep changes in working directory)
git reset HEAD~1

# Stash, switch, and re-apply
git stash
git checkout correct-branch
git stash pop
git add .
git commit -m "Correct commit message"
```

## Scenario: I want to change the last commit message

```bash
git commit --amend -m "New message"
```

## Scenario: I want to add forgotten files to the last commit

```bash
git add forgotten-file.txt
git commit --amend --no-edit
```

## Scenario: I need to undo a commit that's already pushed

```bash
# WARNING: Only do this on your own branch, never on shared branches

# Option A: Revert (safe - creates a new commit that undoes the changes)
git revert <commit-hash>
git push origin branch-name

# Option B: Reset (rewrites history - force push required)
git reset --hard <previous-commit-hash>
git push --force-with-lease origin branch-name
# --force-with-lease is safer than --force (checks if remote has new commits)
```

`git revert` is preferred for shared branches. `git reset --hard` is for local/feature branches.

## Scenario: I made a typo and want to discard changes

```bash
# Discard unstaged changes in a file
# The -- tells git the argument is a file path, not a branch name
git checkout -- file.txt

# Using restore (modern way)
git restore file.txt

# Discard all unstaged changes
git restore .

# Discard all changes (staged and unstaged) - careful!
git reset --hard HEAD
```
