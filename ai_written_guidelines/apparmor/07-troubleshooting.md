# Troubleshooting

## Where Denials Are Logged

AppArmor denials go to the **audit log** (if `auditd` is running) or the kernel log:

```bash
# Primary location (auditd)
sudo ausearch -m apparmor -ts recent

# Alternative — kernel log
sudo journalctl -k | grep apparmor

# Or plain
sudo grep apparmor /var/log/syslog
sudo grep apparmor /var/log/kern.log
```

## Reading a Denial

```
audit(1704067200.123:456): apparmor="DENIED"
  operation="open"
  profile="/usr/sbin/nginx"
  name="/etc/shadow"
  pid=1234 comm="nginx"
  requested_mask="r"
  denied_mask="r"
  fsuid=0 ouid=0
```

| Field | Meaning |
|-------|---------|
| `operation="open"` | What the program tried to do |
| `profile="/usr/sbin/nginx"` | Which profile did the denying |
| `name="/etc/shadow"` | The file that was accessed |
| `requested_mask="r"` | What access was requested |
| `denied_mask="r"` | What access was denied |
| `fsuid=0` | User ID of the process (0 = root) |

The fix is always the same pattern: add a rule to the profile allowing that access.

## aa-logprof — Post-Processing Denials

After running an application in **complain mode** (which logs all denials without blocking them), use `aa-logprof` to update the profile:

```bash
# 1. Put profile in complain mode
sudo aa-complain /usr/sbin/myapp

# 2. Run your application through all its operations
sudo systemctl restart myapp
# ... use the app ...

# 3. Process denials
sudo aa-logprof
```

`aa-logprof` scans the denial log and asks what to do for each one:

```
Profile:  /usr/sbin/myapp
Path:     /var/lib/myapp/data

 (A)llow / (D)eny / (G)lob / (N)ew / (Q)uit / (F)inish
```

Choose `A` to allow the exact path, `G` to allow with a glob pattern.

## aa-notify — Quick Denial Summary

```bash
# Show recent denials in plain text
sudo aa-notify -p

# Show denials from the last 24 hours
sudo aa-notify -s 86400

# Show desktop notification
sudo aa-notify -v
```

## Common Denials and Fixes

### 1. File not accessible

```
audit: apparmor="DENIED" operation="open"
  profile="/usr/sbin/nginx" name="/var/www/custom/index.html"
```

**Fix** — add to profile:

```
/var/www/custom/** r,
```

### 2. Log file can't be written

```
audit: apparmor="DENIED" operation="open"
  profile="/usr/sbin/nginx" name="/var/log/nginx/error.log"
  requested_mask="w"
```

**Fix** — add to profile:

```
/var/log/nginx/* w,
```

### 3. Can't bind to port

```
audit: apparmor="DENIED" operation="create"
  profile="/usr/sbin/myapp" pid=1234 comm="myapp"
  capability="net_bind_service"
```

**Fix** — add to profile:

```
capability net_bind_service,
network inet stream,
```

### 4. Can't execute another program

```
audit: apparmor="DENIED" operation="exec"
  profile="/usr/sbin/myapp" name="/usr/bin/cat"
```

**Fix** — add to profile:

```
/usr/bin/cat ix,   # same profile (inherit)
/usr/bin/cat px,   # transition to cat's own profile
```

## Debugging Workflow

1. **Check mode**: `sudo aa-status | grep myapp` — is it enforcing or complaining?
2. **Switch to complain**: `sudo aa-complain /usr/sbin/myapp`
3. **Reproduce the issue**: `sudo systemctl restart myapp`
4. **Check logs**: `sudo journalctl -k | grep apparmor | grep myapp`
5. **Fix the profile**: Either run `sudo aa-logprof` or edit `/etc/apparmor.d/usr.sbin.myapp` manually
6. **Reload**: `sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.myapp`
7. **Switch to enforce**: `sudo aa-enforce /usr/sbin/myapp`
8. **Verify**: `sudo aa-status | grep myapp`

## Silent Denials

If an application fails and you see **no** AppArmor denials in logs:
- Check that `auditd` is running: `sudo systemctl status auditd`
- Check kernel logs: `sudo journalctl -k | tail -50`
- The denial might be masked by `rate limiting` in the audit subsystem
- It might not be AppArmor — could be file permissions, DAC, or systemd sandboxing

## Checking Profile Coverage

```bash
# Which processes have profiles loaded?
sudo aa-status

# Which processes are completely unconfined?
sudo aa-unconfined
```

## Reloading After Manual Edit

After editing a profile file:

```bash
# Reload just that profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.myapp

# Or reload all profiles
sudo systemctl reload apparmor
```
