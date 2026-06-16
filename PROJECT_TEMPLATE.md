# Project Template Guide

A standardized structure for creating new VM-based learning projects.

> **Note:** This template is only for **VM projects** (with Vagrantfile, setup script, etc.).
> If you only need explanation/learning material (no VM), create the directory under `ai_written_guidelines/<topic>/` instead.

## Where Projects Are Created

- **VM projects** → created as a new directory at the **repository root** (e.g., `simple_vm/`, `docker_basic/`).
- **Explanation-only guides** → created inside `ai_written_guidelines/<topic>/` with markdown files only.

## Directory Structure

Every project should follow this structure:

```
project-name/
├── README.md                    # Project overview and quick start
├── setup-macos.sh              # Dependency installer for macOS
├── Vagrantfile                 # VM configuration
├── LINUX_LEARNING_GUIDE.md    # Comprehensive learning guide
└── provision.sh                # (Optional) VM provisioning script
```

## Quick Start: Creating a New Project

### 1. Create Project Directory at Repository Root

```bash
mkdir new-project
cd new-project
```

### 2. Generate README.md

```bash
cat > README.md << 'EOF'
# Project Name

## What is this?

[Describe what this project teaches/does]

Uses:
- **UTM** - Free, open-source virtualizer
- **Vagrant** - VM management
- **[OS/Distro]** - [What OS you're using]

**Total cost: $0** - Everything is free and open-source!

## Prerequisites

- Apple Silicon Mac (M1/M2/M3/M4)
- macOS (Ventura, Sonoma, or later)
- Internet connection

## Quick Setup

### Option 1: Automated Setup (Recommended)

```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

### Option 2: Manual Setup

```bash
# Install Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install --cask utm
brew install vagrant
vagrant plugin install vagrant_utm
```

## Starting the VM

```bash
# Start the VM
vagrant up --provider=utm

# Connect via SSH
vagrant ssh

# Stop the VM
vagrant halt

# Delete the VM (warning: irreversible)
vagrant destroy -f
```

## Learning Path

[Brief overview of what to learn]

See [LINUX_LEARNING_GUIDE.md](./LINUX_LEARNING_GUIDE.md) for detailed instructions.

## Project Structure

```
project-name/
├── README.md              # This file
├── setup-macos.sh        # Dependency installer
├── Vagrantfile           # VM configuration
└── LINUX_LEARNING_GUIDE.md  # Learning materials
```

## Resources

- **UTM**: https://mac.getutm.app/
- **Vagrant**: https://www.vagrantup.com/
- **[Topic Resource]**: [URL]
EOF
```

### 3. Generate setup-macos.sh

```bash
cat > setup-macos.sh << 'EOF'
#!/bin/bash
# Script to install dependencies for [PROJECT NAME] on macOS
# For Apple Silicon (M1/M2/M3/M4) Macs

set -e

echo "=========================================="
echo "[PROJECT NAME] - Setup"
echo "Installing required dependencies..."
echo "=========================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is for macOS only"
    exit 1
fi

# Check if running on Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo "Warning: This setup is optimized for Apple Silicon (ARM64)."
    echo "You're running on: $ARCH"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo ""
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo ""
    echo "Homebrew already installed. Updating..."
    brew update
fi

# Install UTM
echo ""
echo "Installing UTM..."
brew install --cask utm

# Install Vagrant
echo ""
echo "Installing Vagrant..."
brew install vagrant

# Install vagrant_utm plugin
echo ""
echo "Installing vagrant_utm plugin..."
vagrant plugin install vagrant_utm

# Verify installations
echo ""
echo "=========================================="
echo "Verifying installations..."
echo "=========================================="

echo -n "UTM: "
if command -v utmctl &> /dev/null; then
    echo "Installed ($(utmctl --version 2>&1 | head -1))"
else
    echo "Warning: UTM command line tools not found in PATH"
fi

echo -n "Vagrant: "
if command -v vagrant &> /dev/null; then
    vagrant --version
else
    echo "Not found"
fi

echo -n "vagrant_utm plugin: "
vagrant plugin list | grep utm || echo "Not found"

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Read the documentation: cat README.md"
echo "2. Start the VM: vagrant up --provider=utm"
echo "3. Connect: vagrant ssh"
echo ""
EOF

