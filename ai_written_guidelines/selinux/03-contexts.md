# Security Contexts

Every process and file has an SELinux security context. Understanding contexts is the key to fixing denials.

## Context Format

```
user:role:type:level
```

Example:

```
system_u:object_r:httpd_sys_content_t:s0
```

| Field | Meaning | Example |
|-------|---------|---------|
| `user` | SELinux user identity | `system_u`, `unconfined_u`, `user_u` |
| `role` | Role-based access | `object_r` (files), `system_r` (system processes) |
| **`type`** | **The main enforcement mechanism (targeted policy)** | `httpd_t`, `httpd_sys_content_t`, `etc_t` |
| `level` | MLS sensitivity | `s0`, `s0:c0.c1023` |

In targeted policy, **type** is what matters for access decisions. The type of a **process** is called its **domain** (e.g., `httpd_t`), and the type of a **file** is just called its type (e.g., `httpd_sys_content_t`). The policy decides which domains can access which types and how.

## Viewing Contexts

```bash
# Files and directories
ls -Z
# -rw-r--r--. root root system_u:object_r:etc_t:s0       resolv.conf

# Processes
ps auxZ | grep httpd
# system_u:system_r:httpd_t:s0    root  1234  ... /usr/sbin/httpd

# Your own context
id -Z
# unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023

# Network ports
sudo netstat -Z | grep :80
```

## How Access Decisions Work

SELinux checks if the **domain** of the process (e.g., `httpd_t`) is allowed to access the **type** of the file (e.g., `httpd_sys_content_t`).

```
Process: httpd (domain: httpd_t)
  wants to read
File: /var/www/html/index.html (type: httpd_sys_content_t)

Policy check: "Can httpd_t read httpd_sys_content_t?" → yes
```

```
Process: httpd (domain: httpd_t)
  wants to write
File: /var/www/html/index.html (type: httpd_sys_content_t)

Policy check: "Can httpd_t write httpd_sys_content_t?" → no (read-only)
```

## Changing Contexts

### chcon — Temporary Change

`chcon` changes the context immediately, but the change is **not tracked** by the policy. Running `restorecon` or a full filesystem relabel will revert it.

```bash
# Change a file's type (temporary — survives until restorecon or relabel)
sudo chcon -t httpd_sys_content_t /var/www/html/index.html

# Change user/role/type
sudo chcon -u system_u -r object_r -t httpd_sys_content_t file.txt

# Reference an existing file's context
sudo chcon --reference=/var/www/html/index.html new-file.html
```

### restorecon — Restore Default

Undo manual `chcon` changes by restoring the default policy context:

```bash
# Restore a single file
sudo restorecon /var/www/html/index.html

# Restore recursively
sudo restorecon -Rv /var/www/

# Restore and show changes
sudo restorecon -Rv /var/www/
```

### semanage fcontext — Persistent Changes

For changes that **must survive** `restorecon` or relabeling, register the rule with the SELinux policy database using `semanage fcontext`:

```bash
# Add a persistent rule
# The path pattern "/web(/.*)?" means: /web and everything inside it
# (/.*)? is a regex: "optionally followed by a slash and any content"
sudo semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"

# Apply it (restorecon reads the semanage rules and sets the matching contexts)
sudo restorecon -Rv /web

# Remove a persistent rule
sudo semanage fcontext -d -t httpd_sys_content_t "/web(/.*)?"
```

**How to choose the path pattern:**

| Path | Pattern | What it matches |
|------|---------|----------------|
| `/web` | `/web(/.*)?` | `/web` itself and `/web/file.txt`, `/web/sub/dir/` |
| `/var/www/html` | `/var/www/html(/.*)?` | The html dir and everything inside |
| `/home/user/public_html` | `/home/[^/]+/public_html(/.*)?` | A specific user's public_html |

## Common File Types

| Type | Purpose |
|------|---------|
| `etc_t` | Config files in /etc |
| `bin_t` | Executables in /bin, /usr/bin |
| `var_t` | Variable data in /var |
| `httpd_sys_content_t` | Web content readable by httpd |
| `httpd_sys_rw_content_t` | Web content writable by httpd |
| `public_content_t` | Public read-only files (ftp, samba) |
| `samba_share_t` | Samba shared files |
| `home_root_t` | /home directory |
| `user_home_t` | User home directories |
| `tmp_t` | /tmp files |

## Context Inheritance

When you **create** a file (with `touch`, `cp`, `mkdir`, redirect output), it inherits the context of its parent directory. A file created in `/var/www/html/` gets `httpd_sys_content_t` because the directory has that type.

When you **move** a file (with `mv`), the file **keeps its original context** from its old location. This is a common source of SELinux denials — a file that looks correct in every other way has the wrong context because it was moved from a different directory.

```bash
# cp → creates new file → inherits parent context → works
cp /home/user/index.html /var/www/html/
ls -Z /var/www/html/index.html
# system_u:object_r:httpd_sys_content_t:s0   ← correct

# mv → keeps original context → may fail
mv /home/user/index.html /var/www/html/
ls -Z /var/www/html/index.html
# unconfined_u:object_r:user_home_t:s0       ← WRONG! Was from /home

# Fix after mv:
sudo restorecon -v /var/www/html/index.html
```
