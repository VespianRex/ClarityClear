#!/bin/bash

# This script should be run on the Proxmox server to set up proper permissions
# SSH to your Proxmox server (192.168.0.33) and run these commands

cat << 'EOF'
# Run these commands on your Proxmox server as root:

# Option 1: Fix root@pam permissions (if somehow limited)
pveum acl modify / -user root@pam -role Administrator

# Option 2: Create a dedicated user with API token (recommended)
# Create user
pveum user add terraform@pve --comment "Terraform/OpenTofu automation user"

# Create API token (this will output the token secret - save it!)
pveum user token add terraform@pve terraform-token --privsep 0

# Grant full Administrator role to the user
pveum acl modify / -user terraform@pve -role Administrator

# Alternatively, grant specific permissions needed:
# pveum role create TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt Datastore.AllocateSpace Datastore.Allocate Sys.Modify Pool.Allocate"
# pveum acl modify / -user terraform@pve -role TerraformRole

echo "After running these commands, update your terraform.tfvars with:"
echo 'pm_user = "terraform@pve!terraform-token"'
echo 'pm_password = "<the-token-secret-from-above>"'
EOF