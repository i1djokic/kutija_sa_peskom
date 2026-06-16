# List Running VMs

## Via libvirt (virsh)

List all running domains (VMs):

```bash
virsh -c qemu:///system list
```

List all domains (including stopped):

```bash
virsh -c qemu:///system list --all
```

The `-c qemu:///system` flag uses the system libvirt daemon (configured for your user via the `libvirt` group).

## Via Vagrant

From a Vagrant project directory:

```bash
vagrant status
```

## Common aliases

Add to `~/.bashrc` for convenience:

```bash
alias vms='virsh -c qemu:///system list --all'
```
