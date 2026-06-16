# Vagrant VM Providers by Platform

## Recommended Provider Per OS

| Platform | Recommended Provider | Provider String | Box Format | Notes |
|----------|-------------------|-----------------|------------|-------|
| **Linux** | libvirt (KVM/QEMU) | `"libvirt"` | `generic/<dist>` | Best performance; native Linux virtualization |
| **macOS (Apple Silicon)** | UTM | `"utm"` | `utm/<dist>` | Only option for M1/M2/M3 native; uses `vagrant-utm` plugin |
| **macOS (Intel)** | VirtualBox | `"virtualbox"` | `generic/<dist>` | Works well; or use Parallels if licensed |
| **Windows** | Hyper-V | `"hyperv"` | `generic/<dist>` | Built-in on Windows Pro/Enterprise; enable via "Turn Windows features on/off" |
| **Any OS** | VirtualBox | `"virtualbox"` | `generic/<dist>` | Cross-platform fallback; slower than native options |

## Quick Setup

### Linux – libvirt
```bash
sudo apt install libvirt-dev qemu libvirt-daemon-system virt-manager
vagrant plugin install vagrant-libvirt
```

### macOS – UTM (Apple Silicon)
```bash
brew install utm
vagrant plugin install vagrant-utm
```

### macOS – VirtualBox (Intel)
```bash
brew install --cask virtualbox
```

### Windows – Hyper-V
Enable via PowerShell as Admin:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### Any OS – VirtualBox
Download from https://www.virtualbox.org or use system package manager.

## Vagrantfile Example (Multi-Provider)

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian12"
  config.vm.hostname = "dev-vm"

  # Linux: libvirt (KVM)
  config.vm.provider "libvirt" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # macOS Apple Silicon: UTM
  config.vm.provider "utm" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # macOS Intel / Windows / fallback: VirtualBox
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # Windows: Hyper-V
  config.vm.provider "hyperv" do |v|
    v.memory = 2048
    v.cpus = 2
  end
end
```

## Running with a Specific Provider

```bash
vagrant up --provider=libvirt    # Linux
vagrant up --provider=utm        # macOS Apple Silicon
vagrant up --provider=virtualbox # Any OS
vagrant up --provider=hyperv     # Windows
```

Or set the default:
```bash
export VAGRANT_DEFAULT_PROVIDER=libvirt   # Linux
export VAGRANT_DEFAULT_PROVIDER=utm       # macOS
```

## Provider Comparison

| Feature | libvirt | UTM | VirtualBox | Hyper-V |
|---------|---------|-----|------------|---------|
| Apple Silicon | ❌ | ✅ | ❌ | ❌ |
| Intel Mac | ✅ (via QEMU) | ✅ | ✅ | ❌ |
| Linux | ✅ native | ❌ | ✅ | ❌ |
| Windows (Pro+) | ❌ | ❌ | ✅ | ✅ native |
| Performance | ★★★ | ★★★ | ★★ | ★★★ |
| Ease of setup | ★★ | ★★ | ★★★ | ★★ |
| Synced folders | 9p/virtfs | SSHFS | VB Guest Additions | SMB |

## Box Repositories

- **generic/<dist>** – https://app.vagrantup.com/generic (libvirt, virtualbox, hyperv)
- **utm/<dist>** – https://app.vagrantup.com/utm (UTM only)
- **debian/bookworm**, **ubuntu/jammy64** – Official distro boxes (virtualbox only)

## Notes

- **VirtualBox** is the safest fallback but has no Apple Silicon support and lower I/O performance.
- **libvirt** is the fastest option on Linux; install the `vagrant-libvirt` plugin.
- **UTM** is the only native option for Apple Silicon Macs; requires the `vagrant-utm` plugin.
- **Hyper-V** is Windows-native but requires Pro/Enterprise edition and disables other hypervisors.
