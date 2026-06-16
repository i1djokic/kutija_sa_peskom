# Troubleshooting

SELinux denials are logged to the **audit log** (maintained by the `auditd` daemon). If `auditd` is not running, denials go to the system log instead.

## Checking auditd Is Running

```bash
sudo systemctl status auditd
# If not running:
sudo systemctl start auditd
sudo systemctl enable auditd
```

If auditd is not available, check the system log (see below).

## Checking for Denials

```bash
# Check recent denials
# -ts recent = "timestamp recent" — show events from the last few minutes
sudo ausearch -m avc -ts recent

# Check all denials from today
sudo ausearch -m avc -ts today

# Check the last 5 minutes (specific time)
sudo ausearch -m avc -ts 17:00

# Follow denials in real time
sudo tail -f /var/log/audit/audit.log | grep AVC

# If auditd is not running, check system log
sudo journalctl | grep AVC          # systemd distros
sudo grep AVC /var/log/messages     # syslog distros
```

## Understanding an AVC Denial

Every denial produces an **AVC** (Access Vector Cache) message. Here's how to read one:

```
type=AVC msg=audit(1704067200.123:456):
  avc:  denied  { write }
  for pid=1234 comm="httpd"
  name="index.html" dev=sda1 ino=56789
  scontext=system_u:system_r:httpd_t:s0
  tcontext=unconfined_u:object_r:httpd_sys_content_t:s0
  tclass=file permissive=0
```

| Field | Meaning |
|-------|---------|
| `denied { write }` | The operation that was blocked |
| `comm="httpd"` | The process that was blocked |
| `name="index.html"` | The target file |
| `scontext` | Security context of the **process** (subject) |
| `tcontext` | Security context of the **target** (object) |
| `tclass=file` | Type of object (file, dir, socket, tcp_socket) |
| `permissive=0` | 0 = would have been denied in enforcing mode; 1 = was allowed because in permissive mode |

The key insight: the **scontext** domain tried to do something to the **tcontext** type, and the policy didn't allow it. Your fix will either:
- Change the file's context (tcontext) to a type the process is allowed to access
- Change the process's permissions (via boolean or custom policy)

## Decoding Denials

### audit2why

Quick explanation of why something was denied:

```bash
sudo ausearch -m avc -ts recent | audit2why
# Output example:
# Was caused by:
#   Missing type enforcement (TE) allow rule.
#   You can use audit2allow to generate a loadable module.
```

### audit2allow

Generate policy to allow the denial:

```bash
# Show what rule would fix it
sudo ausearch -m avc -ts recent | audit2allow -a

# Generate a policy module (-M gives the module a name)
sudo ausearch -m avc -ts recent | audit2allow -M mymodule

# This creates:
#   mymodule.pp  — compiled policy module
#   mymodule.te  — readable policy source

# Load it
sudo semodule -i mymodule.pp
```

## sealert (setroubleshoot)

If `setroubleshoot` is installed, SELinux denials also generate user-friendly messages with suggestions:

```bash
# Install (Fedora/RHEL)
sudo dnf install setroubleshoot setroubleshoot-server

# Install (Debian/Ubuntu — package name may vary)
sudo apt install setroubleshoot

# Sealert will pop up desktop notifications
# Or check logs for the friendly messages:
sudo grep -r "SELinux" /var/log/messages | tail -20
```

Example sealert output:

```
SELinux is preventing httpd from open access on the file /var/www/html/test.txt.

If you want to allow httpd to open this file, you must change the file context:
  sudo chcon -t httpd_sys_content_t /var/www/html/test.txt

Or restore the default:
  sudo restorecon -v /var/www/html/test.txt
```

## Common Troubleshooting Steps

### 1. Identify the Problem

```bash
sudo ausearch -m avc -ts recent
```

### 2. Check Mode

```bash
getenforce
```

### 3. Temporarily Disable (Test)

```bash
sudo setenforce 0
# Test your application
# If it works, SELinux is the cause
sudo setenforce 1
```

### 4. Find the Fix

- **Wrong context →** `restorecon` or `semanage fcontext`
- **Boolean available →** `setsebool -P <boolean> on`
- **No boolean →** create a custom policy with `audit2allow`

### 5. Fix and Verify

```bash
sudo setenforce 1
# Test your application
# Check no new denials
sudo ausearch -m avc -ts recent
```

## Enabling Full Audit Logging

By default, SELinux uses **dontaudit rules** — rules that explicitly suppress certain expected denials from being logged (to keep the log quiet). If you're debugging and want to see **every** denial:

```bash
# Install utilities (Fedora/RHEL)
sudo dnf install policycoreutils policycoreutils-python-utils

# Install utilities (Debian/Ubuntu)
sudo apt install policycoreutils selinux-utils

# Remove dontaudit rules from the policy — now all denials are logged
sudo semodule -DB
```

Revert (re-enable dontaudit, restore normal quiet logging):

```bash
# Rebuild policy (re-add dontaudit rules)
sudo semodule -B
```

## File and Process Labels

Check if labels are correct:

```bash
# What type should the file have?
sudo matchpathcon /var/www/html/index.html
# /var/www/html/index.html  system_u:object_r:httpd_sys_content_t:s0

# What type does it actually have?
ls -Z /var/www/html/index.html
```
