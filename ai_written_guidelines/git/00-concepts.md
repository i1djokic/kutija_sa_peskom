# Key Concepts

Terms and ideas used throughout this guide that are helpful to understand up front.

## HEAD

`HEAD` is a pointer to the commit you currently have checked out. It usually points to a branch (e.g., `HEAD -> main`), which means it moves when you make new commits on that branch. When you check out a specific commit instead of a branch, `HEAD` points directly to that commit — this is called a **detached HEAD**.

```
HEAD -> main -> a1b2c3d   (normal: HEAD points to a branch)
HEAD -> a1b2c3d           (detached: HEAD points directly to a commit)
```

## origin

`origin` is the default name git gives to the remote repository you cloned from. When you run `git clone <url>`, git automatically creates a remote called `origin` pointing to that URL.

```bash
git remote -v
# origin  https://github.com/user/repo.git (fetch)
# origin  https://github.com/user/repo.git (push)
```

## Staging Area (Index)

The staging area (also called the **index**) is a middle step between your working directory and a commit. You `git add` files to stage them, then `git commit` to create a commit from what's staged.

```
Working Directory  ──git add──>  Staging Area (Index)  ──git commit──>  Repository
     (files on disk)              (what will be committed)            (commit history)
```

## `~` (Tilde) Parent Notation

`~` refers to a commit's parent. `~1` means "one commit before", `~2` means "two commits before", and so on.

```
HEAD~1   = the parent of HEAD (one commit back)
HEAD~2   = the grandparent (two commits back)
HEAD~    = HEAD~1 (shorthand, same thing)
HEAD~N   = N commits back
```

## `..` (Double Dot) Range Notation

`A..B` means "all commits reachable from B that are not reachable from A". In practice, it's the range of commits from A up to (but not including) A.

```bash
git log main..feature       # Commits in feature but not in main
git cherry-pick A..B        # Apply commits from A to B (excluding A)
```

## Fast-Forward Merge

When the branch you're merging into hasn't diverged (no new commits since you branched), git simply moves the pointer forward — this is a **fast-forward**. No merge commit is created.

```
Before merge (on main):
main:   a---b---c
                   \
feature             d---e

After git merge feature (fast-forward):
main:   a---b---c---d---e
```

`--no-ff` forces a merge commit even when fast-forward is possible, which preserves the branch history visually:

```
After git merge --no-ff feature:
main:   a---b---c-----------f  (merge commit)
                   \       /
feature             d---e
```

## Upstream

The **upstream** is the remote branch that your local branch tracks. When set, you can run `git push` and `git pull` without specifying a remote or branch name. `git push -u origin feature-xyz` sets the upstream on first push.

```bash
git push -u origin feature-xyz   # Push and set upstream
# later: just git push works
```

## Hunk

A **hunk** is a contiguous section of a diff (a group of changed lines, usually a few lines apart). When you run `git add -p`, git shows you each hunk one at a time and asks if you want to stage it.

A hunk looks like this in a diff:

```diff
@@ -10,7 +10,7 @@
 function greet(name) {
-    return "Hello, " + name;
+    return "Hi, " + name + "!";
 }
```

## `--` Separator

The `--` tells git that everything after it is a file path, not a branch or option name. This is needed when a filename could be confused with a branch or command.

```bash
git checkout -- file.txt   # "restore file.txt, not a branch"
git checkout bugfix        # "switch to branch named bugfix"
```
