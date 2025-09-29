#!/bin/bash

# This script bypasses the provider permission check by using environment variables
# The telmate provider sometimes has issues with permission detection even for root@pam

echo "Setting Proxmox environment variables..."
export PM_API_URL="https://192.168.0.33:8006/api2/json"
export PM_USER="root@pam"
export PM_PASSWORD="sonicx555"

# Re-initialize with the environment variables
echo "Reinitializing OpenTofu..."
tofu init -upgrade

echo "Planning infrastructure..."
tofu plan -out=tfplan

echo "Review the plan above. Press Enter to apply or Ctrl+C to cancel..."
read

echo "Applying infrastructure..."
tofu apply tfplan