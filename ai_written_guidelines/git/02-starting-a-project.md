# Starting a Project

## Installing Git

### macOS
```bash
# Homebrew (https://brew.sh) — macOS package manager
brew install git
```

### Linux (Debian/Ubuntu)
```bash
# sudo = run as administrator, apt = Debian package manager
sudo apt update && sudo apt install git
```

### Verify installation
```bash
git --version
```

## Initializing a New Repository

```bash
mkdir my-project && cd my-project
git init
```

## Cloning an Existing Repository

```bash
# HTTPS
git clone https://github.com/user/repo.git

# SSH (requires SSH key setup — see https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
git clone git@github.com:user/repo.git

# Custom directory name
git clone https://github.com/user/repo.git my-folder

# Shallow clone (faster, skips full history)
git clone --depth 1 https://github.com/user/repo.git
```
