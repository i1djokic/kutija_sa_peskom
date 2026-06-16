# Rebasing & Cherry-Pick

## Interactive Rebase

Combine, reorder, or edit commits before pushing.

### Squashing Commits

Merge multiple commits into one:

```bash
# -i = interactive (opens an editor to choose what to do with each commit)
git rebase -i HEAD~4
```

In the editor:

```
pick  a1b2c3 First commit
squash d4e5f6 Second commit     # merge into previous
fixup  g7h8i9 Oops message      # merge, discard its message
squash j0k1l2 WIP               # merge into previous
```

- `pick` — keep as is
- `squash` — merge into the commit above, keep message
- `fixup` — merge into the commit above, discard message
- `reword` — change commit message
- `edit` — stop to amend
- `drop` — remove the commit

Save and close. Git will squash and prompt for a new message.

### Rewording a Commit

```bash
git rebase -i HEAD~5
# Change 'pick' to 'reword' on the commit, save, then edit the message
```

### Dropping a Commit

```bash
git rebase -i HEAD~5
# Change 'pick' to 'drop' on the commit, save
```

### Reordering Commits

```bash
git rebase -i HEAD~4
# Reorder the lines in the editor, save
```

## Splitting a Commit

Break one commit into smaller, logical commits:

```bash
git rebase -i HEAD~3
# Change 'pick' to 'edit' on the commit you want to split
# Save and close - Git stops at that commit

git reset HEAD~                  # Uncommit but keep changes staged (HEAD~ is shorthand for HEAD~1)
git add part1.txt
git commit -m "Part 1: add model"
git add part2.txt
git commit -m "Part 2: add controller"

git rebase --continue
```

## Cherry-Pick

Apply a specific commit from another branch:

```bash
# Copy a single commit
git checkout main
git cherry-pick <commit-hash>

# Copy a range of commits (A..B = commits from A up to B, excluding A)
git cherry-pick <hash-a>..<hash-b>

# Cherry-pick without committing (useful for editing)
# -n = --no-commit (applies changes to working directory but doesn't create a commit)
git cherry-pick -n <commit-hash>
```

## Important: Do Not Rebase Shared Branches

**About `~` notation:** `HEAD~4` means "4 commits before HEAD". See [00-concepts.md](./00-concepts.md) for the full explanation.

**About `..` notation:** `A..B` means "commits from A to B, excluding A". See [00-concepts.md](./00-concepts.md) for more.

**Never** rebase commits that have already been pushed to a shared branch. Rebasing rewrites history — anyone else who has pulled your branch will have divergent history.

**Never** rebase commits that have already been pushed to a shared branch. Rebasing rewrites history — anyone else who has pulled your branch will have divergent history.

Safe use cases:
- Local branches not yet pushed
- Personal feature branches before PR
- Cleaning up history before merging into main

Use `git merge` instead of rebase on shared/public branches.
