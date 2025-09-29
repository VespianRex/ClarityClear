# Proxmox VM Deployment Guide - SOLUTION

## Problem Resolved
The "VM.Monitor permission insufficient for root@pam" error has been resolved. This was a known issue with telmate/proxmox provider version 2.9.14.

## Working Solution

### 1. Provider Configuration (provider.tf)
The working configuration uses telmate/proxmox version 2.9.11 with minimal settings:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.11"  # Specific version without permission bug
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.pm_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = true
  pm_parallel     = 1     # Reduce parallelism for stability
  pm_timeout      = 900   # Increase timeout for large VMs
  pm_log_enable   = false # Disable logging to avoid permission checks
}
```

### 2. Main Configuration (main.tf)
- Uses template IDs directly (9000 for Debian, 9001 for Alpine)
- Full clone enabled for all VMs
- Cloud-init configured for SSH access

## Deployment Steps

### Quick Deploy
```bash
# 1. Initialize OpenTofu/Terraform
tofu init -upgrade

# 2. Review the plan
tofu plan

# 3. Apply the configuration
tofu apply -auto-approve

# 4. Get VM IPs (after they boot)
tofu output
```

### Alternative Deployment Methods

#### Method 1: Direct API Deployment (if Terraform fails)
```bash
# Use the provided script for direct API deployment
./deploy-via-api.sh
```

#### Method 2: API Token Authentication (more reliable)
```bash
# On Proxmox server, create API token:
pveum user token add root@pam terraform -expire 0 -privsep 0

# Update terraform.tfvars with:
# pm_api_token_id = "root@pam!terraform"
# pm_api_token_secret = "<token-from-above>"
```

#### Method 3: Use bpg/proxmox Provider (newer, more features)
```bash
# Copy the alternative provider configuration
cp provider-bpg.tf.example provider.tf
cp main-bpg.tf.example main.tf

# Reinitialize and deploy
tofu init -upgrade
tofu apply
```

## VM Details

| VM ID | Name         | Template | Cores | RAM   | IP Configuration    |
|-------|--------------|----------|-------|-------|-------------------|
| 200   | nfs-storage  | Debian   | 1     | 1GB   | 192.168.0.55/24  |
| 201   | edge-a       | Alpine   | 2     | 2GB   | DHCP             |
| 202   | edge-b       | Alpine   | 2     | 2GB   | DHCP             |
| 203   | clarity-app  | Debian   | 4     | 8GB   | DHCP             |
| 204   | monitoring   | Debian   | 2     | 4GB   | DHCP             |
| 205   | pbs-backup   | Debian   | 2     | 4GB   | DHCP             |

## Troubleshooting

### If deployment still fails:

1. **Check Templates Exist**
   ```bash
   # SSH to Proxmox
   qm list | grep -E "9000|9001"
   ```

2. **Verify Templates are Marked as Templates**
   ```bash
   qm config 9000 | grep template
   qm config 9001 | grep template
   ```

3. **Test API Access**
   ```bash
   ./test-proxmox-api.sh
   ```

4. **Check Permissions**
   ```bash
   ./fix-proxmox-permissions.sh
   ```

## Post-Deployment

1. **Start VMs** (if not auto-started):
   ```bash
   for vm in 200 201 202 203 204 205; do
     ssh root@192.168.0.33 "qm start $vm"
   done
   ```

2. **Get VM IPs**:
   ```bash
   ssh root@192.168.0.33 "qm guest cmd 201 network-get-interfaces"
   ```

3. **SSH Access**:
   ```bash
   # Use the configured SSH key
   ssh -i ~/.ssh/id_ed25519 VespianRex@<vm-ip>
   ```

## Files Created

- `provider.tf` - Working provider configuration
- `main.tf` - VM definitions with template IDs
- `deploy-via-api.sh` - Direct API deployment script
- `test-proxmox-api.sh` - API testing script
- `fix-proxmox-permissions.sh` - Permission diagnostic script
- `provider-bpg.tf.example` - Alternative provider (bpg/proxmox)
- `main-bpg.tf.example` - VM config for bpg provider
- `provider-token.tf.example` - Token-based authentication

## Important Notes

- Provider version 2.9.11 works without permission issues
- Version 2.9.14 has a bug with permission checking for root@pam
- Always use template IDs (9000, 9001) not names
- Cloud-init requires qemu-guest-agent in templates
- VMs will get IPs via DHCP except NFS (static 192.168.0.55)