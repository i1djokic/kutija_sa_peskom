# Configuration

## Identity

Required before your first commit:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Default Branch Name

Set the default branch name for `git init`:

```bash
git config --global init.defaultBranch main
```

## Aliases

Common shortcuts:

```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all --decorate"
```

## Viewing Configuration

```bash
git config --list                  # All config
git config --global --list         # Global config only
git config user.name               # Single value
```

## Editor

Set the default editor for commit messages and rebase:

```bash
git config --global core.editor vim
git config --global core.editor "code --wait"   # VS Code
git config --global core.editor nano
```

## Pull Behavior

Set rebase as default for `git pull`:

```bash
git config --global pull.rebase true
```

## Merge Tool

Set a diff/merge tool:

```bash
git config --global merge.tool vimdiff
git config --global diff.tool vimdiff
```