chmod +x setup-macos.sh
```

### 4. Generate Vagrantfile

```bash
cat > Vagrantfile << 'EOF'
Vagrant.configure("2") do |config|
  # [PROJECT NAME] - [Brief description]
  # Uses [OS/Distro]

  config.vm.box = "utm/bookworm"
  config.vm.hostname = "[vm-name]"

  # VM Specifications
  config.vm.provider "utm" do |v|
    v.name = "[vm-name]"
    v.memory = 2048  # 2GB RAM
    v.cpus = 1       # 1 CPU core
  end

  # Optional: Provisioning script
  # config.vm.provision "shell", path: "provision.sh"

  # Optional: Network configuration
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Optional: Shared folders
  # config.vm.synced_folder ".", "/vagrant", disabled: false
end
EOF
```

### 5. Create Learning Guide Template

```bash
# Copy and customize from existing project
cp ../simplevm/LINUX_LEARNING_GUIDE.md ./LINUX_LEARNING_GUIDE.md
# Then edit to match your project's topic
```

## File Templates by Project Type

### Type 1: Simple VM (like simplevm)

**Purpose**: Linux command learning, basic system administration

**Files needed:**
- `README.md` - Project overview
- `setup-macos.sh` - Install dependencies
- `Vagrantfile` - Single VM, 2GB RAM, 1 CPU
- `LINUX_LEARNING_GUIDE.md` - Linux basics, commands, bash scripting

**Vagrantfile settings:**
```ruby
v.memory = 2048
v.cpus = 1
```

### Type 2: Multi-VM Cluster (like kubernetes)

**Purpose**: Complex setups with multiple VMs

**Files needed:**
- `README.md` - Project overview
- `setup-macos.sh` - Install dependencies
- `Vagrantfile` - Multiple VMs with different roles
- `provision.sh` - Unified provisioning script (accepts role as argument)
- `KUBERNETES_LEARNING_GUIDE.md` - Topic-specific learning guide

**Vagrantfile settings:**
```ruby
# Master node
config.vm.define "master" do |m|
  m.vm.hostname = "master"
  m.vm.provider "utm" do |v|
    v.memory = 4096  # More RAM for master
    v.cpus = 2
  end
  m.vm.provision "shell", path: "provision.sh", args: "master"
end

# Worker node
config.vm.define "worker" do |w|
  w.vm.hostname = "worker"
  w.vm.provider "utm" do |v|
    v.memory = 2048
    v.cpus = 1
  end
  w.vm.provision "shell", path: "provision.sh", args: "worker"
end
```

**provision.sh template:**
```bash
#!/bin/bash
# Unified provisioning script
# Usage: ./provision.sh [role]

NODE_TYPE="${1:-}"

if [[ -z "$NODE_TYPE" ]]; then
    echo "Usage: $0 [master|worker|etc]"
    exit 1
fi

# Common setup for all nodes
echo "=== Common Setup ==="
apt update
apt install -y curl wget vim git

# Role-specific setup
if [[ "$NODE_TYPE" = "master" ]]; then
    echo "=== Master Setup ==="
    # Master-specific commands
fi

if [[ "$NODE_TYPE" = "worker" ]]; then
    echo "=== Worker Setup ==="
    # Worker-specific commands
