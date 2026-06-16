# Generating Profiles

## Use Case

You installed `myapp` and want to confine it. You could write a profile from scratch, but `aa-genprof` does most of the work interactively.

## Prerequisites

```bash
# Install AppArmor utilities
# Fedora/RHEL
sudo dnf install apparmor-utils apparmor-profiles

# Debian/Ubuntu
sudo apt install apparmor-utils apparmor-profiles
```

## aa-genprof Walkthrough

### Step 1: Start Profile Generation

```bash
sudo aa-genprof /usr/sbin/myapp
```

`aa-genprof` creates a stub profile (if one doesn't exist) and puts it in **complain mode**, then monitors logs for denials.

### Step 2: Exercise Your Application

`aa-genprof` will show:

```
Please start the application to be profiled and
specify any arguments the application needs.

When the application is started, you should:
  1) Cause the application to perform all functions
     you intend to confine it to.
  2) Then press 'S' to scan the system log for
     AppArmor events.

Press 'S' when ready, or 'F' to finish.
```

In another terminal, run your application through its operations:

```bash
# Start the daemon
sudo systemctl start myapp

# Hit a web page (if it's a web app)
curl http://localhost:8080/

# Log in, do something
# ...
```

### Step 3: Scan Logs

Press `S` in the `aa-genprof` terminal. It scans the audit log and shows each denial:

```
Reading log entries from /var/log/audit/audit.log.

Profile:  /usr/sbin/myapp
Execute:  /usr/bin/cat
Severity: unknown

Applicable modes:
  (1) Inherit  (I)
  (2) Profile  (P)
  (3) Unconfined  (Ux)
  (4) Deny  (D)

[(I)nherit] / (P)rofile / (U)nconfined / (D)eny / (A)llow / (G)lob / (N)ew / (Q)uit / (F)inish
```

### Step 4: Decide Each Denial

| Option | Meaning | When to use |
|--------|---------|-------------|
| `I` (Inherit) | Child runs with the same profile | Running another instance of the same app |
| `P` (Profile) | Child runs under a **specific named profile** | Running a known confined program (e.g., `/usr/bin/gpg`) |
| `Ux` (Unconfined) | Child runs without AppArmor | Only if you must, avoid this |
| `D` (Deny) | Explicitly block this in the profile | You know this shouldn't happen |
| `A` (Allow) | Add this exact path as allowed | The app legitimately needs this |
| `G` (Glob) | Add a wildcard path (e.g., `/var/www/**`) | The app needs access to a directory tree |
| `N` (New) | Type the rule manually | When the suggestion is close but not exactly right |

### Step 5: Repeat

After each decision, `aa-genprof` continues scanning. Exercise more of your application, press `S` again, and repeat until no more denials appear.

### Step 6: Finish

When done, press `F`. `aa-genprof` updates the profile file and switches it to enforce mode.

```bash
# Verify
sudo aa-status | grep myapp
# Should show "myapp ... (enforce)"
```

## aa-autodep — Quick Stub

For a starting point without the interactive process:

```bash
sudo aa-autodep /usr/sbin/myapp
```

Creates `/etc/apparmor.d/usr.sbin.myapp` with a minimal skeleton:

```
#include <tunables/global>

profile myapp /usr/sbin/myapp {
  #include <abstractions/base>

  # No other rules — almost everything will be denied
}
```

Then you either edit it manually or run `aa-genprof` to fill it in.

## Tips for Profile Generation

1. **Exercise every function** of the application during generation — denied operations are only caught when they actually happen
2. **Use complain mode** with `aa-complain` to capture denials over time
3. **Run `aa-logprof`** periodically to catch denials from production usage without the interactive `aa-genprof` loop
4. **Review generated profiles** — `aa-genprof` tends to add very specific paths; you may want to simplify with globs
5. **Test after generation** — flip to complain mode first, let it run, check for denials, then enforce
