# Git Quick Reference

## Setup & Config

| Command | What it does |
|---------|-------------|
| `git init` | Create a new repo |
| `git clone <url>` | Copy a remote repo |
| `git config --global user.name "Name"` | Set commit author name |
| `git config --global user.email "e@mail"` | Set commit author email |
| `git config --global init.defaultBranch main` | Default branch for init |
| `git config --list` | Show all config |

## Daily Workflow

| Command | What it does |
|---------|-------------|
| `git status` | Show working tree status |
| `git status -s` | Short status |
| `git add <file>` | Stage changes |
| `git add -p` | Stage interactively (hunk by hunk) |
| `git commit -m "msg"` | Commit staged changes |
| `git commit -am "msg"` | Stage tracked + commit in one step |
| `git push origin <branch>` | Push to remote |
| `git pull origin <branch>` | Pull from remote (fetch + merge) |
| `git pull --rebase` | Pull with rebase (cleaner history) |
| `git fetch` | Fetch remote changes without merging |
| `git fetch --prune` | Fetch and remove deleted remote refs |

## Viewing History

| Command | What it does |
|---------|-------------|
| `git log --oneline --graph` | Visual commit history |
| `git log --oneline --graph --all` | All branches |
| `git log --author="X"` | Filter by author |
| `git log --since="2 weeks ago"` | Filter by date |
| `git log -p` | Show diffs in log |
| `git diff` | Show unstaged changes |
| `git diff --staged` | Show staged changes |
| `git diff main..feature` | Diff between branches |
| `git show <commit>` | Show a specific commit |
| `git blame <file>` | Who last modified each line |

## Branching

| Command | What it does |
|---------|-------------|
| `git branch` | List local branches |
| `git branch -a` | List all branches |
| `git checkout -b <branch>` | Create and switch (classic) |
| `git switch -c <branch>` | Create and switch (modern) |
| `git merge <branch>` | Merge branch into current |
| `git merge --no-ff <branch>` | Force merge commit (preserves branch history) |
| `git rebase <branch>` | Rebase current onto branch |
| `git branch -d <branch>` | Delete local branch (safe) |
| `git branch -D <branch>` | Force delete local branch |
| `git push origin --delete <branch>` | Delete remote branch |

## Undoing Changes

| Command | What it does |
|---------|-------------|
| `git reset --soft HEAD~1` | Undo last commit, keep staged |
| `git reset HEAD~1` | Undo last commit, keep working dir |
| `git reset --hard HEAD~1` | Discard last commit and all changes |
| `git reset --hard HEAD` | Discard all uncommitted changes |
| `git revert <commit>` | Undo commit with new commit (safe) |
| `git restore <file>` | Discard unstaged changes in file |
| `git clean -fd` | Remove untracked files/dirs |
| `git clean -n` | Dry run for clean |

## Stash

| Command | What it does |
|---------|-------------|
| `git stash` | Save changes temporarily |
| `git stash -m "msg"` | Save with message |
| `git stash -u` | Save including untracked files |
| `git stash pop` | Apply latest stash and remove it |
| `git stash apply` | Apply stash without removing |
| `git stash list` | List all stashes |
| `git stash drop stash@{N}` | Drop a specific stash |
| `git stash clear` | Remove all stashes |

## Rebasing & Cherry-Pick

| Command | What it does |
|---------|-------------|
| `git rebase -i HEAD~N` | Interactive rebase (squash, reorder) |
| `git rebase --continue` | Continue after resolving conflicts |
| `git rebase --abort` | Abort rebase |
| `git cherry-pick <commit>` | Apply commit to current branch |
| `git cherry-pick -n <commit>` | Cherry-pick without auto-commit |

## Tags

| Command | What it does |
|---------|-------------|
| `git tag` | List tags |
| `git tag -a v1.0 -m "msg"` | Create annotated tag |
| `git push origin v1.0` | Push a single tag |
| `git push origin --tags` | Push all tags |
| `git tag -d v1.0` | Delete local tag |

## Miscellaneous

| Command | What it does |
|---------|-------------|
| `git mv <old> <new>` | Rename a file |
| `git rm --cached <file>` | Untrack file (keep locally) |
| `git remote -v` | Show remotes |
| `git remote add origin <url>` | Add a remote |
| `git commit --amend -m "msg"` | Change last commit message |
| `git commit --amend --no-edit` | Add to last commit without editing message |
| `git submodule update --init --recursive` | Init/update submodules |
| `git push --force-with-lease` | Force push (safer than --force) |
