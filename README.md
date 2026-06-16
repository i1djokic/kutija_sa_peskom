# VM Learning Projects

## Overview

This repository contains two types of AI-generated content:

### 1. VM Learning Projects (root directory)
Standardized, free VM-based learning projects for Apple Silicon Macs. Uses UTM + Vagrant to create sandboxed environments for learning Linux, DevOps, and infrastructure topics. Total cost: $0.

Each project lives in its own directory at the root level (e.g., `simple_vm/`, `docker_basic/`, `kubernetes/`).

### 2. AI-Written Explanations (`ai_written_guidelines/`)
Pure markdown guides explaining programming, infrastructure, or DevOps concepts. These do **not** include VMs or Vagrant setup — just explanations. Created in `ai_written_guidelines/<topic>/`.

## Prerequisites
- Apple Silicon Mac (M1/M2/M3/M4)
- macOS Ventura+
- Internet connection

## Using Existing Projects
1. Navigate to a project subdirectory (e.g., `simple_vm/`)
2. Run `./setup-macos.sh` to install dependencies
3. Start VM: `vagrant up --provider=utm`
4. Connect: `vagrant ssh`
5. Follow the project's learning guide

## Creating New Content

When asking an AI assistant to create something, clarify **which type** you want:

- **For a VM project** → reference `@PROJECT_TEMPLATE.md`. The AI will create a new directory at the repository root with all required files (Vagrantfile, setup script, learning guide, etc.).

- **For an explanation-only guide** → the AI will create a new directory inside `ai_written_guidelines/<topic>/` with one or more markdown files. No VMs or Vagrant — just learning material.

## Standard Project Structure
```
project-name/          (at repository root)
├── README.md
├── setup-macos.sh
├── Vagrantfile
├── [TOPIC]_LEARNING_GUIDE.md
└── provision.sh (optional)
```

## Resources
- UTM: https://mac.getutm.app/
- Vagrant: https://www.vagrantup.com/
- vagrant_utm: https://github.com/utmapp/vagrant-utm
