# Ansible Automation Environment

Ansible automation environment with Vagrant-managed Debian Bookworm VMs.

- **libvirt/KVM** — virtualizer
- **Vagrant** — VM management
- **Ansible** — automation engine
- **Debian Bookworm** — target OS

## Prerequisites

- Linux with KVM-capable CPU
- libvirt + Vagrant installed

## Quick Start

```bash
# 1. Install dependencies
chmod +x setup-linux.sh && ./setup-linux.sh

# 2. Log out & back in (or: newgrp libvirt)

# 3. Start VMs
vagrant up --provider=libvirt

# 4. Generate SSH config for Ansible
./scripts/generate-ssh-config.sh

# 5. Test connection
ansible all -m ping

# 6. Run the full playbook
ansible-playbook playbooks/vagrant.yml
```

## Project Structure

```
ansible_automation/
├── ansible.cfg                        # Ansible configuration
├── Vagrantfile                        # VM definition (1+ VMs)
├── provision.sh                       # VM provisioning script
├── setup-linux.sh                     # Host dependency installer
├── requirements.yml                    # Ansible Galaxy deps
├── .gitignore
├── scripts/
│   ├── generate-ssh-config.sh         # Regenerate Vagrant SSH config
│   └── vagrant-inventory.sh           # Dynamic inventory script
├── inventory/
│   ├── vagrant/
│   │   ├── hosts.yml                  # Vagrant VM inventory
│   │   └── group_vars/all.yml         # Vagrant connection vars
│   ├── staging/                       # Staging environment
│   └── production/                    # Production environment
├── group_vars/all.yml                 # Global defaults
├── playbooks/
│   ├── vagrant.yml                    # Vagrant full setup (packages + apache)
│   ├── site.yml                       # Production site playbook
│   ├── apache.yml                     # Apache-only playbook
│   └── packages.yml                   # Packages-only playbook
└── roles/
    ├── apache/                        # Apache HTTP server role
    │   ├── tasks/
    │   ├── handlers/
    │   ├── templates/
    │   ├── defaults/
    │   ├── vars/ (OS-specific)
    │   └── meta/
    └── packages/                      # System packages role
        ├── tasks/
        ├── defaults/
        ├── vars/ (OS-specific)
        └── meta/
```

## Roles

### apache
Installs and configures Apache HTTP server. Supports both RedHat (`httpd`) and Debian (`apache2`) families via OS-specific vars.

| Variable | Default | Description |
|----------|---------|-------------|
| `apache_listen_port` | `80` | HTTP port |
| `apache_servername` | `inventory_hostname` | Server name |
| `apache_document_root` | `/var/www/html` | Web root |
| `apache_modules_enabled` | `[rewrite, ssl, headers]` | Modules to enable |

### packages
Manages system packages (install, remove, upgrade).

| Variable | Default | Description |
|----------|---------|-------------|
| `base_packages` | `[vim, htop, curl, ...]` | Base packages |
| `extra_packages` | `[]` | Extra packages |
| `install_dev_packages` | `false` | Install dev tools |
| `remove_packages` | `[]` | Packages to remove |
| `upgrade_system` | `false` | Upgrade all packages |

## Usage

### With Vagrant VMs

```bash
# Start VMs
VM_COUNT=2 vagrant up --provider=libvirt

# Generate SSH config
./scripts/generate-ssh-config.sh 2

# Test ping
ansible all -m ping

# Run full Vagrant playbook
ansible-playbook playbooks/vagrant.yml

# Or use the dynamic inventory script
ansible -i scripts/vagrant-inventory.sh -m ping
ansible-playbook -i scripts/vagrant-inventory.sh playbooks/vagrant.yml
```

### With staging/production

```bash
# Override inventory on the command line
ansible all -i inventory/staging/hosts.yml -m ping
ansible-playbook -i inventory/production/hosts.yml playbooks/site.yml
```

## VM Specs

- **Control node**: Your Linux host (Ansible runs natively)
- **Target VMs**: 2 GB RAM, 1 CPU each (configurable in Vagrantfile)
- **OS**: Debian Bookworm
- **Network**: Private DHCP (libvirt)

## Workflow

1. Edit roles in `roles/` to define automation
2. Edit vars in `inventory/<env>/group_vars/` to set environment-specific values
3. Run playbooks with `ansible-playbook playbooks/<playbook>.yml`
4. Use `--check` for dry-run, `--diff` to see changes, `-vvv` for verbose output
