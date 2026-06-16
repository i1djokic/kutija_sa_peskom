# Merge Conflicts

## What a Conflict Looks Like

When git can't automatically merge, you'll see:

```
Auto-merging file.txt
CONFLICT (content): Merge conflict in file.txt
Automatic merge failed; fix conflicts and then commit the result.
```

## Finding Conflicted Files

```bash
git status
```

Files with conflicts are listed under "both modified".

## Conflict Markers

Inside a conflicted file:

```
<<<<<<< HEAD
your changes
=======
incoming changes
>>>>>>> branch-name
```

- `<<<<<<< HEAD` — your current branch's version
- `=======` — divides the two versions
- `>>>>>>> branch-name` — the incoming branch's version

## Resolving

1. Open the file and decide what to keep
2. Remove the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
3. Edit the code to the correct final state

## Marking as Resolved

```bash
git add resolved-file.txt
git commit -m "Resolve merge conflict between main and feature-xyz"
```

## Using a Merge Tool

```bash
git mergetool
```

This opens your configured merge tool (vimdiff, meld, Kaleidoscope, etc.).

Common merge tools:

```bash
git config --global merge.tool vimdiff
git config --global merge.tool meld
git config --global merge.tool kdiff3
```

## Aborting a Merge

```bash
git merge --abort
```

This returns your repo to the state before the merge started.

## Handling Conflicts During Rebase

```bash
# After resolving conflicts during rebase:
git add resolved-file.txt
git rebase --continue

# Skip this commit:
git rebase --skip

# Abort the rebase entirely:
git rebase --abort
```

## Preventing Conflicts

- Pull frequently to stay up to date
- Communicate with team about shared files
- Keep feature branches short-lived
- Use `git pull --rebase` for a cleaner history
