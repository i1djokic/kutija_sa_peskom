#!/bin/bash
# Dynamic inventory script for Vagrant-managed VMs
# Usage: ansible -i scripts/vagrant-inventory.sh -m ping
#
# Supports --list and --host <hostname> Ansible inventory script interface.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SSH_CONFIG_FILE="$SCRIPT_DIR/.vagrant/ssh-config"

if [[ "${1:-}" = "--list" ]]; then
    if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
        echo '{"_meta": {"hostvars": {}}}'
        exit 0
    fi

    HOSTS=$(awk '/^Host / {print $2}' "$SSH_CONFIG_FILE" | grep -v '^\*$' | grep -v '^$' || true)

    echo '{'
    echo '  "_meta": {'
    echo '    "hostvars": {'
    first=true
    while IFS= read -r host; do
        [[ -z "$host" ]] && continue
        $first || echo ','
        first=false
        echo "      \"$host\": {"
        echo '        "ansible_user": "vagrant",'
        echo '        "ansible_python_interpreter": "/usr/bin/python3",'
        echo '        "ansible_ssh_common_args": "-F '"$SSH_CONFIG_FILE"'"'
        echo '      }'
    done <<< "$HOSTS"
    echo '    }'
    echo '  },'
    echo '  "all": {'
    echo '    "children": ['
    first=true
    while IFS= read -r host; do
        [[ -z "$host" ]] && continue
        $first || echo ','
        first=false
        echo "      \"$host\""
    done <<< "$HOSTS"
    echo '    ]'
    echo '  }'
    echo '}'

elif [[ "${1:-}" = "--host" ]]; then
    echo '{"ansible_user": "vagrant", "ansible_python_interpreter": "/usr/bin/python3", "ansible_ssh_common_args": "-F '"$SSH_CONFIG_FILE"'"}'
else
    echo "Usage: $0 --list | --host <hostname>" >&2
    exit 1
fi
