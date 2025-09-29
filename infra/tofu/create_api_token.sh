#!/bin/bash
# Script to create Proxmox API token for Terraform/OpenTofu

# SSH into Proxmox and create API token
echo "Creating API token for Terraform/OpenTofu..."
echo "Please run these commands on your Proxmox server:"
echo ""
echo "# Create user for Terraform (if not exists)"
echo "pveum user add terraform@pve --password 'TerraformUser123!'"
echo ""
echo "# Create API token"
echo "pveum user token add terraform@pve terraform-token --privsep 0"
echo ""
echo "# Grant full permissions to the user"
echo "pveum aclmod / -user terraform@pve -role Administrator"
echo ""
echo "Save the token secret that is displayed!"
echo ""
echo "Then update terraform.tfvars with:"
echo "pm_user = \"terraform@pve!terraform-token\""
echo "pm_password = \"<token-secret>\""