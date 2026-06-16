# VM Image Builder — Custom CentOS Stream 10 Vagrant Box for libvirt/KVM

## Why this exists

Builds a custom CentOS Stream 10 base box for use with libvirt/KVM. Useful when you need a
pre-customized base image with packages and config already baked in.

## Files

| File | Purpose |
|---|---|
| `Vagrantfile` | Build recipe — references `generic/centos-stream-10` during the build |
| `build.sh` | Orchestrates the full build: boot → provision → package → register |
| `provision.sh` | Provisioning script (updates, packages, qemu-guest-agent) |
| `Vagrantfile.use` | Usage example for projects that consume the built box |

## Usage

```bash
# Build the base box
./build.sh

# The output: centos-stream-10-base.box + registered as a local Vagrant box
```

After building, reference the custom box in any project via `Vagrantfile.use`.

## Requirements

- Linux with libvirt/KVM
- Vagrant with `vagrant-libvirt` plugin: `vagrant plugin install vagrant-libvirt`
