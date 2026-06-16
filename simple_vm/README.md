# Simple Linux VM for Learning

## What is this?

A simple, lightweight Linux virtual machine for learning Linux commands, bash scripting, and system administration on Linux.

Uses:
- **libvirt/KVM** - Open-source virtualizer for Linux
- **Vagrant** - VM management tool
- **Debian 12 (bookworm)** - Stable, beginner-friendly Linux distribution

**Total cost: $0** - Everything is free and open-source!

## Prerequisites

- Linux with KVM-capable CPU (most modern CPUs)
- libvirt and Vagrant installed
- Internet connection

## Quick Setup

### Option 1: Automated Setup (Recommended)

```bash
cd simplevm
chmod +x setup-linux.sh
./setup-linux.sh
```

### Option 2: Manual Setup

```bash
# Install libvirt/KVM (Debian/Ubuntu)
sudo apt install -y libvirt-daemon-system libvirt-clients qemu-kvm virt-manager vagrant vagrant-libvirt

# Start libvirtd
sudo systemctl enable --now libvirtd

# Add user to groups
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```

## Starting the VM

```bash
# Start the VM (first boot downloads the image, ~5 minutes)
vagrant up --provider=libvirt

# Connect to the VM via SSH
vagrant ssh

# When done, you can:
vagrant halt    # Stop the VM
vagrant reload  # Restart the VM
vagrant destroy # Delete the VM (warning: all data lost)
```

## Learning Linux

Once connected to the VM (`vagrant ssh`), you can start learning:

### Basic Commands
```bash
# System information
uname -a
cat /etc/os-release

# File operations
ls -la
cd /tmp
mkdir test
cd test
touch file1.txt
nano file1.txt  # Edit file

# File permissions
chmod +x script.sh
ls -l

# Process management
ps aux
top
htop  # if installed

# Package management (Debian/Ubuntu)
sudo apt update
sudo apt install htop
```

### Practice Areas
- **File system navigation** - `cd`, `ls`, `pwd`, `mkdir`, `rm`
- **Text editing** - `nano`, `vim` (vim pre-installed)
- **File permissions** - `chmod`, `chown`
- **User management** - `sudo`, `su`, `useradd`
- **Process management** - `ps`, `top`, `kill`
- **Networking** - `ip`, `ping`, `curl`, `netstat`
- **Package management** - `apt` (Debian/Ubuntu)
- **Bash scripting** - Create and run `.sh` files

## VM Specifications

- **OS**: Debian 12 (bookworm)
- **RAM**: 2GB
- **CPU**: 1 core
- **Disk**: 20GB (dynamic)
- **Access**: SSH via `vagrant ssh`
- **User**: `vagrant` (password: `vagrant`, has sudo access)

## Vagrant Commands

```bash
# Start VM
vagrant up --provider=libvirt

# Stop VM
vagrant halt

# Restart VM
vagrant reload

# Delete VM (warning: irreversible)
vagrant destroy -f

# Check status
vagrant status

# SSH into VM
vagrant ssh

# Re-provision (re-run setup script)
vagrant provision
```

## Troubleshooting

### Issue: VMs won't start

```bash
# Check libvirt is running
sudo systemctl status libvirtd

# Check plugin
vagrant plugin list | grep libvirt

# Check user is in libvirt group
groups $USER
```

### Issue: Can't SSH into VM

```bash
# Wait a few minutes after `vagrant up`
# Check VM is running
vagrant status

# Try SSH manually
vagrant ssh -- -vvv
```

### Issue: Installation fails

```bash
# Check internet connection
# Reinstall plugin
vagrant plugin uninstall vagrant-libvirt
vagrant plugin install vagrant-libvirt
```

## Project Structure

```
simplevm/
├── README.md           # This file
├── setup-linux.sh      # Automated setup script
└── Vagrantfile         # VM configuration
```

## Resources for Learning

- **Linux Journey**: https://linuxjourney.com/
- **Debian Documentation**: https://www.debian.org/doc/
- **Vim Tutorial**: https://www.openvim.com/
- **Bash Scripting**: https://www.gnu.org/software/bash/manual/

## License

Free to use and modify.

## Contributing

Suggestions welcome! Open an issue or submit a pull request.
