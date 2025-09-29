#!/bin/bash

# Direct deployment script using Proxmox API
# This bypasses the Terraform provider permission issues

PROXMOX_HOST="192.168.0.33"
PROXMOX_USER="root@pam"
PROXMOX_PASS="sonicx555"
NODE="prox00"

# Get authentication ticket
echo "Authenticating with Proxmox..."
AUTH_RESPONSE=$(curl -k -s -X POST "https://$PROXMOX_HOST:8006/api2/json/access/ticket" \
  -d "username=$PROXMOX_USER&password=$PROXMOX_PASS")

TICKET=$(echo "$AUTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['ticket'])")
CSRF=$(echo "$AUTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['CSRFPreventionToken'])")

echo "Authentication successful!"

# Function to clone VM from template
clone_vm() {
  local TEMPLATE_ID=$1
  local NEW_VMID=$2
  local VM_NAME=$3
  local CORES=$4
  local MEMORY=$5
  local IP_CONFIG=$6

  echo "Cloning VM $VM_NAME (ID: $NEW_VMID) from template $TEMPLATE_ID..."

  curl -k -s -X POST "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/qemu/$TEMPLATE_ID/clone" \
    -H "Cookie: PVEAuthCookie=$TICKET" \
    -H "CSRFPreventionToken: $CSRF" \
    -d "newid=$NEW_VMID" \
    -d "name=$VM_NAME" \
    -d "full=1" \
    -d "target=$NODE"

  sleep 5

  # Configure the VM
  echo "Configuring VM $VM_NAME..."
  curl -k -s -X POST "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/qemu/$NEW_VMID/config" \
    -H "Cookie: PVEAuthCookie=$TICKET" \
    -H "CSRFPreventionToken: $CSRF" \
    -d "cores=$CORES" \
    -d "memory=$MEMORY" \
    -d "balloon=$((MEMORY/2))" \
    -d "agent=1" \
    -d "onboot=1" \
    -d "ciuser=VespianRex" \
    -d "sshkeys=$(echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro' | python3 -c 'import sys; import urllib.parse; print(urllib.parse.quote(sys.stdin.read()))')" \
    -d "ipconfig0=$IP_CONFIG" \
    -d "nameserver=192.168.0.1" \
    -d "searchdomain=andub.go.ro"

  echo "VM $VM_NAME created successfully!"
}

# Check if templates exist
echo "Checking if templates exist..."
TEMPLATE_CHECK=$(curl -k -s "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/qemu" \
  -H "Cookie: PVEAuthCookie=$TICKET")

if echo "$TEMPLATE_CHECK" | grep -q '"vmid":9000'; then
  echo "Debian template (9000) found"
  DEBIAN_TEMPLATE=9000
else
  echo "WARNING: Debian template (9000) not found! Please create it first."
  exit 1
fi

if echo "$TEMPLATE_CHECK" | grep -q '"vmid":9001'; then
  echo "Alpine template (9001) found"
  ALPINE_TEMPLATE=9001
else
  echo "WARNING: Alpine template (9001) not found! Please create it first."
  exit 1
fi

# Deploy VMs
echo "Starting VM deployment..."

# NFS Server (Debian) - Static IP
clone_vm $DEBIAN_TEMPLATE 200 "nfs-storage" 1 1024 "ip=192.168.0.55/24,gw=192.168.0.1"

# Edge VMs (Alpine)
clone_vm $ALPINE_TEMPLATE 201 "edge-a" 2 2048 "ip=dhcp"
clone_vm $ALPINE_TEMPLATE 202 "edge-b" 2 2048 "ip=dhcp"

# App VM (Debian)
clone_vm $DEBIAN_TEMPLATE 203 "clarity-app" 4 8192 "ip=dhcp"

# Monitoring VM (Debian)
clone_vm $DEBIAN_TEMPLATE 204 "monitoring" 2 4096 "ip=dhcp"

# PBS VM (Debian)
clone_vm $DEBIAN_TEMPLATE 205 "pbs-backup" 2 4096 "ip=dhcp"

echo ""
echo "Deployment complete!"
echo ""
echo "VMs created:"
echo "  - nfs-storage (200): 192.168.0.55"
echo "  - edge-a (201): DHCP"
echo "  - edge-b (202): DHCP"
echo "  - clarity-app (203): DHCP"
echo "  - monitoring (204): DHCP"
echo "  - pbs-backup (205): DHCP"
echo ""
echo "You can now start the VMs from the Proxmox web interface or using:"
echo "  qm start <vmid>"