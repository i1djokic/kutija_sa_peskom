# SELinux Modes

SELinux has three modes. Use them to control enforcement.

## The Three Modes

| Mode | Behavior |
|------|----------|
| **Enforcing** | SELinux policy is enforced. Denials are logged and blocked. |
| **Permissive** | Denials are logged but **not** blocked. Use for troubleshooting. |
| **Disabled** | SELinux is completely turned off. No logging, no enforcement. |

## Check Current Mode

```bash
getenforce
# Output: Enforcing
#         Permissive
#         Disabled

# More detail
sestatus
# SELinux status:                 enabled
# Current mode:                   enforcing
# Mode from config file:          enforcing
# Policy version:                 31
```

## Switch Mode at Runtime

```bash
# Temporarily disable enforcement (until reboot)
sudo setenforce 0

# Re-enable enforcement
sudo setenforce 1
```

`setenforce` only switches between Enforcing (1) and Permissive (0). It cannot enable SELinux if it was disabled at boot — once disabled, the SELinux kernel subsystem is not loaded at all, so no amount of `setenforce` will turn it on; a reboot with `SELINUX=enforcing` in the config is required.

## Switch Mode Permanently

Edit `/etc/selinux/config`:

```ini
# This file controls the state of SELinux on the system.
# enforcing  - SELinux security policy is enforced.
# permissive - SELinux prints warnings instead of enforcing.
# disabled   - No SELinux policy is loaded.
SELINUX=enforcing
```

Change `SELINUX=` to `permissive` or `disabled`, then reboot.

**What is relabeling?** When switching from Disabled to Enforcing, every file needs to get the correct SELinux context assigned. This is called **relabeling** — it scans all files and applies the contexts defined in the policy. Without it, files would have no label and the system might not boot correctly.

**Important:** Switching from Disabled to Enforcing requires a reboot and a relabel:

```bash
# After setting SELINUX=enforcing, the first reboot will relabel automatically
# Or force relabel on next boot:
sudo touch /.autorelabel
sudo reboot
```

## Mode Transition Rules

```
Disabled ──reboot──> Enforcing  (filesystem relabel required)
Disabled ──reboot──> Permissive (no relabel needed)
Permissive ──setenforce 1──> Enforcing
Enforcing  ──setenforce 0──> Permissive
```

## How to Troubleshoot With Modes

1. Application is failing
2. Check if SELinux is blocking: `sudo ausearch -m avc -ts recent`
   (If auditd is not running, see [05-troubleshooting.md](./05-troubleshooting.md) for alternatives)
3. Temporarily set to Permissive: `sudo setenforce 0`
4. If the application now works, SELinux is the cause
5. Fix the issue (context, boolean, or custom policy)
6. Re-enforce: `sudo setenforce 1`
