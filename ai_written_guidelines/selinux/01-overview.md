# SELinux Overview

## What is SELinux?

SELinux (Security-Enhanced Linux) is a mandatory access control (MAC) system built into the Linux kernel. It enforces security policies that define what processes can access which files, ports, and other resources — even after traditional Linux permissions (DAC) have granted access.

## MAC vs DAC

| Access Control | How it works |
|----------------|-------------|
| **DAC** (Discretionary) | Standard Linux permissions: user/group/other, rwx bits. The file owner controls access. |
| **MAC** (Mandatory) | SELinux policies enforced system-wide. Even root can be restricted. |

SELinux checks permissions **after** DAC. Both must allow access for the operation to succeed.

```
Process tries to access file
        │
        ▼
   DAC check (rwx) ─── DENY → Access denied
        │
        │ ALLOW
        ▼
   SELinux check ─── DENY → Access denied (AVC denial)
        │
        │ ALLOW
        ▼
   Access granted
```

## How It Works

SELinux applies a **security context** to every process and every object (files, sockets, ports). A policy defines rules about which contexts can interact.

```
Subject (process)  ──>  Object (file/port)
     has context          has context
     httpd_t              httpd_sys_content_t
```

The policy says: `httpd_t` can read `httpd_sys_content_t`. Access is granted.

## Policy Types

| Type | Description |
|------|-------------|
| **Targeted** | Only selected processes are confined (default: most common) |
| **MLS** | Multi-Level Security — classified data levels (government/military) |
| **Minimum** | Minimal policy — very few processes confined |

The default on most distributions is **targeted**.

## Key Terms

| Term | Meaning |
|------|---------|
| **Subject** | A process (e.g., httpd, sshd) |
| **Object** | A file, port, socket, directory |
| **Context** | SELinux label: `user:role:type:level` |
| **Type** | The main part of the context used in targeted policy |
| **Domain** | The type of a process (e.g., `httpd_t`) |
| **AVC** | Access Vector Cache — SELinux access decision |
| **Boolean** | A policy toggle you can switch on/off |
| **Transition** | When a process changes type (e.g., when a user runs a command) |
