# Proxmox VM Deployment Workaround

The telmate/proxmox provider has a known issue with permission checking that incorrectly reports missing VM.Monitor permission even for root@pam users. Here are the solutions:

## Option 1: Create API Token (Recommended)

SSH to your Proxmox server (192.168.0.33) and run:

```bash
# Create a dedicated Terraform user
pveum user add terraform@pve --comment "Terraform automation"

# Create an API token (SAVE THE OUTPUT TOKEN!)
pveum user token add terraform@pve terraform-token --privsep 0

# Grant Administrator role
pveum acl modify / -user terraform@pve -role Administrator
```

Then update `terraform.tfvars`:
```hcl
pm_user = "terraform@pve!terraform-token"
pm_password = "<token-from-above>"
```

## Option 2: Direct API Deployment

Use the Proxmox API directly to create VMs. Script available in `direct_deploy.sh`.

## Option 3: Use Alternative Provider

Switch to the bpg/proxmox provider which has better permission handling:

```bash
# Update provider.tf to use bpg/proxmox
# Then run:
tofu init -upgrade
tofu apply
```

## Option 4: Manual Template Fix

The issue might be that templates 9000 and 9001 don't exist. Create them:

```bash
# On Proxmox server, create templates from existing VMs or cloud images:
qm create 9000 --name debian-template --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 debian-12-generic-amd64.qcow2 local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000

# Similar for Alpine template with ID 9001
```

## Current VM Configuration

The infrastructure includes:
- **NFS VM** (200): 192.168.0.55 - Storage server
- **Edge A VM** (201): Load balancer primary
- **Edge B VM** (202): Load balancer secondary
- **App VM** (203): Application server
- **Monitoring VM** (204): Prometheus/Grafana
- **PBS VM** (205): Proxmox Backup Server

All VMs are configured with:
- Cloud-init for SSH key injection
- QEMU guest agent
- VirtIO network and disk drivers
- Proper memory ballooning