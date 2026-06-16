# Modes

AppArmor has three operational states for each profile.

## Enforce Mode

Policies are enforced. Denied operations are blocked and logged.

## Complain Mode (Learning/Audit)

Policies are **not enforced**. Denied operations are **allowed** but **logged**. Used for:
- Testing a new profile before enforcing it
- Learning what an application needs (`aa-logprof` reads complain logs)
- Troubleshooting without breaking functionality

## Disabled (Unconfined)

The profile is loaded but does nothing. The process runs unconfined (no AppArmor restrictions). The profile can be re-enabled later without recompiling.

## Switching Modes

```bash
# Check current mode of all profiles
sudo aa-status

# Check mode of a specific profile
sudo aa-status | grep nginx

# Put profile into enforce mode
sudo aa-enforce /usr/sbin/nginx

# Put profile into complain mode
sudo aa-complain /usr/sbin/nginx

# Disable profile (unload from kernel)
sudo aa-disable /usr/sbin/nginx
```

You can also specify the profile name instead of the path:

```bash
sudo aa-enforce nginx
sudo aa-complain nginx
sudo aa-disable nginx
```

## Global Default Mode

To set the default mode for all profiles, edit `/etc/apparmor.d/local/` configurations, or use kernel boot parameters:

```
# Boot into complain mode globally (for debugging)
apparmor=1 security=apparmor apparmor_audit=1
```

## Runtime vs Permanent

Mode changes with `aa-enforce`/`aa-complain`/`aa-disable` are **not persistent across reboot** — they only affect the currently loaded profiles in the kernel. To make a mode permanent, edit the profile file:

```
# /etc/apparmor.d/usr.sbin.nginx
# Change 'flags=(complain)' to 'flags=(enforce)' or remove the flags line
```

Or use `aa-enabled` to check if AppArmor is loaded:

```bash
aa-enabled
# Output: Yes
```
