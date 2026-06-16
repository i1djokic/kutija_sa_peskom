# Tools

## aa-status

List all loaded profiles and their current mode:

```bash
sudo aa-status
```

Example output:

```
apparmor module is loaded.
40 profiles are loaded.
36 profiles are in enforce mode.
   /usr/sbin/nginx
   /usr/sbin/mysqld
   /usr/bin/man
   ...
4 profiles are in complain mode.
   /usr/sbin/apache2
   ...
4 processes have profiles defined.
4 processes are in enforce mode.
   /usr/sbin/nginx (1234)
   ...
0 processes are in complain mode.
0 processes are unconfined but have a profile defined.
```

## aa-enforce

Switch a profile to enforce mode:

```bash
sudo aa-enforce /usr/sbin/nginx
# or
sudo aa-enforce nginx
```

## aa-complain

Switch a profile to complain (learning) mode:

```bash
sudo aa-complain /usr/sbin/nginx
```

While in complain mode, all denied operations are allowed but logged. Run your application and use `aa-logprof` to build the profile from the logs.

## aa-disable

Unload a profile entirely:

```bash
sudo aa-disable /usr/sbin/nginx
```

This moves the profile files to `/etc/apparmor.d/disable/` (symbolic links). The profile remains on disk but is not loaded.

To re-enable:

```bash
sudo rm /etc/apparmor.d/disable/usr.sbin.nginx
sudo systemctl reload apparmor
```

## aa-unconfined

List processes running without any AppArmor profile:

```bash
sudo aa-unconfined
```

## aa-autodep

Generate a minimal (stub) profile that allows almost nothing:

```bash
sudo aa-autodep /usr/sbin/myapp
```

Creates a profile with only basic includes and common paths. Useful as a starting point before running `aa-genprof`.

## aa-genprof

**The main tool for creating profiles.** Guided, interactive profile generation:

```bash
sudo aa-genprof /usr/sbin/nginx
```

See [06-generating-profiles.md](./06-generating-profiles.md) for the full walkthrough.

## aa-logprof

Post-process audit logs to update profiles:

```bash
# After running an application in complain mode
sudo aa-logprof
```

Scans logs for AppArmor denials and asks how to handle each one (allow, deny, etc.). Automatically updates the profile file.

## aa-notify

Display desktop notifications for AppArmor denials:

```bash
sudo aa-notify -p     # Parse and show recent denials
sudo aa-notify -s 1   # Show denials from last day
```

## aa-mergeprof

Merge two profiles together:

```bash
sudo aa-mergeprof /path/to/base-profile /path/to/new-rules
```

## apparmor_parser

Load, reload, or unload profiles in the kernel (low-level tool):

```bash
# Load/reload a profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx

# Load profile containing includes (add includes path)
sudo apparmor_parser -r -I /etc/apparmor.d /etc/apparmor.d/usr.sbin.nginx

# Unload a profile
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.nginx

# Check syntax without loading
sudo apparmor_parser -N /etc/apparmor.d/usr.sbin.nginx
```

## aa-enabled

Quick check if AppArmor is active:

```bash
aa-enabled
# Output: Yes
```

## Comparing to SELinux Tools

| AppArmor | SELinux equivalent |
|----------|-------------------|
| `aa-status` | `getenforce`, `sestatus` |
| `aa-enforce` | `setenforce 1` (per profile vs system-wide) |
| `aa-complain` | `setenforce 0` (per profile vs system-wide) |
| `aa-genprof` | No direct equivalent |
| `aa-logprof` | `audit2allow` |
| `aa-notify` | `sealert` |
| `apparmor_parser -r` | `semodule -i` |
| `aa-disable` | `semodule -d` |
