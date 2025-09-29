#!/bin/bash

# Proxmox Permission Fix Script
# This script helps diagnose and fix permission issues for Terraform/OpenTofu deployments

PROXMOX_HOST="192.168.0.33"
PROXMOX_USER="root@pam"
PROXMOX_PASS="sonicx555"

echo "====================================="
echo "Proxmox Permission Diagnostic Script"
echo "====================================="
echo ""

# Function to execute pvesh commands
execute_pvesh() {
    local cmd=$1
    sshpass -p "${PROXMOX_PASS}" ssh -o StrictHostKeyChecking=no "${PROXMOX_USER%%@*}@${PROXMOX_HOST}" "pvesh $cmd"
}

echo "1. Testing connection to Proxmox..."
if sshpass -p "${PROXMOX_PASS}" ssh -o StrictHostKeyChecking=no "${PROXMOX_USER%%@*}@${PROXMOX_HOST}" "echo 'Connection successful'" 2>/dev/null; then
    echo "   ✓ Connection successful"
else
    echo "   ✗ Connection failed. Please install sshpass: brew install hudochenkov/sshpass/sshpass"
    echo "   Or connect manually: ssh root@${PROXMOX_HOST}"
    exit 1
fi

echo ""
echo "2. Checking current user permissions..."
execute_pvesh "get /access/permissions --userid ${PROXMOX_USER}" 2>/dev/null || echo "   Unable to retrieve permissions"

echo ""
echo "3. Verifying templates exist..."
echo "   Checking for template 9000 (Debian)..."
execute_pvesh "get /nodes/prox00/qemu/9000/config" 2>/dev/null && echo "   ✓ Template 9000 exists" || echo "   ✗ Template 9000 not found"

echo "   Checking for template 9001 (Alpine)..."
execute_pvesh "get /nodes/prox00/qemu/9001/config" 2>/dev/null && echo "   ✓ Template 9001 exists" || echo "   ✗ Template 9001 not found"

echo ""
echo "4. Creating API token for Terraform (recommended approach)..."
echo "   Execute this command on the Proxmox server:"
echo ""
echo "   pveum user token add root@pam terraform -expire 0 -privsep 0"
echo ""
echo "   This will output a token ID and secret. Use these in your terraform.tfvars:"
echo "   pm_api_token_id     = \"root@pam!terraform\""
echo "   pm_api_token_secret = \"<token-secret-from-command>\""

echo ""
echo "5. Alternative: Grant explicit permissions (if not using root)..."
echo "   If using a non-root user, execute these on Proxmox:"
echo ""
echo "   pveum role create TerraformRole -privs \"VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit\""
echo "   pveum user add terraform@pve"
echo "   pveum aclmod / -user terraform@pve -role TerraformRole"

echo ""
echo "====================================="
echo "Quick Fix Steps:"
echo "====================================="
echo ""
echo "1. First, try reinitializing Terraform/OpenTofu:"
echo "   rm -rf .terraform .terraform.lock.hcl"
echo "   tofu init"
echo ""
echo "2. Update provider version in provider.tf to ~> 3.0"
echo ""
echo "3. Use template IDs (9000, 9001) directly instead of names"
echo ""
echo "4. Try with simplified configuration (main-simple.tf.example)"
echo ""
echo "5. If still failing, create API token as shown above"
echo ""