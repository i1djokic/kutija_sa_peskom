# Practical Examples

## Example 1: Nginx

Profile for a standard nginx web server:

```
# /etc/apparmor.d/usr.sbin.nginx
#include <tunables/global>

profile nginx /usr/sbin/nginx {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability kill,

  network inet stream,

  # Deny sensitive files
  deny /etc/shadow r,
  deny /root/** rw,

  # Config
  /etc/nginx/ r,
  /etc/nginx/** r,

  # Web content
  /var/www/** r,

  # Logs
  /var/log/nginx/* w,

  # PID and sockets
  /run/nginx.pid rw,
  /run/nginx.sock rw,

  # Temp
  /var/tmp/ r,
  /var/tmp/** rw,
}
```

**Common denials with nginx:**
- Custom web root outside `/var/www/` → add the path with `r`
- PHP-FPM socket → add `/run/php/php-fpm.sock rw`
- Let's Encrypt certs → add `/etc/letsencrypt/** r`

## Example 2: Custom Python Web App

```
# /etc/apparmor.d/usr.bin.python3
#include <tunables/global>

profile python3 /usr/bin/python3 {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/python>

  capability net_bind_service,
  capability setgid,
  capability setuid,

  network inet stream,

  # App code
  /opt/myapp/** rix,

  # Config
  /etc/myapp/ r,
  /etc/myapp/** r,

  # Data
  /var/lib/myapp/** rw,

  # Logs
  /var/log/myapp/* w,
}
```

**Note:** Confining Python by its interpreter path (`/usr/bin/python3`) means **all** Python scripts inherit this profile. Consider using `px` in the parent profile to selectively confine only the scripts run by nginx/httpd.

## Example 3: MySQL/MariaDB

```
# /etc/apparmor.d/usr.sbin.mysqld
#include <tunables/global>

profile mysqld /usr/sbin/mysqld {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/mysql>

  capability setgid,
  capability setuid,
  capability sys_resource,
  capability net_bind_service,
  capability audit_write,

  network inet stream,

  # Data directory
  /var/lib/mysql/ r,
  /var/lib/mysql/** rwk,

  # Config
  /etc/mysql/ r,
  /etc/mysql/** r,

  # Logs
  /var/log/mysql/* rw,

  # PID, socket, pid file
  /run/mysqld/ r,
  /run/mysqld/** rw,
  /run/mysqld/mysqld.sock rw,
  /run/mysqld/mysqld.pid rw,

  # InnoDB temp
  /var/lib/mysql/ib_logfile* rw,
  /var/lib/mysql/ibdata* rw,
  /var/lib/mysql/ibtmp* rw,
}
```

## Example 4: Custom Daemon With Port 9000

```
# /etc/apparmor.d/usr.sbin.myapp
#include <tunables/global>

profile myapp /usr/sbin/myapp {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_bind_service,
  capability setgid,
  capability setuid,

  network inet stream,

  /etc/myapp/ r,
  /etc/myapp/** r,
  /var/lib/myapp/** rw,
  /run/myapp.pid rw,
}
```

AppArmor does not need a separate "port labeling" step like SELinux does — the `capability net_bind_service` rule grants the right to bind any port. If you need to restrict to a specific port, use a more granular approach (e.g., run as a non-root user and let the kernel's `CAP_NET_BIND_SERVICE` on the port handle it, or use iptables/nftables).

## Example 5: SSH Daemon

```
# /etc/apparmor.d/usr.sbin.sshd
#include <tunables/global>

profile sshd /usr/sbin/sshd {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability setgid,
  capability setuid,
  capability audit_write,
  capability net_bind_service,
  capability sys_chroot,
  capability sys_resource,

  network inet stream,
  network inet6 stream,

  /etc/ssh/ r,
  /etc/ssh/** r,
  /etc/ssh/ssh_host_* r,

  /run/sshd.pid rw,

  /var/log/btmp w,
  /var/log/wtmp w,

  /var/run/sshd/ r,
  /var/run/sshd/** rw,

  # PAM and auth
  /etc/pam.d/** r,
  /lib/security/** r,

  # User home directories — transition to unconfined for user sessions
  /home/*/ r,
  /home/*/** rix,
}
```

## Example 6: Confining a Script With a Subprofile (Hat)

Apache with PHP:

```
profile apache2 /usr/sbin/apache2 {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability kill,

  network inet stream,

  /etc/apache2/ r,
  /etc/apache2/** r,

  ^DEFAULT_URI {
    /var/www/html/** r,
    /var/www/ r,
  }

  ^PHP {
    #include <abstractions/php>

    /var/www/html/** r,
    /var/www/html/*.php rix,
    /tmp/ r,
  }
}
```

## SELinux Comparison

| Scenario | SELinux fix | AppArmor fix |
|----------|-------------|--------------|
| Web server can't read files | `restorecon -R /var/www/` or `semanage fcontext` | Add `/var/www/** r,` to nginx profile |
| Can't bind port | `semanage port -a -t http_port_t -p tcp 9000` | Add `capability net_bind_service, network inet stream,` to profile |
| App can't access its data | `chcon -t myapp_data_t /var/lib/myapp/` | Add `/var/lib/myapp/** rw,` to profile |
| Daemon can't run script | Custom policy with `allow httpd_t bin_t:file execute;` | Add `/usr/bin/script rix,` to profile |
