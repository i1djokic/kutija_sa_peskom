# Reference

## Quick Commands

| Command | What it does |
|---------|-------------|
| `sudo aa-status` | List all profiles and their modes |
| `sudo aa-enforce /path/to/bin` | Switch profile to enforce mode |
| `sudo aa-complain /path/to/bin` | Switch profile to complain mode |
| `sudo aa-disable /path/to/bin` | Unload profile |
| `sudo aa-genprof /path/to/bin` | Interactive profile generation |
| `sudo aa-logprof` | Process denials from logs into profile |
| `sudo aa-autodep /path/to/bin` | Generate stub profile |
| `sudo aa-notify -p` | Show recent denials |
| `sudo aa-unconfined` | Show processes without profiles |
| `sudo aa-mergeprof base new` | Merge two profiles |
| `aa-enabled` | Check if AppArmor is loaded |
| `sudo apparmor_parser -r /etc/apparmor.d/prof` | Load/reload a profile |
| `sudo apparmor_parser -R /etc/apparmor.d/prof` | Unload a profile |
| `sudo apparmor_parser -N /etc/apparmor.d/prof` | Check syntax (no load) |
| `sudo systemctl reload apparmor` | Reload all profiles |

## File Permissions

| Permission | Meaning |
|------------|---------|
| `r` | Read |
| `w` | Write |
| `a` | Append |
| `k` | Lock |
| `l` | Link |
| `ix` | Execute — inherit profile |
| `px` | Execute — transition to specific profile |
| `Px` | Execute — transition, scrub env |
| `cx` | Execute child — transition to subprofile |
| `Cx` | Execute child — scrub env |
| `ux` | Execute unconfined (dangerous) |
| `Ux` | Execute unconfined, scrub env (dangerous) |
| `m` | Memory map executable |

## Capabilities

Common capability rules:

| Rule | Allows |
|------|--------|
| `capability net_bind_service,` | Binding to privileged ports (<1024) |
| `capability setuid,` | Changing user ID |
| `capability setgid,` | Changing group ID |
| `capability chown,` | Changing file ownership |
| `capability dac_override,` | Bypassing file permission checks |
| `capability sys_admin,` | Various admin operations |
| `capability sys_ptrace,` | Debugging / tracing processes |
| `capability sys_resource,` | Resource limit overrides |
| `capability kill,` | Sending signals |

## Network Rules

```
network inet stream,         # TCP IPv4
network inet dgram,          # UDP IPv4
network inet6 stream,        # TCP IPv6
network inet6 dgram,         # UDP IPv6
network unix stream,         # Unix domain socket (stream)
network unix dgram,          # Unix domain socket (datagram)
network netlink raw,         # Netlink sockets
```

## Path Patterns

| Pattern | Matches |
|---------|---------|
| `/path/to/file` | Exact file |
| `/path/to/dir/` | The directory entry itself |
| `/path/to/dir/*` | Files directly in dir (non-recursive) |
| `/path/to/dir/**` | Files recursively in dir |
| `/path/*/log` | Single-level wildcard |

## Important Paths

| Path | Purpose |
|------|---------|
| `/etc/apparmor.d/` | Profile files |
| `/etc/apparmor.d/abstractions/` | Shared rule sets |
| `/etc/apparmor.d/tunables/` | Variable definitions |
| `/etc/apparmor.d/disable/` | Disabled profiles (symlinks) |
| `/var/log/audit/audit.log` | Audit log (if auditd is running) |
| `/var/log/syslog` | System log (Debian/Ubuntu) |
| `/var/log/kern.log` | Kernel log (Debian/Ubuntu) |

## Common Abstractions

```
#include <abstractions/base>
#include <abstractions/nameservice>
#include <abstractions/openssl>
#include <abstractions/python>
#include <abstractions/php>
#include <abstractions/mysql>
#include <abstractions/X>
#include <abstractions/dbus>
#include <abstractions/audio>
#include <abstractions/freedesktop.org>
```

## SELinux-to-AppArmor Mapping

| SELinux concept | AppArmor equivalent |
|-----------------|---------------------|
| Enforcing mode | Enforce mode |
| Permissive mode | Complain mode |
| Policy module | Profile file |
| File context / label | File path + permission in profile |
| Type enforcement (TE) | File access rules |
| Boolean | No direct equivalent |
| Domain transition | `px` execute rule |
| `restorecon` | No equivalent (not needed) |
| `semanage fcontext` | No equivalent (path-based) |
| `ausearch -m avc` | `ausearch -m apparmor` |
| `audit2allow` | `aa-logprof` |
| `sealert` | `aa-notify` |
| `chcon` | No equivalent |
| MLS / MCS | `profile name flags=(complain)` + hats |
