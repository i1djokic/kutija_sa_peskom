# Profile Rules

Rules are written inside the profile's `{ }` block. Each rule defines what a program can access.

## File Access Rules

```
/path/to/file permissions,
```

Supported file permissions:

| Permission | Meaning |
|------------|---------|
| `r` | Read |
| `w` | Write (implies append) |
| `a` | Append only |
| `k` | File locking |
| `l` | Link (hard/symlink) |
| `ix` | Execute **inherit** — run child with same profile |
| `px` | Execute **profile** — run child under a **specific** (named) profile |
| `Px` | Execute **profile** (delegate to named profile, scrub environment) |
| `cx` | Execute **child** — transition to another profile within same binary |
| `Cx` | Execute child (scrub environment) |
| `ux` | Execute **unconfined** — child runs without AppArmor (dangerous) |
| `Ux` | Execute unconfined with scrub (dangerous) |
| `m` | Memory map executable (PROT_EXEC mmap) |

## Path Patterns

| Pattern | Matches |
|---------|---------|
| `/etc/nginx/` | The directory itself |
| `/etc/nginx/*` | Files directly in /etc/nginx (not subdirectories) |
| `/etc/nginx/**` | Everything recursively under /etc/nginx |
| `/var/www/*/public/` | Any subdir's `public/` at depth 2 |
| `/home/*/public_html/` | Any user's public_html |
| `/home/*/public_html/**` | Recursive under any user's public_html |

There is no regex in path matching — only `*` (single level) and `**` (any depth).

## Capability Rules

Linux capabilities that the profile may use:

```
capability dac_override,
capability net_bind_service,
capability sys_admin,
capability setuid,
capability kill,
capability chown,
```

Without these, the program cannot use that capability even if the process runs as root.

## Network Rules

```
network <domain> <type> <protocol>,
```

Examples:

```
network inet stream,           # TCP IPv4
network inet dgram,            # UDP IPv4
network inet6 stream,          # TCP IPv6
network netlink raw,           # Netlink sockets
network unix stream,           # Unix domain sockets (local)
network unix dgram,
```

Without any `network` rule, all network access is blocked.

## Mount Rules

```
mount options=(ro,bind) /dev/sda1 -> /mnt/point,
umount /mnt/point,
pivot_root /new-root,
```

## change_profile Rules

Controls transitions to other profiles:

```
change_profile -> /usr/sbin/other-binary,
```

## Variable Rules (Tunables)

```
@{NGINX_CONF_DIR}=/etc/nginx
@{HOME}=/home/*/public_html

@{NGINX_CONF_DIR}/ r,
@{NGINX_CONF_DIR}/** r,
```

Variables are defined in `/etc/apparmor.d/tunables/` and included with `#include <tunables/global>`.

## Deny Rules

Explicitly block access even if other rules might allow it:

```
deny /etc/shadow r,
deny /root/** rw,
deny capability sys_ptrace,
```

`deny` rules override `allow` rules. Use them to carve out exceptions from broad permissions.

## Owner Rules

Restrict rules to files owned by the process's UID:

```
owner /home/*/ r,
owner /home/*/** rw,
```

Without `owner`, the rule applies regardless of file ownership. With `owner`, it only applies when the process owns the file.

## Audit Rules

Force logging even for allowed operations:

```
audit /etc/nginx/conf.d/ r,
audit capability net_bind_service,
```

Useful for verifying that specific rules are hit during normal operation.

## Putting It Together

```
profile nginx /usr/sbin/nginx {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_bind_service,
  capability setgid,
  capability setuid,

  network inet stream,

  # Deny sensitive files
  deny /etc/shadow r,
  deny /root/** rw,

  # Allow web content
  /etc/nginx/ r,
  /etc/nginx/** r,
  /var/www/** r,
  /var/log/nginx/* w,
  owner /run/nginx.pid rw,
}
```
