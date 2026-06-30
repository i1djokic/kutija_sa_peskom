# Git — DevOps Cheatsheet

## Configuration

```bash
git config --global user.name "Name"
git config --global user.email "e@mail.com"
git config --global core.editor vim
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true
git config --global alias.co checkout
git config --list
```

## Basics

```bash
git init
git clone <url>
git add <file>
git add -p                    # interactive partial add
git add -A                    # all changes
git commit -m "msg"
git commit -a -m "msg"        # add tracked + commit
git commit --amend            # fix last commit msg
git commit --amend --no-edit  # add staged to last commit
git rm <file>
git mv <old> <new>
git status
git status -s                 # short
git log --oneline --graph --all -20
```

## Diff

```bash
git diff                      # working vs staged
git diff --staged             # staged vs last commit
git diff main..feature        # branch diff
git diff HEAD~1               # diff since last commit
git diff --name-only          # filenames only
git diff --stat               # stats
```

## Branch

```bash
git branch                    # list local
git branch -a                 # all (local + remote)
git branch <name>
git branch -d <name>          # delete (merged)
git branch -D <name>          # delete (force)
git checkout <branch>
git checkout -b <branch>      # create + switch
git switch <branch>           # modern checkout
git switch -c <branch>        # create + switch
git branch -m <old> <new>     # rename
git branch -r                 # remote branches
```

## Merge & Rebase

```bash
# merge
git checkout main && git merge feature
git merge --no-ff feature    # keep branch history

# rebase
git checkout feature && git rebase main
git rebase -i HEAD~3         # interactive (squash, reword, reorder)

# conflict resolution
git mergetool                 # open merge tool
git rebase --continue
git rebase --abort
git merge --abort

# pull strategies
git pull --rebase            # preferred over merge
git pull --ff-only           # fail if not fast-forward
```

## Stash

```bash
git stash                    # save dirty work
git stash pop                # apply + drop
git stash apply stash@{0}    # apply but keep
git stash list
git stash drop stash@{0}
git stash push -m "msg"      # named stash
git stash -u                 # include untracked
```

## Remote

```bash
git remote -v
git remote add origin <url>
git remote remove origin
git remote set-url origin <url>
git fetch origin
git pull origin main
git push origin main
git push -u origin feature    # set upstream
git push origin --delete <branch>  # delete remote branch
git push --tags
git push origin :<branch>    # delete remote branch (alt)
```

## Tags

```bash
git tag                      # list
git tag v1.0.0
git tag -a v1.0.0 -m "release 1.0.0"  # annotated
git tag -d v1.0.0            # delete local
git push origin v1.0.0       # push specific tag
git push origin --tags       # push all tags
git push --delete origin v1.0.0  # delete remote tag
git checkout v1.0.0          # detach to tag
```

## Reset & Revert

```bash
# soft — keep changes staged
git reset --soft HEAD~1

# mixed (default) — keep changes unstaged
git reset HEAD~1

# hard — discard everything
git reset --hard HEAD~1
git reset --hard origin/main  # match remote

# revert (safe for shared branches)
git revert HEAD               # new commit undoing HEAD
git revert HEAD~3..HEAD       # revert range
```

## Cherry-pick

```bash
git cherry-pick <commit-hash>
git cherry-pick -n <hash>    # no auto-commit
git cherry-pick A..B         # pick range (A excluded)
```

## Bisect

```bash
git bisect start
git bisect bad               # current is bad
git bisect good <known-good-hash>  # mark good
# git will checkout middles — test then mark
git bisect good
git bisect bad
git bisect reset
```

## Reflog

```bash
git reflog                   # history of HEAD movements
git reset --hard HEAD@{2}    # recover lost commit
git checkout HEAD@{yesterday}
```

## Submodules

```bash
git submodule add <url> path
git submodule update --init --recursive
git submodule foreach git pull origin main
git clone --recurse-submodules <url>
```

## Clean

```bash
git clean -n                 # dry run
git clean -fd                # remove untracked files + dirs
git clean -fdx               # include ignored files
```

## Advanced

```bash
# search
git log -S "function"        # commits that changed "function"
git log -p -S "function"     # with diff
git grep "pattern"           # search working tree
git log --grep="fix"         # commits with msg matching

# blame
git blame file.txt
git blame -L 10,20 file.txt

# show
git show HEAD
git show <hash>:file.txt     # show file at commit

# archive
git archive --format=zip HEAD > archive.zip

# worktree (multiple branches checked out)
git worktree add ../hotfix hotfix

# hooks
# .git/hooks/pre-commit, pre-push, post-merge, etc.
```

## Workflows

```bash
# feature branch
git checkout -b feature/xyz main
# ... work, commit ...
git fetch origin
git rebase origin/main
git push -u origin feature/xyz
# PR → merge → delete

# hotfix
git checkout -b hotfix/1.0.1 main
git commit -m "fix: critical"
git push -u origin hotfix/1.0.1
# PR to main + backport to develop

# sync fork
git remote add upstream <original-url>
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## One-liners

```bash
# delete merged branches (except main)
git branch --merged | grep -v '\*\|main\|master' | xargs git branch -d

# list commits by author
git log --author="name" --oneline

# total commits count
git rev-list --count HEAD

# files changed in last commit
git diff --name-only HEAD~1

# last commit changed a file
git log -1 --oneline -- file.txt

# squash last N commits (interactive)
git rebase -i HEAD~N

# undo last commit but keep changes
git reset --soft HEAD~1

# undo file to last commit state
git checkout -- file.txt

# stage parts of a file
git add -p file.txt

# show remote URL
git remote get-url origin

# list all branches sorted by last commit
git branch --sort=-committerdate
```

## Key Concepts

| Concept | Summary |
|---------|---------|
| **Working tree** | your current files |
| **Index/staging** | area before commit |
| **Commit** | snapshot of staged changes |
| **HEAD** | pointer to current commit/branch |
| **Branch** | movable pointer to a commit |
| **Remote** | remote repo reference |
| **Tracking** | local branch linked to remote |
| **Fast-forward** | linear history merge (no merge commit) |
| **Detached HEAD** | checked out a commit, not a branch |
| **Reflog** | history of HEAD (use to recover) |
| **Origin** | conventional name for primary remote |
| **Upstream** | fork source remote |
| **DETACHED HEAD** | not on a branch — commit will be lost without a branch |
