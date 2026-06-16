# SELinux Guide

Complete documentation for SELinux (Security-Enhanced Linux) — understanding modes, contexts, booleans, troubleshooting denials, and writing policies.

## Contents

| File | What it covers |
|------|----------------|
| [01-overview.md](./01-overview.md) | What is SELinux, MAC vs DAC, how access control works |
| [02-modes.md](./02-modes.md) | Enforcing, Permissive, Disabled, switching at runtime and boot |
| [03-contexts.md](./03-contexts.md) | Security contexts (user:role:type:level), viewing, changing, restoring |
| [04-booleans.md](./04-booleans.md) | Toggling features on/off without writing policy |
| [05-troubleshooting.md](./05-troubleshooting.md) | AVC denials, audit log, ausearch, audit2why, sealert |
| [06-practical-examples.md](./06-practical-examples.md) | Fixing common denials — httpd, SSH, custom ports, file access |
| [07-custom-policies.md](./07-custom-policies.md) | audit2allow, compiling modules, semodule |
| [08-reference.md](./08-reference.md) | Command cheat sheet and quick reference |
| [09-selinux-vs-apparmor.md](./09-selinux-vs-apparmor.md) | SELinux vs AppArmor — pros, cons, when to use each, recommendations |

## Quick Start

```bash
# Check current mode
getenforce

# Temporarily disable enforcement (for troubleshooting)
sudo setenforce 0

# View a file's SELinux context
ls -Z file.txt

# View a process context
ps auxZ | grep nginx

# Restore default contexts
sudo restorecon -Rv /var/www/

# Search audit log for denials
sudo ausearch -m avc -ts recent
```

## Package Installation

Commands in this guide use Fedora/RHEL (`dnf`) by default. For Debian/Ubuntu:

```bash
# Install SELinux utilities on Debian/Ubuntu
sudo apt install selinux-utils policycoreutils policycoreutils-python-utils

# Install setroubleshoot
sudo apt install setroubleshoot

# Install policy development tools
sudo apt install selinux-policy-dev checkpolicy

# Note: Debian/Ubuntu ships with SELinux disabled by default
# You may need to install selinux-basics and run selinux-activate
```

## Resources

- [Red Hat SELinux Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/)
- [SELinux Project Wiki](https://selinuxproject.org/)
- [Debian SELinux Wiki](https://wiki.debian.org/SELinux)
