# kutija sa peskom — Sandbox for Learning DevOps & Infrastructure

A hands-on, zero-cost learning environment for DevOps, infrastructure, and systems engineering. Spin up disposable virtual machines on your Linux machine, work through guided projects, and tear it all down — no cloud bills, no permanent setup.

## What You Can Do With This Project

- **Learn Linux from scratch** — fire up a Debian VM and work through a 800-line guide covering everything from filesystem navigation to bash scripting.
- **Practice Docker and container orchestration** — run Docker inside a VM (single node or a multi-node Swarm cluster) and learn services, scaling, stacks, and routing mesh.
- **Build a Kubernetes cluster** — deploy a single-node K3s cluster or a multi-node K8s cluster on your local machine.
- **Automate with Ansible** — provision a multi-VM environment and learn configuration management, playbooks, roles, and inventory management.
- **Explore AWS serverless** — use a local AWS emulator (floci) to learn API Gateway and Lambda without cloud costs.
- **Deploy real applications with GitOps** — work through ArgoCD deployments and Helm chart management on your local K8s cluster.
- **Read deep-dive guides** — choose from 22+ topic areas (Python, Go, Rust, Git, SSH, Kubernetes, SELinux, monitoring, and more) with AI-written, structured markdown guides.
- **Grab quick cheatsheets** — 17 concise references covering Docker, Kubernetes, Git, Terraform, CI/CD, networking, SQL, and AI-assisted coding.

## Repository Structure

### 1. VM Learning Projects (root directories)

Standardized, free VM-based learning projects optimized for **Linux hosts using Libvirt + KVM + Vagrant**. Each project is self-contained with a Vagrantfile, setup script, and a comprehensive learning guide.

| Directory | What you'll learn |
|-----------|------------------|
| `simple_vm/` | Linux fundamentals, bash scripting, system administration |
| `docker_basic/` | Docker, Docker Compose, container lifecycle |
| `docker_swarm/` | Docker Swarm orchestration, multi-node services |
| `ansible_automation/` | Ansible playbooks, roles, inventory, automation |
| `kubernetes/` | K3s single-node, K8s two-node, Helm charts, ArgoCD, raw manifests |
| `aws_api_gateway/` | API Gateway + Lambda with local AWS emulator |
| `local_aws_services/` | floci AWS emulator (41 services, 24ms startup) |
| `vm_image_builder/` | Build custom Vagrant boxes for libvirt |
| `application_examples/` | Real apps deployed with Helm + ArgoCD |
| `pytest_examples/` | Python testing patterns with pytest |

### 2. AI-Written Explanations (`ai_written_guidelines/`)

22 topic areas with pure markdown guides — no VMs, no setup. Just structured deep-dives into programming, infrastructure, and DevOps concepts.

Topics include: Python, Go, Rust, C, C++, Bash, Git, SSH, Kubernetes (StatefulSets, persistent storage, pod security), ELK Stack, firewalld, iptables, SELinux, AppArmor, rsync, GitOps, AWS CDK (Python + TypeScript), and Linux monitoring.

### 3. Short Docs (`short-docs/`)

17 cheatsheets for quick reference: Docker, Kubernetes, Helm, ArgoCD, Git, GitHub Actions, Jenkins, Terraform, CloudFormation, networking, SQL, and AI-assisted coding.

## Prerequisites

- Linux host (any distribution with KVM support)
- libvirt + QEMU/KVM
- Vagrant with `vagrant-libvirt` plugin
- Internet connection

## Getting Started

1. Pick a project directory (e.g., `simple_vm/`)
2. Run `./setup-linux.sh` to install dependencies
3. Start the VM: `vagrant up` (the libvirt provider is already configured in the Vagrantfile)
4. Connect: `vagrant ssh`
5. Follow the project's learning guide

When you're done, tear everything down with `vagrant destroy -f`.

## Creating New Content

When asking an AI assistant to create something, clarify **which type** you want:

- **For a VM project** → reference `@PROJECT_TEMPLATE.md`. The AI will create a new directory at the repository root with all required files (Vagrantfile, setup script, learning guide, etc.).

- **For an explanation-only guide** → the AI will create a new directory inside `ai_written_guidelines/<topic>/` with one or more markdown files. No VMs or Vagrant — just learning material.

## Standard Project Structure

```
project-name/          (at repository root)
├── README.md
├── setup-linux.sh
├── Vagrantfile
├── [TOPIC]_LEARNING_GUIDE.md
└── provision.sh (optional)
```

## Resources

- Vagrant: https://www.vagrantup.com/
- vagrant-libvirt: https://github.com/vagrant-libvirt/vagrant-libvirt
- Libvirt: https://libvirt.org/
