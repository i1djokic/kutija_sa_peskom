# Vagrant with UTM - Quick Reference

## Brief Description
Vagrant is a tool for building/managing VM environments. It uses providers (like UTM for macOS) to automate VM workflows. This guide focuses on UTM (`vagrant_utm` plugin) with `utm/bookworm` box.

## Basic Commands
Commands for UTM (use `--provider=utm` with `up`/`reload` to specify provider):
```bash
vagrant up --provider=utm  # Start VMs with UTM provider
vagrant reload --provider=utm  # Reload with UTM provider
vagrant ssh                 # Connect to VM
vagrant status              # Check VM status
vagrant halt                # Stop VMs
vagrant destroy -f          # Delete VMs (irreversible)
vagrant ssh-config         # View SSH settings
```

**Tip:** Set `export VAGRANT_DEFAULT_PROVIDER=utm` to avoid typing `--provider=utm` each time.

## Configuring Synced Folders (Host ↔ VM)
Mount local macOS directories to VM with `config.vm.synced_folder` in Vagrantfile:

### Basic Syntax
```ruby
config.vm.synced_folder "HOST_PATH", "VM_PATH"
```

### Examples
1. **Default Vagrant mount** (host `.` → VM `/vagrant`):
```ruby
config.vm.synced_folder ".", "/vagrant", disabled: false
```

2. **Custom folder mount** (host `./projects` → VM `/home/vagrant/projects`):
```ruby
config.vm.synced_folder "./projects", "/home/vagrant/projects"
```

3. **Read-only mount**:
```ruby
config.vm.synced_folder "./data", "/data", mount_options: ["ro"]
```

4. **Disable synced folders**:
```ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
```

### UTM-Specific Notes
- `vagrant_utm` uses SSHFS for synced folders
- Ensure `sshfs` is installed in VM (add to `provision.sh`):
  ```bash
  apt install -y sshfs
  ```

### Full Example Vagrantfile
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "utm/bookworm"
  config.vm.hostname = "example-vm"

  config.vm.provider "utm" do |v|
    v.name = "example-vm"
    v.memory = 2048
    v.cpus = 1
  end

  # Mount host ./src to VM /home/vagrant/src
  config.vm.synced_folder "./src", "/home/vagrant/src"
  # Default Vagrant mount (host . → VM /vagrant)
  config.vm.synced_folder ".", "/vagrant", disabled: false
end
```

## Cleaning Up the Vagrant Environment

### Stop VMs (Keep State)
```bash
vagrant halt                # Stop all VMs gracefully
vagrant halt <vm-name>     # Stop specific VM
```

### Destroy VMs (Remove VMs)
```bash
vagrant destroy             # Destroy all VMs (keeps box image)
vagrant destroy -f          # Force destroy without confirmation
vagrant destroy <vm-name>  # Destroy specific VM
```

### Remove Box Images
```bash
vagrant box list           # List installed boxes
vagrant box remove utm/bookworm  # Remove a specific box
```

### Full Cleanup (Start Fresh)
```bash
# 1. Destroy VMs
vagrant destroy -f

# 2. Remove box image (optional, frees disk space)
vagrant box remove utm/bookworm

# 3. Remove Vagrant metadata (inside project folder)
rm -rf .vagrant/

# 4. Remove project files (if deleting entire project)
cd ..
rm -rf <project-folder>
```

### UTM-Specific Cleanup
Vagrant destroy may not always remove UTM VMs completely. Verify:
```bash
open -a UTM               # Check UTM app for leftover VMs
utmctl list               # List UTM VMs via CLI
utmctl stop <vm-name>     # Stop VM in UTM
utmctl delete <vm-name>   # Delete VM in UTM (irreversible)
```

### Cleanup Checklist
- [ ] `vagrant destroy -f` (destroys VMs)
- [ ] `rm -rf .vagrant/` (removes project state)
- [ ] `vagrant box remove <box-name>` (frees disk space, optional)
- [ ] Verify no leftover VMs in UTM app
- [ ] Delete project folder if no longer needed

## Resources
- Vagrant Docs: https://www.vagrantup.com/docs
- vagrant_utm: https://github.com/utmapp/vagrant-utm
