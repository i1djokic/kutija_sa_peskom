# AppArmor vs SELinux

Both AppArmor and SELinux are Linux Mandatory Access Control (MAC) systems. They serve the same purpose — confining programs beyond traditional Unix permissions — but take fundamentally different approaches.

## Core Philosophy

| Aspect | AppArmor | SELinux |
|--------|----------|---------|
| Approach | **Path-based** — rules are written as file paths; no labels on files | **Label-based** — every file, process, socket, pipe gets a security context label; rules match labels to labels |
| Policy scope | **Per-profile** — each program has its own profile file; unrelated programs don't affect each other | **System-wide** — a single policy defines rules for everything |
| Default stance | **Unconfined unless a profile exists** — no profile means no restrictions | **Everything denied unless explicitly allowed** (even root) |
| Who maintains | Profiles are per-app, maintained by distro or written by admin | Distributions ship reference policy; administrators can write custom modules |

## Granularity

SELinux is more granular. Consider a web server reading `/etc/shadow`:

- **AppArmor**: The nginx profile lists paths. You write `deny /etc/shadow r,` in the nginx profile. If someone moves shadow to a different path, the rule needs updating.
- **SELinux**: The web server process runs as `httpd_t`. The file `/etc/shadow` has context `shadow_t`. The policy says `httpd_t` cannot read `shadow_t`. This works regardless of where the file is physically located.

AppArmor reasons about **paths** (physical locations). SELinux reasons about **types** (abstract labels).

| Situation | AppArmor advantage | SELinux advantage |
|-----------|-------------------|------------------|
| Same file, different location | — | Label follows the file (`mv` keeps the label) |
| Same location, different file types | Path-based rules still apply | Contexts differentiate files at the same path |
| Custom application in a standard path (`/opt`) | Just add the path to a profile | Needs new type definition + file context rule |
| Untrusted user uploads | — | File context can be checked regardless of path |

## Pros and Cons

### AppArmor Pros

- **Simplicity** — rules are file paths with permissions; no labels, no contexts, no relabeling
- **Easy to start** — `aa-genprof` interactively builds profiles from watching the application
- **Intuitive debugging** — denial says "myapp was denied reading /etc/shadow"; fix is adding `/etc/shadow r,` to the profile
- **No relabeling** — since it's path-based, there are no file labels to manage or restore
- **Per-profile** — you can confine nginx without affecting anything else; no system-wide policy changes
- **Lower overhead** — less complexity means less chance of configuration mistakes that break the system

### AppArmor Cons

- **Path dependency** — if an application reads files through symlinks, mount points, or bind mounts, the path in the denial may differ from the path in the profile
- **No system-wide default deny** — processes without a profile run unconfined; you can't enforce a "default deny" for all programs
- **No MLS** — AppArmor does not support multi-level security classifications
- **Coarser controls** — cannot express "process type A can read files of type B" as an abstract rule; every path must be explicitly listed
- **Profile maintenance** — application updates that change file locations require profile updates
- **Less popular on RHEL** — AppArmor is not supported on RHEL/CentOS (SELinux is the default); primarily used on Debian/Ubuntu and SUSE

### SELinux Pros

- **Label persistence** — a file keeps its security context when moved; rules don't break because a file was relocated
- **Type enforcement** — allows abstract policy like "processes of type A can read files of type B regardless of where either is"
- **Multi-Level Security (MLS)** — built-in support for classification levels (Confidential, Secret, Top Secret) required by some government/enterprise environments
- **Role-Based Access Control (RBAC)** — users can be restricted to specific roles with different SELinux permissions
- **Mature ecosystem** — long history in RHEL/CentOS/Fedora, extensive documentation, `setroubleshoot`, `audit2allow`, `semanage`
- **System-wide enforcement** — no process is unconfined unless explicitly allowed; root is also confined

### SELinux Cons

- **Complexity** — steep learning curve; contexts, types, booleans, policy modules, file context matching
- **Label management** — files need correct labels; `restorecon` and `semanage fcontext` are essential maintenance tasks
- **Relabeling cost** — switching from Disabled to Enforcing requires a filesystem relabel (can be slow on large systems)
- **Debugging overhead** — AVC denials require understanding contexts to interpret; `audit2allow` helps but still requires comprehension
- **Disabling is common** — many administrators default to disabling SELinux because it's easier than learning it

## When to Use Each

### Choose AppArmor When

- You run **Debian, Ubuntu, or SUSE/openSUSE** (SELinux is available but not the default)
- You want to **get started quickly** with interactive profile generation
- Your team is **small** or lacks dedicated security engineering time
- You have **custom or in-house applications** that need confinement
- Your environment has **frequent path changes** (containers, dynamic storage)
- You want to confine **specific applications** without touching the rest of the system

### Choose SELinux When

- You run **RHEL, CentOS, Fedora, or Rocky Linux** (AppArmor is not available without custom kernels)
- You need **Multi-Level Security (MLS)** for classified environments
- You need **system-wide default-deny** (no unconfined processes)
- You have a team that can invest in learning the label-based model
- Your environment is **static** (well-known applications, standard paths)
- You need **fine-grained control** over individual capabilities

## Recommendations

### For Most Server Workloads

**Use the MAC system your distribution defaults to:**

| Distribution | Default MAC | Recommendation |
|-------------|-------------|----------------|
| Debian / Ubuntu | AppArmor | Use AppArmor — it's the default, easier, and well integrated |
| SUSE / openSUSE | AppArmor | Use AppArmor — it's the default, mature on SUSE |
| RHEL / CentOS / Fedora | SELinux | Use SELinux — it's tested, supported, and integrated |
| Arch Linux | Neither | Choose based on what you're comfortable with; AppArmor has simpler setup |

Both systems are effective. The best one is the one you **actually use**. Running with MAC disabled is worse than running either system, no matter which one you pick.

### For Containers

- **Docker** supports both; AppArmor's per-profile model maps more naturally to per-container confinement
- **Kubernetes** uses neither for pod-level security (uses Pod Security Standards instead), but the node can run either

### For Learning

- Start with AppArmor if you want to understand MAC concepts quickly
- Move to SELinux if you need label-based features or work in RHEL environments
- The concepts transfer: complain/permissive mode for debugging, audit logs, allow/deny rules

## Quick Comparison Table

| Feature | AppArmor | SELinux |
|---------|----------|---------|
| Approach | Path-based (file paths) | Label-based (security contexts) |
| Default deny | No (per-profile only) | Yes (system-wide) |
| MLS support | No | Yes (built-in) |
| RBAC support | No | Yes |
| Profile granularity | Per-executable path | Per-type (many processes share a type) |
| File label management | Not needed | Required (`restorecon`, `semanage fcontext`) |
| Relabel on enable | Not needed | Required |
| Interactive profile gen | Yes (`aa-genprof` walks through denials) | No (`audit2allow` post-processes logs) |
| Learning curve | Moderate | Steep |
| Best distro fit | Debian/Ubuntu/SUSE | RHEL/Fedora/CentOS |
| Default deny for root | Only if a profile exists | Yes |
| Denial log source | `ausearch -m apparmor` or `journalctl -k` | `ausearch -m avc` |
| Policy language | Simple rule syntax | M4 macro + TE rules |
