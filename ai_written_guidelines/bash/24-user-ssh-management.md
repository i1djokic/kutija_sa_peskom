# User & SSH Key Management

## Create User with SSH Key

```bash
#!/bin/bash
set -euo pipefail

create_user() {
    local user="$1" key="$2" shell="${3:-/bin/bash}"

    # Create user if not exists (idempotent)
    if ! id "$user" &>/dev/null; then
        useradd -m -s "$shell" "$user"
        echo "Created user: $user"
    fi

    # Set up SSH
    ssh_dir="/home/$user/.ssh"
    mkdir -p "$ssh_dir"
    echo "$key" > "$ssh_dir/authorized_keys"

    # Secure permissions
    chown -R "$user:" "$ssh_dir"
    chmod 700 "$ssh_dir"
    chmod 600 "$ssh_dir/authorized_keys"

    # Lock password (SSH key only)
    passwd -l "$user" &>/dev/null || true

    echo "SSH key installed for $user"
}

# Usage
create_user "deploy" "ssh-ed25519 AAAAC3... user@host"
```

## Batch User Creation from File

```bash
# users.csv format: username,ssh_key,groups
# deploy,ssh-ed25519 AAA...,sudo
# monitor,ssh-rsa AAA...,ops

while IFS=',' read -r username key groups; do
    [[ -z "$username" || "$username" =~ ^# ]] && continue

    useradd -m -s /bin/bash "$username"

    # Add to groups
    if [[ -n "$groups" ]]; then
        IFS=' ' read -ra group_list <<< "$groups"
        for group in "${group_list[@]}"; do
            usermod -aG "$group" "$username"
        done
    fi

    # Install SSH key
    mkdir -p "/home/$username/.ssh"
    echo "$key" > "/home/$username/.ssh/authorized_keys"
    chown -R "$username:" "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    chmod 600 "/home/$username/.ssh/authorized_keys"
done < users.csv
```

## SSH Hardening

```bash
# /etc/ssh/sshd_config hardening
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config

# Apply
systemctl reload sshd

# Allow specific users only
echo "AllowUsers deploy admin" >> /etc/ssh/sshd_config
```

## Sudoers Management

```bash
# Add sudo access
echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx" > /etc/sudoers.d/deploy-nginx
chmod 440 /etc/sudoers.d/deploy-nginx

# Validate before applying
visudo -c -f /etc/sudoers.d/deploy-nginx
```

## User Cleanup

```bash
# Remove users who haven't logged in for 90+ days
lastlog -b 90 | tail -n +2 | awk '{print $1}' | while read -r user; do
    # Skip system users
    if [[ "$(id -u "$user")" -ge 1000 ]]; then
        userdel -r "$user"
        echo "Removed inactive user: $user"
    fi
done
```

## SSH Key Rotation

```bash
# Deploy new SSH key while keeping old one for rollback
deploy_key() {
    local user="$1" new_key="$2"
    local auth="/home/$user/.ssh/authorized_keys"

    # Backup current
    cp "$auth" "${auth}.bak-$(date +%Y%m%d)"

    # Prepend new key
    { echo "$new_key"; cat "${auth}.bak-$(date +%Y%m%d)"; } > "$auth.new"
    mv "$auth.new" "$auth"

    # Keep last 2 backups
    ls -t "${auth}.bak-"* | tail -n +3 | xargs -r rm -f
}
```
