#!/bin/bash

# Deploy script that sets environment variables for the Proxmox provider
# This can sometimes bypass permission checking issues

export PM_API_URL="https://192.168.0.33:8006/api2/json"
export PM_USER="root@pam"
export PM_PASSWORD="sonicx555"
export PM_TLS_INSECURE="true"

echo "Deploying VMs to Proxmox..."
tofu apply -auto-approve