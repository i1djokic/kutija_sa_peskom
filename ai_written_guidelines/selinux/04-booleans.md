# Booleans

Booleans are on/off switches built into the SELinux policy. They let you enable/disable common features without writing custom policy rules. For example, instead of writing a policy to allow your web server to connect to a database, you just flip the `httpd_can_network_connect_db` boolean to `on`.

Think of booleans as toggles for pre-approved scenarios that the SELinux developers knew administrators would need.

## Viewing Booleans

```bash
# List all booleans with current status
getsebool -a

# Check specific booleans
getsebool httpd_can_network_connect
getsebool httpd_enable_homedirs

# List booleans with descriptions
# Note: semanage is part of the policycoreutils-python-utils package
sudo semanage boolean -l

# Filter booleans by prefix
sudo semanage boolean -l | grep httpd
```

## Setting Booleans

```bash
# Temporarily enable (until reboot)
sudo setsebool httpd_can_network_connect on

# Temporarily disable
sudo setsebool httpd_can_network_connect off

# Permanently enable (survives reboot)
sudo setsebool -P httpd_can_network_connect on
```

The `-P` flag makes the change persistent by writing to the policy store. Without `-P`, the change is lost on reboot.

## Common Booleans

### Web Server (httpd)

| Boolean | What it does |
|---------|-------------|
| `httpd_can_network_connect` | Allow httpd to connect to network (proxies, APIs) |
| `httpd_can_network_connect_db` | Allow httpd to connect to databases |
| `httpd_enable_homedirs` | Allow httpd to serve user home directories |
| `httpd_can_sendmail` | Allow httpd to send email |
| `httpd_use_nfs` | Allow httpd to access NFS mounts |
| `httpd_execmem` | Allow httpd to execute memory (needed by some PHP/Perl) |
| `httpd_unified` | Treat all httpd content as one type (simplifies) |
| `httpd_mod_auth_pam` | Allow httpd to use PAM for auth |

### SSH

| Boolean | What it does |
|---------|-------------|
| `ssh_chroot_rw_homedirs` | Allow SSH chroot to read/write home dirs |
| `ssh_sysadm_login` | Allow SSH login as sysadm |
| `selinuxuser_use_ssh_chroot` | Allow SSH chroot for SELinux users |

### File Sharing (Samba, FTP, NFS)

| Boolean | What it does |
|---------|-------------|
| `samba_enable_home_dirs` | Allow Samba to share home directories |
| `samba_export_all_rw` | Allow Samba to read/write any file |
| `ftp_home_dir` | Allow FTP to access home directories |
| `nfs_export_all_rw` | Allow NFS to export with read/write |
| `use_samba_home_dirs` | Support Samba home directories |

### System

| Boolean | What it does |
|---------|-------------|
| `global_ssp` | Enable stack smash protection |
| `selinuxuser_execheap` | Allow unconfined users to execute heap memory |
| `selinuxuser_execmod` | Allow unconfined users to execute modifiable memory |
| `selinuxuser_execstack` | Allow unconfined users to execute stack memory |

## Finding the Right Boolean

```bash
# Search by keyword
sudo semanage boolean -l | grep -i "database"
sudo semanage boolean -l | grep -i "nfs"
sudo semanage boolean -l | grep -i "network"

# After an AVC denial, use audit2why for suggestions
sudo ausearch -m avc -ts recent | audit2why
```

## Example Workflow

```bash
# 1. Application blocked
# 2. Check audit log
sudo ausearch -m avc -ts recent

# 3. Find the boolean
sudo semanage boolean -l | grep httpd

# 4. Try temporarily
sudo setsebool httpd_can_network_connect on

# 5. Verify application works
# 6. Make permanent
sudo setsebool -P httpd_can_network_connect on
```