fi
```

## Standard Learning Guide Structure

Every `*_LEARNING_GUIDE.md` should have:

```markdown
# [TOPIC] Learning Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Core Concepts](#core-concepts)
3. [Basic Commands](#basic-commands)
4. [Practice Exercises](#practice-exercises)
5. [Learning Path](#learning-path)
6. [Quick Reference](#quick-reference)

---

## Getting Started
[How to connect and basic info]

## Core Concepts
[Key concepts and architecture]

## Basic Commands
[Essential commands with examples]

## Practice Exercises
### Beginner Level
[Simple exercises]

### Intermediate Level
[More complex exercises]

### Advanced Level
[Challenging exercises]

## Learning Path
### Week 1: Basics
- [ ] Task 1
- [ ] Task 2

### Week 2: Intermediate
- [ ] Task 1
- [ ] Task 2

## Quick Reference
[Cheat sheet of commands]

## Resources
[Links to documentation, books, tutorials]
```

## AI Instructions for Creating New Content

When asked to create something, first determine which type:

### Type A: VM Project (with Vagrant/UTM)
Use this template. Create the directory at the **repository root**. The project will include a Vagrantfile, setup script, and learning guide.

### Type B: Explanation-Only Guide (no VM)
Create the directory under `ai_written_guidelines/<topic>/` with one or more markdown files. No Vagrantfile, no setup script — just learning material. Use the learning guide structure below as a reference.

---

### When creating a new VM project:

1. **Ask clarifying questions:**
   - What topic should the project teach?
   - How many VMs are needed?
   - What OS/distro should be used?
   - What are the learning objectives?

2. **Create the directory structure at the repository root:**
   ```bash
   mkdir -p new-project
   cd new-project
   ```

3. **Generate files using templates above:**
   - Customize README.md for the topic
   - Copy and adapt setup-macos.sh
   - Create appropriate Vagrantfile
   - Write topic-specific learning guide

4. **Ensure consistency:**
   - All projects use UTM + Vagrant + vagrant_utm
   - All use `utm/bookworm` box (unless specified otherwise)
   - All have executable setup-macos.sh
   - All have comprehensive learning guides

5. **Test the setup:**
   ```bash
   ./setup-macos.sh
   vagrant up --provider=utm
   vagrant ssh
   ```

## Example: Creating a Docker Learning Project

```bash
# 1. Create directory at repository root
mkdir -p docker-learning
cd docker-learning

# 2. Create README.md (customized for Docker)
# 3. Copy setup-macos.sh
# 4. Create Vagrantfile with more RAM (Docker needs it)
#    v.memory = 4096
# 5. Create DOCKER_LEARNING_GUIDE.md with:
#    - Docker installation
#    - Basic commands (run, ps, images, etc.)
#    - Dockerfile creation
#    - Docker Compose
#    - Practice exercises

# 6. Test
vagrant up --provider=utm
vagrant ssh
# Inside VM: install docker, follow guide
```

## Migration Checklist

When creating a new project from scratch:

- [ ] Create project directory
- [ ] Generate README.md with project description
- [ ] Generate setup-macos.sh and make executable
- [ ] Generate Vagrantfile with correct VM specs
- [ ] Create learning guide with standard structure
- [ ] (Optional) Create provision.sh for automated setup
- [ ] Test: run setup-macos.sh
- [ ] Test: run vagrant up --provider=utm
- [ ] Test: run vagrant ssh
- [ ] Document any special instructions in README.md

## AI Documentation Formatting Guide

When writing documentation for the `ai_written_guidelines/` directory, follow these formatting conventions exactly.

### File Organization

Each topic gets its own subdirectory under `ai_written_guidelines/<topic>/`. Files are numbered with a two-digit prefix for ordering:

```
ai_written_guidelines/<topic>/
├── 00-index.md               # Table of contents (always required)
├── 01-overview.md             # Overview / architecture (optional)
├── 02-<core-concept>.md       # Core topics
├── ...
├── NN-reference.md            # Command cheat sheet / reference
└── NN-comparison.md           # Comparison with alternative (optional)
```

**Conventions:**
- File names: lowercase kebab-case with numeric prefix — `<NN>-<short-kebab-case-title>.md`
- Index file: always `00-index.md`
- Every directory must have a `00-index.md` that serves as the table of contents

### Heading Structure

| Level | Format | Rule |
|-------|--------|------|
| H1 | `# Title` | Exactly one per file, matches the document topic |
| H2 | `## Section` | Primary organizational unit (3–8 per file) |
| H3 | `### Subsection` | Sub-topics within H2 sections |
| H4 | `#### Sub-subsection` | Rare, only in dense reference files |

### Code Blocks

- Use **fenced code blocks** with explicit language tags — never indented code blocks
- Language tags for common cases: `bash`, `python`, `c`, `cpp`, `rust`, `go`, `ini`, `yaml`, `json`, `ruby`
- Use an empty language tag (just ` ``` `) for log output, ASCII diagrams, or conceptual flowcharts
- Include `sudo` in shell commands directly rather than noting it separately

Example:
````markdown
```bash
sudo iptables -L -v -n
```
````

### Tables

Use GFM pipe tables with aligned pipes:

```markdown
| Header A | Header B |
|----------|----------|
| value 1  | value 2  |
```

- Default alignment (left) for text columns
- Centered alignment (`:---:|`) for checkmarks / yes-no columns
- Right alignment (`---:`) is never used

### Lists

- Unordered lists use `-` (hyphen) — never `*` or `+`
- Ordered lists use `1.` with automatic numbering
- Nested lists use 4-space indentation
- Term-definition pattern: `- **Term** -- description` (bold + space-dash-dash-space)

### Inline Formatting

- **Bold** (`**text**`) for key terms, command flags, file paths
- `Inline code` (backticks) for commands, paths, file names, types, context labels
- `---` (horizontal rule) used sparingly, mainly in index files
- `>` blockquotes for purpose statements: `> **Purpose:** Brief description`

### Cross-References

Use relative markdown links for internal links:

```markdown
[link text](./02-core-concept.md)
```

Full URLs only in Resources sections.

### Index File Structure (`00-index.md`)

Every index file follows this structure:

```markdown
# <Topic Title>

One-paragraph summary of what this guide covers.

## Contents

| File | Topic | Description |
|------|-------|-------------|
| [01-overview.md](./01-overview.md) | Overview | What it is and key concepts |

## Quick Start

```bash
<sample commands>
```

## Package Installation (for system-tool guides only)

Shows commands for both Fedora/RHEL (`dnf`) and Debian/Ubuntu (`apt`).

## Resources

- [External Link](url)
```

### Content File Template

```markdown
# <Document Title>

## <H2 Section>

Introductory prose paragraph.

```<language>
<code examples>
```

### <H3 Subsection (optional)>

...
```

### Comparison File Template

```markdown
# <Topic A> vs <Topic B>

Introduction paragraph.

## Core Philosophy

| Aspect | Topic A | Topic B |
|--------|---------|---------|

## Pros and Cons

### Topic A Pros
- ...

### Topic A Cons
- ...

## When to Use Each

### Choose Topic A When
- ...

## Quick Comparison Table

| Feature | Topic A | Topic B |
|---------|---------|---------|
```

### Topic Categorization

- **Language/programming guides** (bash, python, c, cpp, golang, rust): Split index into **Essentials** (basics, syntax, control flow) and **DevOps & Automation** (CLI tools, APIs, testing)
- **System-tool guides** (selinux, apparmor, iptables, firewalld, rsync, ssh): Linear progression — Overview → Core Concepts → Intermediate → Practical Examples → Advanced → Reference → Comparison

### AI Writing Rules

When an AI agent writes documentation for `ai_written_guidelines/`:

1. **Always ask first** what topic the user wants documented
2. **Plan the file structure** — decide which files are needed (minimum: `00-index.md` + content files + `NN-reference.md`)
3. **Use exactly one H1 per file** — no exceptions
4. **Every code block must have a language tag** (or be empty-tagged for output/diagrams)
5. **Use pipe tables**, not HTML tables or other markdown table syntax
6. **Use `-` for bullets** in unordered lists — never `*` or `+`
7. **Use relative links** (not full URLs) for cross-references within the guide
8. **Keep consistent numbering** — files are numbered sequentially with two-digit prefixes
9. **Include installation instructions** for both Fedora/RHEL and Debian/Ubuntu in system-tool guides
10. **End with a reference file** (`NN-reference.md`) containing a command cheat sheet

## File Naming Conventions

| File | Naming Pattern | Example |
|------|----------------|---------|
| Learning Guide | `[TOPIC]_LEARNING_GUIDE.md` | `DOCKER_LEARNING_GUIDE.md` |
| README | `README.md` | Always the same |
| Setup Script | `setup-macos.sh` | Always the same |
| Provision Script | `provision.sh` | For multi-VM projects |
| Vagrant Config | `Vagrantfile` | Always the same |

## Common Customizations

### Increase VM Resources

```ruby
# For resource-intensive projects (Docker, K8s, etc.)
v.memory = 4096  # 4GB
v.cpus = 2

# For simple learning
v.memory = 2048  # 2GB
v.cpus = 1
```

### Add Port Forwarding

```ruby
# Access VM service from host
config.vm.network "forwarded_port", guest: 80, host: 8080
config.vm.network "forwarded_port", guest: 3306, host: 3306
```

### Add Shared Folders

```ruby
# Share host folder with VM
config.vm.synced_folder "./projects", "/home/vagrant/projects"
```

### Multiple Network Interfaces

```ruby
# Static IP for VM-to-VM communication
config.vm.network "private_network", ip: "192.168.56.10"
```

## Troubleshooting New Projects

### Issue: VM won't start
- Check UTM is installed: `open -a UTM`
- Check plugin: `vagrant plugin list | grep utm`
- Verify box: `vagrant box list`

### Issue: Provisioning fails
- Check script is executable: `chmod +x provision.sh`
- Test script manually inside VM
- Check logs: `vagrant ssh -c "journalctl -xe"`

### Issue: Learning guide too long
- Break into multiple files if needed
- Use Table of Contents for navigation
- Keep exercises practical and testable

------

**Use this template to quickly scaffold new learning projects with consistent structure!**
