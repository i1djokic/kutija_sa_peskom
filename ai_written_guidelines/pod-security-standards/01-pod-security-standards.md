# Pod Security Standards

> **Source:** [Kubernetes Documentation — Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## What Are Pod Security Standards?

Pod Security Standards (PSS) are **pre-defined security policies** in Kubernetes that control what a Pod is allowed to do. Think of them as a set of rules that answer questions like:

- Can this Pod run as the root user?
- Can this Pod access the host machine's network?
- Can this Pod add extra Linux capabilities?
- Can this Pod use certain types of storage volumes?

Instead of every team inventing their own security rules from scratch, Kubernetes provides three standard policies that cover the most common security needs. You pick the one that fits your workload.

---

## Why Do We Need This?

Containers share the host machine's kernel. Without restrictions, a malicious or compromised container could:

- **Escape** the container and access the host
- **Read** other containers' data
- **Disable** security mechanisms
- **Consume** host resources unfairly

Pod Security Standards give you a simple, built-in way to prevent these scenarios without needing third-party tools.

---

## The Three Profiles (From Least to Most Secure)

| Profile | Security Level | Best For |
|---|---|---|
| **Privileged** | None — fully open | System infrastructure, monitoring agents, network plugins |
| **Baseline** | Low — prevents known exploits | Most regular applications |
| **Restricted** | High — follows hardening best practices | Security-critical or untrusted workloads |

**Important:** These policies are **cumulative**. Restricted includes everything Baseline does, plus more restrictions. Baseline includes everything Privileged does (which is nothing — Privileged has no restrictions).

---

## Profile Details

---

### Privileged

**What it is:** The "no rules" policy. A Pod running under Privileged can do almost anything a container could possibly do.

**When to use it:**
- Cluster infrastructure components (network plugins, monitoring agents, storage drivers)
- Tools that need direct hardware access
- Workloads managed by trusted administrators

**What it allows:**
- Running as root
- Access to the host network, PID namespace, and IPC namespace
- All Linux capabilities
- HostPath volumes (direct access to files on the host machine)
- Any seccomp or AppArmor profile (or none at all)
- Privileged mode (bypasses almost all container isolation)

**Example scenario:** Your cluster uses Calico for networking. Calico's components need to modify iptables rules on the host and access host network interfaces — things that would be blocked by Baseline or Restricted. So Calico runs under the Privileged policy.

> **Why this exists:** Some workloads fundamentally need host access. Without a Privileged profile, you'd have no way to run these workloads at all.

---

### Baseline

**What it is:** A "reasonable defaults" policy. It blocks the most dangerous things while still allowing most normal applications to run without changes.

**When to use it:**
- Regular web applications, APIs, and services
- CI/CD pipelines
- Development and staging environments
- When you want better security but can't modify every Pod spec

**What it prevents (and what each restriction means):**

| Control | What It Blocks | Why It Matters |
|---|---|---|
| **HostProcess** | Windows containers that run as host processes | HostProcess containers have full access to the Windows host |
| **Host Namespaces** | Pods sharing the host's network, PID, or IPC namespaces | A container on the host network can snoop on all host traffic; a container sharing host PID can see all processes |
| **Privileged Containers** | Containers running in privileged mode | Privileged mode disables almost all container isolation |
| **Capabilities** | Dangerous Linux capabilities beyond a safe list | Capabilities like `SYS_ADMIN` or `NET_ADMIN` could let a container modify the host kernel or network |
| **HostPath Volumes** | Volumes that mount host filesystem paths | A container with a HostPath volume can read/write any file on the host |
| **Host Ports** | Containers binding to host ports | Host ports bypass Kubernetes networking and can conflict with other workloads |
| **Host Probes / Lifecycle Hooks** | Probes and lifecycle hooks targeting arbitrary hosts | Could be used to probe internal network services |
| **AppArmor** | Disabling or using custom AppArmor profiles | AppArmor restricts what system calls a container can make |
| **SELinux** | Setting custom SELinux user/role or unapproved types | SELinux Mandatory Access Control prevents containers from accessing each other's files |
| **`/proc` Mount Type** | Exposing the full `/proc` filesystem | `/proc` contains kernel data — too much exposure aids attackers |
| **Seccomp** | Setting seccomp to `Unconfined` | Seccomp filters system calls; `Unconfined` means any syscall is allowed |
| **Sysctls** | Unsafe kernel parameter changes | Sysctls can disable security mechanisms (e.g., `net.ipv4.ip_forward`) or affect all containers on a host |

**The allowed Linux capabilities under Baseline:**
```
AUDIT_WRITE     — write to kernel audit log
CHOWN           — change file ownership
DAC_OVERRIDE    — bypass file permission checks
FOWNER          — bypass ownership checks on file operations
FSETID          — don't clear setuid/setgid bits on mode changes
KILL            — send signals to processes
MKNOD           — create device nodes
NET_BIND_SERVICE — bind to privileged ports (< 1024)
SETFCAP         — set file capabilities
SETGID          — change group identity
SETPCAP         — set process capabilities
SETUID          — change user identity
SYS_CHROOT      — call chroot()
```

> **Real-world analogy:** Baseline is like locking your front door and closing the windows, but not installing a security system. It stops opportunists but won't stop a determined attacker.

---

### Restricted

**What it is:** The "hardened" policy. It applies everything Baseline does, plus additional strict controls. Some Pods may need configuration changes to comply.

**When to use it:**
- Production financial systems handling payments
- Healthcare applications with patient data
- Multi-tenant environments where you don't trust the users
- Any workload that processes sensitive data
- Compliance requirements (PCI-DSS, HIPAA, SOC 2)

**Additional controls on top of Baseline:**

| Control | What It Requires | Why It Matters |
|---|---|---|
| **Volume Types** | Only specific volume types allowed (see below) | Volumes like `hostPath` are already blocked by Baseline; this also restricts other potentially dangerous volume types |
| **Privilege Escalation** | `allowPrivilegeEscalation` must be `false` | Prevents a process from gaining more privileges than its parent (e.g., via setuid binaries) |
| **Non-root User** | `runAsNonRoot` must be `true` | Running as root inside a container is risky — if the container is compromised, the attacker has root |
| **Non-root User ID** | `runAsUser` must not be `0` | Even if `runAsNonRoot` is true, you could still set the user to 0 (root); this blocks that loophole |
| **Seccomp** | Must explicitly set to `RuntimeDefault` or `Localhost` | Baseline only blocks `Unconfined`; Restricted requires an actual seccomp profile |
| **Capabilities** | Must drop `ALL`; only `NET_BIND_SERVICE` may be added back | Baseline blocks dangerous capabilities; Restricted goes further and requires you to explicitly drop everything first |

**Allowed volume types under Restricted:**
- `configMap` — inject configuration data
- `csi` — Container Storage Interface volumes
- `downwardAPI` — expose Pod metadata
- `emptyDir` — temporary storage scoped to the Pod's lifetime
- `ephemeral` — inline ephemeral volumes
- `persistentVolumeClaim` — persistent storage
- `projected` — combine multiple volume sources
- `secret` — inject sensitive data

**Linux-only controls (v1.25+):** Privilege Escalation, Seccomp, and Capabilities restrictions apply only on Linux nodes. Windows containers have different security models and these controls do not apply.

> **Real-world analogy:** Restricted is like a locked front door, security cameras, a guard dog, bulletproof windows, and a security system. It's much harder to break in, but it also means you can't just walk in casually — you need proper authorization (i.e., your Pod needs the right security context settings).

---

## How Pod Security Standards Are Enforced

### The Pod Security Admission Controller

The built-in enforcement mechanism is the **Pod Security Admission** controller. It works by **labeling namespaces** with the desired security level:

```yaml
# Enforce Baseline — block Pods that don't comply
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
  labels:
    pod-security.kubernetes.io/enforce: baseline
```

There are three modes:

| Mode | Label Suffix | Behavior |
|---|---|---|
| **enforce** | `pod-security.kubernetes.io/enforce` | Blocks Pod creation if it violates the policy |
| **audit** | `pod-security.kubernetes.io/audit` | Allows the Pod but logs the violation |
| **warn** | `pod-security.kubernetes.io/warn` | Allows the Pod but shows a warning to the user |

You can also **pin a version** to ensure consistent behavior:
```yaml
pod-security.kubernetes.io/enforce-version: v1.30
```

### Enforcement flow:
1. You label a namespace (e.g., `enforce: restricted`)
2. Someone tries to create a Pod in that namespace
3. The Pod Security Admission controller checks the Pod against the policy
4. If the Pod violates the policy in `enforce` mode, it's rejected
5. If it passes, the Pod is created normally

### Example: Enforcing Baseline on a namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: v1.36
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```
This enforces Baseline but also **audits and warns** about Restricted violations — a great way to gradually tighten security.

### Third-party alternatives:

If you need more fine-grained control than the three built-in profiles:
- **[Kyverno](https://kyverno.io/policies/pod-security/)** — Kubernetes-native policy engine with Pod Security Standard policies built in
- **[OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper)** — General-purpose policy engine using Rego
- **[Kubewarden](https://github.com/kubewarden)** — WebAssembly-based policy engine

---

## Understanding the Key Security Concepts

If you're new to Kubernetes security, here's what each security mechanism actually does:

| Concept | What It Does | Why Block It? |
|---|---|---|
| **Privileged mode** | Gives the container nearly all capabilities and access to host devices | An attacker with privileged access can escape the container |
| **Linux Capabilities** | Fine-grained permissions (e.g., `NET_BIND_SERVICE`, `SYS_ADMIN`) | Too many capabilities = privilege escalation risk |
| **Seccomp** | Filters which system calls a process can make | Limits what an attacker can do even if they compromise the container |
| **AppArmor** | MAC (Mandatory Access Control) for programs | Restricts file access, network access, and capabilities per program |
| **SELinux** | MAC labels for processes, files, and ports | Prevents containers from accessing each other's resources |
| **Host Namespaces** | Sharing the host's network, PID, or IPC | Breaks isolation between the container and the host |
| **HostPath Volumes** | Mounting host directories into the container | Direct filesystem access to the host |
| **Privilege Escalation** | Allowing a process to gain more privileges (e.g., via setuid) | The core of many container escape exploits |
| **Sysctls** | Kernel parameters (e.g., `net.ipv4.ip_forward`) | Can disable security mechanisms globally |

---

## How to Choose the Right Profile

Ask yourself these questions:

1. **Does this workload need direct host access?** (e.g., network plugin, monitoring agent)
   - **Yes** → Privileged
   - **No** → Continue

2. **Can I modify this workload's Pod spec to comply with restrictions?** (e.g., set `runAsNonRoot: true`, drop capabilities)
   - **No** → Baseline
   - **Yes** → Continue

3. **Does this workload handle sensitive data or run untrusted code?**
   - **Yes** → Restricted
   - **No** → Baseline

**General recommendation:** Start with Baseline for most namespaces and use Restricted for production/high-value workloads. Use Privileged only when absolutely necessary.

---

## Pod OS Field (Linux vs Windows)

Since v1.25, the Restricted policy checks `pod.spec.os.name`:

- If `.spec.os.name` is `linux` (or unset), all controls apply
- If `.spec.os.name` is `windows`, the following controls are **relaxed** because they don't apply on Windows:
  - Privilege Escalation (`allowPrivilegeEscalation`)
  - Seccomp profile requirements
  - Linux Capabilities (`drop: ["ALL"]`)

This allows Windows workloads to pass the Restricted policy without needing Linux-specific security contexts.

---

## User Namespaces

**What it is:** A Linux feature that maps a container's root user (UID 0) to a non-root user outside the container.

**Why it matters:** Even if you run as root inside the container, you're an unprivileged user on the host. This significantly reduces the impact of a container escape.

**How it relates to PSS:** When user namespaces are enabled, some Restricted policy controls can be relaxed. For example, a container can run as UID 0 inside its namespace because it's mapped to a non-root UID on the host.

---

## FAQ

### What's the difference between a security profile and a security context?

**Security Context** (`securityContext` in the Pod spec) is configured per-Pod or per-Container — it's what the **workload author** sets. For example:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    securityContext:
      capabilities:
        drop: ["ALL"]
```

**Security Profile** (Privileged / Baseline / Restricted) is a **cluster-wide policy** enforced by the control plane. It checks that the Pod's Security Context meets the required standards.

In short: Security Context = what you ask for. Security Profile = what the cluster checks.

### Why isn't there a profile between Privileged and Baseline?

The gap between Privileged and Baseline is intentionally left open because workloads that need more than Baseline but less than Privileged are usually **application-specific**. A database, a message queue, and a CI runner would each need different specific permissions. Rather than guessing, Kubernetes leaves this space for custom policies via third-party tools like Kyverno or OPA Gatekeeper.

### What about sandboxed Pods? (gVisor, Kata Containers)

Sandboxed runtimes provide an extra layer of isolation (a lightweight VM or userspace kernel). There's no standard API to identify a Pod as "sandboxed," so PSS doesn't have a separate profile for them. In practice, sandboxed workloads can often use Baseline or Restricted because the sandbox adds defense-in-depth, but this depends on the specific runtime and workload.

---

## Practical Tips

- **Start with `warn` and `audit` modes** before switching to `enforce` to see what breaks
- **Use version pins** (`enforce-version: v1.36`) to ensure consistent behavior across cluster upgrades
- **Combine with Network Policies** for defense-in-depth — PSS controls what a Pod can do; Network Policies control what it can talk to
- **Check logs** for audit violations regularly — they tell you which Pods would fail if you tightened the policy
- **Test locally** with tools like `kubectl dry-run` or Kyverno's CLI before rolling out enforcement

---

## Quick Reference: Controls by Profile

| Control | Privileged | Baseline | Restricted |
|---|---|---|---|
| Host namespaces | Allowed | Blocked | Blocked |
| Privileged containers | Allowed | Blocked | Blocked |
| HostPath volumes | Allowed | Blocked | Blocked |
| Capabilities | Any | Safe list only | Must drop ALL |
| Seccomp | Any | Not Unconfined | Must be set |
| Non-root user | Optional | Optional | Required |
| Privilege Escalation | Allowed | Allowed | Blocked |
| Volume types | Any | Any | Restricted list |
| AppArmor | Any | RuntimeDefault/Localhost | RuntimeDefault/Localhost |
| SELinux | Any | Restricted types | Restricted types |

---

> **Reference:** [Kubernetes Documentation — Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
