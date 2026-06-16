# Profiles

A profile is a set of rules that confine a single program. AppArmor uses the executable path to match a process to its profile.

## Profile Location

All profiles live in `/etc/apparmor.d/`. Each profile is a single file, named after the executable's absolute path with slashes replaced by dots:

| Executable | Profile file |
|------------|-------------|
| `/usr/sbin/nginx` | `/etc/apparmor.d/usr.sbin.nginx` |
| `/usr/bin/man` | `/etc/apparmor.d/usr.bin.man` |
| `/usr/lib/postfix/master` | `/etc/apparmor.d/usr.lib.postfix.master` |

## Profile Structure

A minimal profile looks like this:

```
# /etc/apparmor.d/usr.sbin.nginx
#include <tunables/global>

profile nginx /usr/sbin/nginx {
  #include <abstractions/base>

  /etc/nginx/ r,
  /etc/nginx/** r,
  /var/log/nginx/* w,
  /var/www/** r,
  /run/nginx.pid rw,
  network inet stream,
}
```

| Part | Meaning |
|------|---------|
| `#include <tunables/global>` | Pulls in global variable definitions (site-wide settings) |
| `profile nginx /usr/sbin/nginx` | Declares this profile applies to the nginx executable |
| `{ }` | The rules block — everything inside is what nginx can do |
| `#include <abstractions/base>` | Loads common rules (reading libraries, basic files) |
| `/etc/nginx/ r,` | Allow reading the nginx config directory |
| `/etc/nginx/** r,` | Allow reading everything recursively under /etc/nginx |
| `network inet stream,` | Allow TCP network connections |

## Profile Name vs Executable Path

```
profile <name> <executable-path> {
```

The name is for humans and tools. The path is what the kernel matches. If you leave out the path, AppArmor uses the profile name as the path:

```
profile nginx {  # same as: profile nginx /usr/sbin/nginx
```

## Multiple Executables, One Profile

Use the `profile` keyword with multiple paths:

```
profile nginx /usr/sbin/nginx {
```

Or attach an alias:

```
profile nginx /usr/sbin/nginx {
  ...
}
alias /usr/local/sbin/nginx -> /usr/sbin/nginx,
```

## Subprofiles (Hats)

A single binary can switch subprofiles based on role (like SELinux domain transitions). Used heavily in Apache and Postfix:

```
profile apache2 /usr/sbin/apache2 {
  # Main profile rules

  ^DEFAULT_URI {
    # Handles static files
    /var/www/html/** r,
  }

  ^HANDLING_UNTRUSTED_INPUT {
    # Tighter rules for processing user input
    /var/www/html/ r,
    /tmp/* rw,
  }
}
```

Hats allow the same process to change its confinement by calling `change_hat()`.

## Includes and Abstractions

Abstractions are shared rule sets that many profiles use:

```
#include <abstractions/base>     # Basic system access (shared libs, /proc, etc.)
#include <abstractions/nameservice>  # DNS resolution
#include <abstractions/openssl>   # OpenSSL access
#include <abstractions/php>       # PHP integration
```

Available abstractions live in `/etc/apparmor.d/abstractions/`.

## Loading Profiles

```bash
# Load all profiles
sudo systemctl reload apparmor

# Or load a single profile
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```
