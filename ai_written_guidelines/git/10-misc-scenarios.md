# Miscellaneous Scenarios

## Detached HEAD State

Happens when you check out a specific commit instead of a branch:

```bash
git checkout <commit-hash>       # Now in detached HEAD

# If you just want to look around - go back to your branch
git checkout main

# If you made commits and want to keep them
git checkout -b new-branch
# Or in two steps:
git branch new-branch
git checkout new-branch
```

## Untracked Files Won't Go Away

Remove untracked files from the working directory:

```bash
git clean -n                      # Dry run (shows what would be deleted)
git clean -f                      # Force delete untracked files
git clean -fd                     # Also delete untracked directories
git clean -fx                     # Also delete gitignore'd files

# Get a pristine state
git reset --hard HEAD && git clean -fd
```

## Renaming a File

Git detects renames automatically, but using `git mv` stages the change:

```bash
git mv old-name.txt new-name.txt
git commit -m "Rename old-name.txt to new-name.txt"
```

## Tags

Tags are fixed labels pointing to a specific commit. Use them to mark releases.

```bash
# List tags
git tag
git tag -l "v1.*"                # Wildcard filter

# Create tags
git tag v1.0.0                   # Lightweight tag (just a pointer)
git tag -a v1.0.0 -m "Release v1.0.0"  # Annotated tag (stores message, author, date — recommended)

# Push tags
git push origin v1.0.0           # Push a single tag
git push origin --tags           # Push all tags

# Delete tags
git tag -d v1.0.0                # Local
git push origin --delete v1.0.0  # Remote

# Checkout a tag (creates detached HEAD)
git checkout v1.0.0
git checkout -b release-v1.0.0   # To make changes on a branch
```

## Accidentally Committed a Secret

```bash
# WARNING: Even if you remove it from history, assume the secret is compromised.
# Rotate the secret immediately.

# Remove file from git tracking but keep locally
git rm --cached secrets.txt
echo "secrets.txt" >> .gitignore

# Rewrite history (only if not pushed to shared branch)
git rebase -i HEAD~N             # Mark commit for edit, or
# --tree-filter runs a command against every commit's file tree
git filter-branch --tree-filter 'rm -f secrets.txt' HEAD

# For serious cases, use git-filter-repo:
# https://github.com/newren/git-filter-repo

# Force push
git push --force-with-lease origin branch-name
```

## Submodules

A **submodule** is a git repo embedded inside another git repo. The parent repo stores which commit hash the submodule should be at.

```bash
# Clone with submodules
git clone --recurse-submodules <repo-url>

# Update submodules after clone
# --init = first-time setup, --recursive = also init nested submodules inside submodules
git submodule update --init --recursive

# Add a submodule
git submodule add https://github.com/user/lib.git lib/

# Update all submodules to the latest commit from their remote
# --remote = fetch latest from the submodule's remote, --merge = merge into local submodule branch
git submodule update --remote --merge

# After submodule changes, commit the update in the parent repo:
git add lib/
git commit -m "Update lib submodule to latest"
```
