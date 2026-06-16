# AppArmor Guide

Complete documentation for AppArmor (Application Armor) — a path-based Mandatory Access Control system. Similar to SELinux but simpler: profiles use file paths instead of security labels.

## Contents

| File | What it covers |
|------|----------------|
| [01-overview.md](./01-overview.md) | What is AppArmor, path-based vs label-based (SELinux comparison), architecture |
| [02-modes.md](./02-modes.md) | Enforce, Complain, Disabled; switching at runtime and boot |
| [03-profiles.md](./03-profiles.md) | Profile structure, file naming, hats (subprofiles), includes, abstractions |
| [04-profile-rules.md](./04-profile-rules.md) | File access rules, capabilities, network, path patterns, deny, owner, audit |
| [05-tools.md](./05-tools.md) | aa-status, aa-enforce, aa-complain, aa-genprof, aa-logprof, and more |
| [06-generating-profiles.md](./06-generating-profiles.md) | Interactive profile generation walkthrough with aa-genprof |
| [07-troubleshooting.md](./07-troubleshooting.md) | Reading denials, aa-logprof, aa-notify, common fixes, debug workflow |
| [08-custom-profiles.md](./08-custom-profiles.md) | Writing profiles by hand, variables, abstractions, hats, best practices |
| [09-practical-examples.md](./09-practical-examples.md) | Nginx, Python app, MySQL, custom daemon, SSH, Apache hats |
| [10-reference.md](./10-reference.md) | Command cheat sheet, rule syntax quick reference, SELinux mapping |
| [11-selinux-vs-apparmor.md](./11-selinux-vs-apparmor.md) | AppArmor vs SELinux — pros, cons, when to use each, recommendations |

## Quick Start

```bash
# Check if AppArmor is active
aa-enabled

# List loaded profiles and their modes
sudo aa-status

# Switch a profile to complain mode (audit without blocking)
sudo aa-complain /usr/sbin/nginx

# Generate a profile interactively
sudo aa-genprof /usr/sbin/myapp

# Reload all profiles after edits
sudo systemctl reload apparmor
```

## Package Installation

```bash
# Fedora/RHEL
sudo dnf install apparmor-utils apparmor-profiles

# Debian/Ubuntu (AppArmor is usually enabled by default)
sudo apt install apparmor-utils apparmor-profiles
```

## Resources

- [AppArmor Wiki](https://wiki.apparmor.net/)
- [Ubuntu AppArmor Documentation](https://ubuntu.com/server/docs/security-apparmor)
- [Debian AppArmor Wiki](https://wiki.debian.org/AppArmor)
