#!/usr/bin/env bash
set -euo pipefail

dnf update -y

dnf install -y \
  qemu-guest-agent \
  git \
  curl \
  wget \
  vim \
  net-tools \
  bind-utils

systemctl enable qemu-guest-agent --now

dnf clean all
