# Reference

## Command Cheat Sheet

### Modes

| Command | What it does |
|---------|-------------|
| `getenforce` | Show current mode (Enforcing/Permissive/Disabled) |
| `sestatus` | Detailed SELinux status |
| `setenforce 0` | Switch to Permissive mode |
| `setenforce 1` | Switch to Enforcing mode |
| `sudo touch /.autorelabel` | Force relabel on next reboot |

### Contexts

| Command | What it does |
|---------|-------------|
| `ls -Z` | View file contexts |
| `ps auxZ` | View process contexts |
| `id -Z` | View your own context |
| `sudo chcon -t TYPE file` | Temporarily change file context |
| `sudo restorecon file` | Restore default context |
| `sudo restorecon -Rv /dir` | Restore recursively, show changes |
| `semanage fcontext -a -t TYPE "/path(/.*)?"` | Add persistent context rule |
| `semanage fcontext -l` | List persistent context rules |
| `semanage fcontext -d -t TYPE "/path(/.*)?"` | Remove persistent rule |
| `matchpathcon /path` | Show what context the policy says a path *should* have (useful to compare with `ls -Z`) |

### Booleans

| Command | What it does |
|---------|-------------|
| `getsebool -a` | List all booleans |
| `getsebool httpd_can_network_connect` | Check a specific boolean |
| `sudo setsebool httpd_can_network_connect on` | Enable temporarily |
| `sudo setsebool -P httpd_can_network_connect on` | Enable permanently |
| `sudo semanage boolean -l` | List booleans with descriptions |
| `sudo semanage boolean -l \| grep httpd` | Filter by name |

### Ports

| Command | What it does |
|---------|-------------|
| `sudo semanage port -l` | List all port definitions |
| `sudo semanage port -l \| grep http` | List HTTP-related ports |
| `sudo semanage port -a -t http_port_t -p tcp 8080` | Add port 8080 to http_port_t |

### Troubleshooting

| Command | What it does |
|---------|-------------|
| `sudo ausearch -m avc -ts recent` | Show recent AVC denials |
| `sudo ausearch -m avc -ts today` | Show today's denials |
| `sudo tail -f /var/log/audit/audit.log \| grep AVC` | Watch denials in real time |
| `sudo ausearch -m avc -ts recent \| audit2why` | Explain why denied |
| `sudo ausearch -m avc -ts recent \| audit2allow` | Show allow rules |
| `sudo ausearch -m avc -ts recent \| audit2allow -M mymodule` | Generate policy module |
| `sudo grep AVC /var/log/messages` | Denials if auditd is off |
| `sudo journalctl \| grep AVC` | Denials via systemd journal |

### Custom Policy

| Command | What it does |
|---------|-------------|
| `sudo semodule -l` | List loaded policy modules |
| `sudo semodule -i myapp.pp` | Install a policy module |
| `sudo semodule -r myapp` | Remove a policy module |
| `sudo semodule -u myapp.pp` | Update a policy module |
| `sudo semodule -e myapp` | Enable a disabled module |
| `sudo semodule -d myapp` | Disable a module |
| `sudo semodule -DB` | Turn off dontaudit rules (enable all logging) |
| `sudo semodule -B` | Rebuild policy (restore dontaudit) |
| `sudo semanage permissive -a httpd_t` | Make a domain permissive |
| `sudo semanage permissive -d httpd_t` | Remove permissive exemption |

## File Types Quick Reference

| Type | Used for |
|------|----------|
| `httpd_sys_content_t` | Web content (readable by httpd) |
| `httpd_sys_rw_content_t` | Web content writable by httpd |
| `httpd_log_t` | httpd log files |
| `samba_share_t` | Samba shared directories |
| `public_content_t` | Public read-only (FTP, rsync) |
| `public_content_rw_t` | Public read-write |
| `user_home_t` | User home directories |
| `tmp_t` | /tmp files |
| `var_t` | /var files (generic) |
| `etc_t` | /etc configuration files |
| `bin_t` | Executables |
| `default_t` | Unlabeled files (usually wrong) |

## Boolean Quick Reference

| Boolean | Use case |
|---------|----------|
| `httpd_can_network_connect` | httpd as proxy, connecting to APIs |
| `httpd_can_network_connect_db` | httpd connecting to database |
| `httpd_enable_homedirs` | httpd serving ~/public_html |
| `httpd_can_sendmail` | httpd sending email |
| `httpd_use_nfs` | httpd accessing NFS mounts |
| `samba_enable_home_dirs` | Samba sharing home dirs |
| `ftp_home_dir` | FTP access to home dirs |
| `ssh_chroot_rw_homedirs` | SSH chroot access |
| `nfs_export_all_rw` | NFS read-write exports |

## Config File

`/etc/selinux/config`:

```ini
# enforcing | permissive | disabled
SELINUX=enforcing
# targeted | mls | minimum
SELINUXTYPE=targeted
```
