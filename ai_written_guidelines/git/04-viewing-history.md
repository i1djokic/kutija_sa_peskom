# Viewing History

## Commit Log

```bash
git log                          # Full log
git log --oneline                # Compact (one line per commit)
git log --oneline --graph        # With branch graph
git log --oneline --graph --all  # Show all branches
git log -5                       # Last 5 commits
```

## Filtering the Log

```bash
git log --author="John"                 # By author
git log --since="2 weeks ago"           # By date
git log --until="2024-01-01"            # Until date
git log --grep="bugfix"                 # By commit message
git log -- file.txt                     # Commits touching a file
git log --follow -- file.txt            # Include renames
git log -S "functionName"               # Commits that changed a string
git log --oneline --no-merges           # Exclude merge commits
```

## Viewing Changes (Diffs)

```bash
git diff                         # Unstaged changes
git diff --staged                # Staged changes (what will be committed)
git diff HEAD                    # All changes since last commit
git diff HEAD~1..HEAD            # Changes in the last commit
git diff main..feature           # Changes between two branches
git diff --stat                  # Summary (files changed, insertions, deletions)
```

## Inspecting Commits

```bash
git show <commit-hash>           # Show a specific commit (diff + metadata)
git show HEAD                    # Latest commit
git show HEAD:file.txt           # Show file as it was in HEAD
git show --stat <commit-hash>    # Stats only
```

## Blame

```bash
# Who last modified each line of a file
git blame file.txt

# With ignore whitespace
git blame -w file.txt
```
