# System Administration

## System Information

```bash
# Hardware
uname -a                          # kernel info
lscpu                             # CPU details
free -h                           # memory
lsblk                             # block devices
lspci                             # PCI devices
lsusb                             # USB devices

# OS
cat /etc/os-release               # distro info
hostnamectl                       # hostname + OS details
uptime -p                         # uptime pretty-print

# Kernel parameters
sysctl -a                         # all kernel params
sysctl net.ipv4.tcp_tw_reuse      # specific param
sysctl -w net.core.somaxconn=65535 # set at runtime
```

## User & Group Management

```bash
# Users
useradd -m -s /bin/bash "$user"            # create with home dir
usermod -aG sudo "$user"                   # add to group
userdel -r "$user"                         # remove with home dir
passwd -l "$user"                          # lock account
chage -E 2026-12-31 "$user"                # set account expiry
chage -M 90 "$user"                        # max password age (days)

# Groups
groupadd devops                            # create group
gpasswd -a "$user" devops                  # add user to group
gpasswd -d "$user" devops                  # remove user from group
groupdel devops                            # delete group

# List users/groups
getent passwd                              # all users
getent group                               # all groups
groups "$user"                             # user's groups
id "$user"                                 # uid, gid, groups
```

## File Permissions

```bash
# chmod (symbolic)
chmod u+x script.sh              # user + execute
chmod g-w file.txt               # group - write
chmod o+r file.txt               # others + read
chmod a+x script.sh              # all + execute

# chmod (octal)
chmod 755 script.sh              # rwxr-xr-x
chmod 644 file.txt               # rw-r--r--
chmod 600 /home/user/.ssh/id_rsa # rw-------
chmod 700 /home/user/.ssh        # rwx------
chmod 400 secret.key             # r--------

# chown
chown user:group file.txt        # owner + group
chown -R user:group /path/       # recursive
chown user: file.txt             # change user only (keep group)
chown :group file.txt            # change group only

# ACL (for fine-grained control)
setfacl -m u:deploy:rx /opt/app  # grant deploy read+execute
getfacl /opt/app                  # view ACLs
```

## Process Management

```bash
# List processes
ps aux                            # all processes
ps auxf                           # tree view
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head  # top by CPU
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%mem | head  # top by memory

# Priority
nice -n 10 long_task &           # run with low priority
renice -n 5 -p "$pid"            # change priority of running process

# Limits per process
prlimit --pid "$pid"              # show limits
prlimit --pid "$pid" --nofile=65535 # raise file descriptor limit
```

## systemd Service Management

```bash
# Create service
cat > /etc/systemd/system/myapp.service << 'UNIT'
[Unit]
Description=My Application
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=myapp
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/bin/server
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT

# Operations
systemctl daemon-reload
systemctl enable myapp
systemctl start myapp
systemctl status myapp
systemctl restart myapp
systemctl reload myapp            # SIGHUP (if supported)
systemctl stop myapp
journalctl -u myapp               # view logs
journalctl -u myapp -f            # follow logs
journalctl -u myapp --since "1 hour ago"
```

## Cron Jobs

```bash
# Install crontab from script
install_cron() {
    local cron_file="$1"
    crontab "$cron_file"
}

# Check if crontab exists
crontab -l &>/dev/null || echo "No crontab"

# Add job idempotently
add_cron_job() {
    local job="$1"
    (crontab -l 2>/dev/null | grep -F "$job") && return 0  # exists
    (crontab -l 2>/dev/null; echo "$job") | crontab -
}

add_cron_job "0 2 * * * /opt/scripts/backup.sh >> /var/log/backup.log 2>&1"
```

## Package Management

```bash
# Debian/Ubuntu
apt update
apt install -y nginx
apt remove -y nginx
apt autoremove -y

# RHEL/Fedora
dnf install -y nginx
dnf remove -y nginx
dnf autoremove -y

# Check if package installed
dpkg -s nginx &>/dev/null && echo "installed"
rpm -q nginx &>/dev/null && echo "installed"

# List files from package
dpkg -L nginx
rpm -ql nginx
```

## Sysctl / Kernel Parameters

```bash
# Network tuning (common for servers)
cat >> /etc/sysctl.d/99-network.conf << 'EOF'
net.core.somaxconn = 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65535
EOF

sysctl -p /etc/sysctl.d/99-network.conf
```

## Log Management

```bash
# journalctl — query systemd journal
journalctl -u nginx                       # service logs
journalctl -p err -b                      # errors since boot
journalctl --since "yesterday"            # time range
journalctl -n 50                          # last 50 lines
journalctl -f                             # follow

# Clear old logs
journalctl --vacuum-time=7d               # keep last 7 days
journalctl --vacuum-size=500M             # keep <500MB

# Configure journal size limit
# /etc/systemd/journald.conf:
# SystemMaxUse=500M
```
