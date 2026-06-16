# Overview

## What Is AppArmor?

AppArmor (Application Armor) is a **Mandatory Access Control (MAC)** system for Linux. It restricts what files, capabilities, and network resources individual programs can access.

Unlike traditional Unix permissions (DAC — Discretionary Access Control) where the file owner decides who accesses a file, MAC is enforced by the system regardless of what the user or program wants.

## Path-Based vs Label-Based

AppArmor uses **path-based** confinement: rules are written in terms of file paths (`/etc/shadow r`), not security labels. This is the key difference from SELinux, which uses **label-based** confinement (files and processes both get a security context label).

| Aspect | AppArmor | SELinux |
|--------|----------|---------|
| Approach | Path-based | Label-based |
| Rules | File paths in profiles | Security context matching |
| Complexity | Simpler to learn | More complex, more granular |
| Overhead | No relabeling needed | Requires correct file labels |
| Profile/policy location | `/etc/apparmor.d/` | Various policy modules |
| Good for | Single-purpose apps on servers | Multi-purpose systems, MLS |

## What AppArmor Controls

- **File access** — read, write, execute, append, link, lock, mmap
- **Capabilities** — Linux capabilities (CAP_NET_BIND_SERVICE, etc.)
- **Network access** — socket types, addresses, ports
- **mount, pivot_root, ptrace, signal, unix domain sockets, dbus, and more**

## Architecture

AppArmor loads **profiles** (per-program rules) into the kernel. When a profiled program runs, AppArmor checks every operation against its profile. Operations not explicitly allowed are denied and logged.

Profiles can be in one of two modes:
- **Enforce** — denials are blocked
- **Complain (audit)** — denials are logged but allowed

## Use Cases

- Confine web servers (nginx, Apache) to only access web files
- Restrict DNS servers to only network operations needed
- Sandbox untrusted applications
- Add a security layer on top of traditional file permissions

## When AppArmor Shines

- You want **path-based** confinement without labels
- You need to quickly generate profiles with `aa-genprof`
- The application is well-defined (single-purpose daemon)
- You prefer simpler syntax over SELinux's complexity
