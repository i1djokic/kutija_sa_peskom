# SELinux vs AppArmor

Both SELinux and AppArmor are Linux Mandatory Access Control (MAC) systems. They serve the same purpose — confining programs beyond traditional Unix permissions — but take fundamentally different approaches.

## Core Philosophy

| Aspect | SELinux | AppArmor |
|--------|---------|----------|
| Approach | **Label-based** — every file, process, socket, pipe gets a security context label; rules match labels to labels | **Path-based** — rules are written as file paths; no labels on files |
| Policy scope | **System-wide** — a single policy defines rules for everything | **Per-profile** — each program has its own profile file; unrelated programs don't affect each other |
| Default stance | **Everything denied unless explicitly allowed** (even root) | **Unconfined unless a profile exists** — no profile means no restrictions |
| Who maintains | Distributions ship reference policy; administrators can write custom modules | Profiles are per-app, maintained by distro or written by admin |

## Granularity

SELinux is more granular. Consider a web server reading `/etc/shadow`:

- **SELinux**: The web server process runs as `httpd_t`. The file `/etc/shadow` has context `shadow_t`. The policy says `httpd_t` cannot read `shadow_t`. This works regardless of where the file is physically located.
- **AppArmor**: The nginx profile lists paths. You write `deny /etc/shadow r,` in the nginx profile. If someone moves shadow to a different path, the rule needs updating.

SELinux reasons about **types** (abstract labels). AppArmor reasons about **paths** (physical locations).

| Situation | SELinux advantage | AppArmor advantage |
|-----------|------------------|-------------------|
| Same file, different location | Label follows the file (`mv` keeps the label) | Path changes, rule must be updated |
| Same location, different file types | Contexts differentiate files at the same path | Must use path patterns or different rules |
| Custom application in a standard path (`/opt`) | Needs new type definition + file context rule | Just add the path to a profile |
| Untrusted user uploads | File context can be checked regardless of path | Path-based rules still apply |

## Pros and Cons

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

## When to Use Each

### Choose SELinux When

- You run **RHEL, CentOS, Fedora, or Rocky Linux** (AppArmor is not available without custom kernels)
- You need **Multi-Level Security (MLS)** for classified environments
- You need **system-wide default-deny** (no unconfined processes)
- You have a team that can invest in learning the label-based model
- Your environment is **static** (well-known applications, standard paths)
- You need **fine-grained control** over individual capabilities

### Choose AppArmor When

- You run **Debian, Ubuntu, or SUSE/openSUSE** (SELinux is available but not the default)
- You want to **get started quickly** with interactive profile generation
- Your team is **small** or lacks dedicated security engineering time
- You have **custom or in-house applications** that need confinement
- Your environment has **frequent path changes** (containers, dynamic storage)
- You want to confine **specific applications** without touching the rest of the system

## Recommendations

### For Most Server Workloads

**Use the MAC system your distribution defaults to:**

| Distribution | Default MAC | Recommendation |
|-------------|-------------|----------------|
| RHEL / CentOS / Fedora | SELinux | Use SELinux — it's tested, supported, and integrated |
| Debian / Ubuntu | AppArmor | Use AppArmor — it's the default, easier, and well integrated |
| SUSE / openSUSE | AppArmor | Use AppArmor — it's the default, mature on SUSE |
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

| Feature | SELinux | AppArmor |
|---------|---------|----------|
| Approach | Label-based (security contexts) | Path-based (file paths) |
| Default deny | Yes (system-wide) | No (per-profile only) |
| MLS support | Yes (built-in) | No |
| RBAC support | Yes | No |
| Profile granularity | Per-type (many processes share a type) | Per-executable path |
| File label management | Required (`restorecon`, `semanage fcontext`) | Not needed |
| Relabel on enable | Required | Not needed |
| Interactive profile gen | No (`audit2allow` post-processes logs) | Yes (`aa-genprof` walks through denials) |
| Learning curve | Steep | Moderate |
| Best distro fit | RHEL/Fedora/CentOS | Debian/Ubuntu/SUSE |
| Default deny for root | Yes | Only if a profile exists |
| Denial log source | `ausearch -m avc` | `ausearch -m apparmor` or `journalctl -k` |
| Policy language | M4 macro + TE rules | Simple rule syntax |
