# Configuration Drift Detection

## Hash-Based Baseline

```bash
# Create baseline of all .conf files
BASELINE_FILE="/etc/baseline.sha256"

create_baseline() {
    find /etc/ -type f \( -name "*.conf" -o -name "*.yml" -o -name "*.yaml" \) \
        -exec sha256sum {} \; | sort > "$BASELINE_FILE"
    echo "Baseline created: $BASELINE_FILE"
}

check_drift() {
    local baseline="$1" current
    current=$(mktemp)
    trap 'rm -f "$current"' RETURN

    find /etc/ -type f \( -name "*.conf" -o -name "*.yml" -o -name "*.yaml" \) \
        -exec sha256sum {} \; | sort > "$current"

    if ! diff -q "$baseline" "$current" &>/dev/null; then
        echo "Configuration drift detected!"
        diff "$baseline" "$current"
        return 1
    fi
    echo "No drift detected"
}

# First run: create baseline
# Subsequent: check for drift
if [[ ! -f "$BASELINE_FILE" ]]; then
    create_baseline
else
    check_drift "$BASELINE_FILE"
fi
```

## Permissions Audit

```bash
# Track file permissions
audit_permissions() {
    local baseline="$1" current
    current=$(mktemp)
    trap 'rm -f "$current"' RETURN

    find /etc/ -type f -printf '%m %u %g %p\n' | sort > "$current"

    if ! diff -q "$baseline" "$current" &>/dev/null; then
        echo "Permission drift detected!"
        diff "$baseline" "$current"
        return 1
    fi
}

# Check for world-writable files (security concern)
find /etc/ -perm -o+w -type f -exec ls -la {} \;
```

## Package Audit

```bash
# Track installed packages
# Debian/Ubuntu
dpkg --get-selections | sort > /var/lib/audit/packages.baseline

# Check for new/removed packages
diff /var/lib/audit/packages.baseline <(dpkg --get-selections | sort)

# RHEL/Fedora
rpm -qa --queryformat '%{NAME} %{VERSION}\n' | sort > /var/lib/audit/packages.baseline

# Check for unauthorized packages
comm -13 <(sort allowed_packages.txt) <(rpm -qa --queryformat '%{NAME}\n' | sort)
```

## Systemd Service Audit

```bash
# Track enabled services
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' | sort

# Detect new enabled services
diff <(cat /var/lib/audit/enabled.baseline) <(systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' | sort)
```

## Dridef Detection Script (All-in-One)

```bash
#!/bin/bash
set -euo pipefail

AUDIT_DIR="/var/lib/audit"
mkdir -p "$AUDIT_DIR"

drift_check() {
    local name="$1" cmd="$2"
    local baseline="$AUDIT_DIR/${name}.baseline"
    local current
    current=$(mktemp)
    trap 'rm -f "$current"' RETURN

    eval "$cmd" > "$current"

    if [[ ! -f "$baseline" ]]; then
        cp "$current" "$baseline"
        echo "[$name] Baseline created"
    elif ! diff -q "$baseline" "$current" &>/dev/null; then
        echo "[$name] DRIFT DETECTED:"
        diff "$baseline" "$current" || true
        return 1
    else
        echo "[$name] OK"
    fi
}

# Usage
drift_check "packages"  "dpkg --get-selections | sort"
drift_check "crontab"   "crontab -l 2>/dev/null || echo '(no crontab)'"
drift_check "services"  "systemctl list-unit-files --state=enabled --no-legend | awk '{print \$1}' | sort"
drift_check "ssh_config" "sha256sum /etc/ssh/sshd_config"
```
