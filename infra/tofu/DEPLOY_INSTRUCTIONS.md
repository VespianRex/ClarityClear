# Deployment Instructions for Proxmox VMs

## The Issue
The telmate/proxmox Terraform provider has a known bug where it incorrectly reports missing `VM.Monitor` permissions even for `root@pam` users. This is a false positive - the root user has all permissions.

## Verified Configuration
- **Proxmox Node**: `prox00` (not `pve`)
- **Storage**: `local-lvm` (exists and accessible)
- **Templates**:
  - VM 9000: `debian12-cloud` (Debian template)
  - VM 9001: `alpine-cloud` (Alpine template)
- **API Endpoint**: `https://192.168.0.33:8006/api2/json`
- **Authentication**: `root@pam` with password

## Solutions

### Option 1: Direct API Deployment (Recommended)
Use the provided script to deploy VMs directly via the Proxmox API:

```bash
./direct_deploy.sh
```

This will create:
- **VM 200**: `nfs-storage` - NFS server at 192.168.0.55
- **VM 201**: `edge-a` - Edge/Load balancer A (Alpine)
- **VM 202**: `edge-b` - Edge/Load balancer B (Alpine)
- **VM 203**: `clarity-app` - Application server (Debian)
- **VM 204**: `monitoring` - Monitoring stack (Debian)
- **VM 205**: `pbs-backup` - Proxmox Backup Server (Debian)

### Option 2: Create API Token
SSH to your Proxmox server and create an API token:

```bash
# On Proxmox server (192.168.0.33)
pveum user add terraform@pve
pveum user token add terraform@pve terraform-token --privsep 0
pveum acl modify / -user terraform@pve -role Administrator
```

Then update `terraform.tfvars`:
```hcl
pm_user = "terraform@pve!terraform-token"
pm_password = "<token-secret-from-above>"
```

### Option 3: Manual VM Creation
Create VMs manually in Proxmox UI by cloning the templates with these specs:

#### NFS Storage (VM 200)
- Clone from: debian12-cloud (9000)
- Name: nfs-storage
- Cores: 1, RAM: 1GB
- IP: 192.168.0.55/24
- SSH Key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO

#### Edge VMs (201-202)
- Clone from: alpine-cloud (9001)
- Names: edge-a, edge-b
- Cores: 2, RAM: 2GB each
- IP: DHCP
- SSH Key: (same as above)

#### App VM (203)
- Clone from: debian12-cloud (9000)
- Name: clarity-app
- Cores: 4, RAM: 8GB
- IP: DHCP
- SSH Key: (same as above)

#### Monitoring (204)
- Clone from: debian12-cloud (9000)
- Name: monitoring
- Cores: 2, RAM: 4GB
- IP: DHCP
- SSH Key: (same as above)

#### PBS Backup (205)
- Clone from: debian12-cloud (9000)
- Name: pbs-backup
- Cores: 2, RAM: 4GB
- IP: DHCP
- SSH Key: (same as above)

## Post-Deployment
After VMs are created:
1. Start all VMs
2. Verify SSH access with user `VespianRex`
3. Configure static IPs if needed
4. Set up NFS exports on VM 200
5. Configure edge load balancers
6. Deploy applications

## Files Provided
- `main.tf` - OpenTofu configuration (blocked by provider bug)
- `direct_deploy.sh` - Direct API deployment script
- `setup_proxmox_permissions.sh` - Instructions for API token setup
- `test_provider.sh` - API connectivity test
- `terraform.tfvars` - Variable configuration