#!/usr/bin/env bash
set -euo pipefail

BOX_NAME="centos-stream-10-base"
BOX_FILE="${BOX_NAME}.box"

echo "==> Bringing up VM and running provisioner..."
vagrant up

echo "==> Packaging provisioned VM into ${BOX_FILE}..."
vagrant package --output "${BOX_FILE}"

echo "==> Registering ${BOX_FILE} as local box '${BOX_NAME}'..."
vagrant box add --force "${BOX_FILE}" --name "${BOX_NAME}"

echo "==> Cleaning up build VM..."
vagrant destroy --force

echo "==> Done! You can now use '${BOX_NAME}' as the box name in other projects."
