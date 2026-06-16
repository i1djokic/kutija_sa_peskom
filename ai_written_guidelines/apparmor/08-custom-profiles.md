# Custom Profiles

Writing profiles by hand gives you full control. The interactive tools (`aa-genprof`, `aa-logprof`) handle 90% of cases, but manual editing is needed for complex rules, variables, and advanced features.

## When to Write Manually

- The generated profile is too permissive (overly broad globs)
- You need `owner` or `deny` rules
- You need hats (subprofiles) for Apache/PHP
- The application needs complex network rules
- You want to split rules across multiple files

## Starting From Scratch

Create a new file in `/etc/apparmor.d/`:

```bash
sudo touch /etc/apparmor.d/usr.sbin.myapp
```

### Minimal Template

```
#include <tunables/global>

profile myapp /usr/sbin/myapp {
  #include <abstractions/base>
  #include <abstractions/nameservice>
}
```

Load it:

```bash
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.myapp
sudo aa-enforce /usr/sbin/myapp
```

This profile allows almost nothing (only what's in `abstractions/base`). Watch logs and add rules as needed.

### Adding File Rules

```
profile myapp /usr/sbin/myapp {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  # Config
  /etc/myapp/ r,
  /etc/myapp/** r,

  # Data
  /var/lib/myapp/** rw,

  # Logs
  /var/log/myapp/* w,

  # Sockets
  /run/myapp.pid rw,
  /run/myapp.sock rw,
}
```

### Adding Capabilities and Network

```
profile myapp /usr/sbin/myapp {
  #include <abstractions/base>

  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability chown,
  capability dac_override,

  network inet stream,
  network inet6 stream,

  deny network netlink raw,

  ...
}
```

## Using Variables

Variables (tunables) keep profiles portable:

```
# Define at the top (after includes)
@{MYAPP_DATA}=/srv/myapp
@{MYAPP_CONF}=/etc/myapp

# Use in rules
@{MYAPP_CONF}/ r,
@{MYAPP_CONF}/** r,
@{MYAPP_DATA}/ rw,
@{MYAPP_DATA}/** rw,
```

Common predefined tunables:

| Variable | Expands to |
|----------|-----------|
| `@{HOME}` | `/home/*` |
| `@{HOMEDIRS}` | Common home directory paths |
| `@{PROC}` | `/proc/` |
| `@{PID}` | `/proc/[0-9]*/` |
| `@{dev}` | Device files |
| `@{sys}` | `/sys/` |

## Using Includes (Abstractions)

Abstractions package common rules for well-known subsystems:

```
#include <abstractions/base>         # libc, ld, basic /proc
#include <abstractions/nameservice>  # DNS, /etc/hosts, nsswitch
#include <abstractions/openssl>      # OpenSSL certs, config
#include <abstractions/php>          # PHP-FPM integration
#include <abstractions/mysql>        # MySQL client access
#include <abstractions/python>       # Python modules
#include <abstractions/X>            # X11 GUI access
```

Browse available abstractions:

```bash
ls /etc/apparmor.d/abstractions/
```

## Using Hats (Subprofiles)

Hats are subprofiles that a single process can switch to. Used heavily in Apache:

```
profile apache2 /usr/sbin/apache2 {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_bind_service,
  capability setgid,
  capability setuid,
  network inet stream,

  /etc/apache2/ r,
  /etc/apache2/** r,
  /var/log/apache2/* w,

  # Default hat for static files
  ^DEFAULT_URI {
    /var/www/html/** r,
  }

  # Tighter hat for CGI scripts
  ^CGI {
    /usr/lib/cgi-bin/** rix,
    /var/www/cgi-bin/** rix,
  }
}
```

The program enters a hat by calling `change_hat()` with the hat token.

## Compile-Time Checks

Before loading, verify syntax:

```bash
# Check syntax (N = no load)
sudo apparmor_parser -N /etc/apparmor.d/usr.sbin.myapp
# Silent = OK
```

## Best Practices

1. **Start with complain mode** — never write and enforce in one shot
2. **Use abstractions** — they save time and are maintained by distro
3. **Be specific with paths** — `/var/www/prod/** r,` not `/ r,`
4. **Use `owner` for user files** — `owner /home/** rw,` limits to files owned by the process
5. **Use `deny` for defense in depth** — block sensitive paths even if a broad rule accidentally allows them
6. **Keep `deny` rules before `allow` rules** — easier to read
7. **Test with `aa-logprof`** even for manual profiles
