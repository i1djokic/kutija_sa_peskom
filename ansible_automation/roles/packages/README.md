# Packages Role

Installs and manages system packages.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `base_packages` | `[vim, htop, curl, ...]` | Base packages to install |
| `extra_packages` | `[]` | Additional packages |
| `dev_packages` | OS-dependent | Development packages |
| `remove_packages` | `[]` | Packages to remove |
| `install_dev_packages` | `false` | Install dev packages toggle |
| `upgrade_system` | `false` | Upgrade all packages toggle |

## Dependencies

None.
