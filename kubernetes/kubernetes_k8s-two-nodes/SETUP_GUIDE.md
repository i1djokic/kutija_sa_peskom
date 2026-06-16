# Kubernetes Cluster Setup Guide — UTM + Vagrant

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      macOS Host                              │
│                                                              │
│   ┌────────────────────┐    ┌────────────────────┐          │
│   │   Master Node      │    │   Worker Node      │          │
│   │   k8s-master       │    │   k8s-worker       │          │
│   │   192.168.64.10    │◄──►│   192.168.64.11    │          │
│   │                    │    │                    │          │
│   │   ┌──────────────┐ │    │   ┌──────────────┐ │          │
│   │   │  kube-apiserver│ │    │   │   kubelet   │ │          │
│   │   │  etcd         │ │    │   │   kube-proxy │ │          │
│   │   │  kube-scheduler│ │    │   │   containerd│ │          │
│   │   │  kube-controller│ │    │   └──────────────┘ │          │
│   │   │  containerd   │ │    │                      │          │
│   │   │  Calico CNI   │ │    │                      │          │
│   │   └──────────────┘ │    │                      │          │
│   └────────────────────┘    └──────────────────────┘          │
│                                                              │
│   Both VMs on macOS Shared Network (192.168.64.0/24)         │
│   Internet access via NAT  ◄────► Inter-VM communication     │
└──────────────────────────────────────────────────────────────┘
```

Both VMs use a single NIC on **macOS Shared Network** — this is a virtual VLAN managed by macOS's `vmnet` framework. It provides:
- **NAT** for internet access (package downloads, etc.)
- **Inter-VM communication** (all VMs on the same VLAN)
- **Host-VM communication** (reachable from your Mac)

---

## Prerequisites

- Apple Silicon Mac (M1/M2/M3/M4)
- macOS Ventura or later
- 8+ GB RAM (4 GB for master, 2 GB for worker)

## Step 1: Install Dependencies

```bash
# Install UTM (free VM manager)
brew install --cask utm

# Install Vagrant
brew install vagrant

# Install the UTM provider plugin for Vagrant
vagrant plugin install vagrant_utm

# Start the cluster
vagrant up --provider=utm
```

Or use the automated script:
```bash
chmod +x setup-macos.sh
./setup-macos.sh
```

First boot takes ~10-15 minutes to download the Rocky Linux box and provision both VMs.

## Step 2: Verify the VMs are Running

```bash
vagrant status
```

Expected output:
```
Current machine states:

master                    running (utm)
worker                    running (utm)
```

## Step 3: Initialize the Cluster

The master node is **automatically initialized** during provisioning (`provision.sh`). SSH in to check:

```bash
vagrant ssh master
```

Inside the master node, check if Kubernetes is ready:

```bash
# Check nodes (should show master as Ready after Calico starts)
kubectl get nodes

# Check all pods (may take 1-2 minutes for Calico to fully start)
kubectl get pods -A
```

If you see `NotReady`, wait for Calico to finish:
```bash
kubectl get pods -n kube-system -w
```

## Step 4: Get the Join Command

From the master node, generate a token for the worker:

```bash
kubeadm token create --print-join-command
```

This outputs something like:
```
kubeadm join 192.168.64.10:6443 --token xxxxxx.xxxxxx --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Copy this full command.

## Step 5: Join the Worker Node

In a **separate terminal**, SSH into the worker:

```bash
vagrant ssh worker
```

Paste the join command from Step 4:

```bash
kubeadm join 192.168.64.10:6443 --token xxxxxx.xxxxxx --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Expected output:
```
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.
```

## Step 6: Verify the Cluster

Back in the **master** SSH session:

```bash
kubectl get nodes
```

Expected:
```
NAME          STATUS   ROLES           AGE   VERSION
k8s-master    Ready    control-plane   5m    v1.30.0
k8s-worker    Ready    <none>          1m    v1.30.0
```

Both should show `Ready`. If worker shows `NotReady`, wait 30s and check again (Calico needs to set up networking on the new node).

Check all system pods:
```bash
kubectl get pods -A
```

All pods should show `Running`.

## Quick Commands Reference

```bash
# Start cluster
vagrant up --provider=utm

# Stop cluster (preserve VMs)
vagrant halt

# Destroy cluster (delete VMs)
vagrant destroy -f

# Re-run provisioning on running VMs
vagrant provision

# SSH into master
vagrant ssh master

# SSH into worker
vagrant ssh worker

# Check VM status
vagrant status
```

## Troubleshooting

### Worker stays NotReady

```bash
kubectl describe node k8s-worker
```

Check the worker's kubelet logs:
```bash
sudo journalctl -u kubelet -f
```

### IP conflict (wrong IP assigned)

Check what IP the VM actually has:
```bash
ip addr show
```

If the IP is not `192.168.64.10` (master) or `192.168.64.11` (worker), the NetworkManager config may have failed. Check:
```bash
nmcli connection show
sudo nmcli connection modify "Wired" ipv4.addresses 192.168.64.10/24
sudo nmcli connection up "Wired"
```

### Master init fails

If `kubeadm init` fails, reset and retry:
```bash
sudo kubeadm reset -f
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.64.10
```

### Re-provision from scratch

```bash
vagrant destroy -f && vagrant up --provider=utm
```

### Cluster communication issues

Ensure the VMs can reach each other:
```bash
# From master
ping 192.168.64.11

# From worker
ping 192.168.64.10
```

If ping fails, the macOS Shared Network VLAN is broken — check UTM settings.
