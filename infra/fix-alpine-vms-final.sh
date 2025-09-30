#!/bin/bash
set -euo pipefail

echo "🔧 Final fix for Alpine VMs - recreating with Debian instead for edge services"
echo "Since Alpine is giving us issues, let's use Debian for the edge VMs too"

ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📋 Stopping and removing problematic Alpine VMs..."
for vmid in 201 202; do
    echo "Removing VM $vmid..."
    qm stop $vmid 2>/dev/null || true
    sleep 2
    qm destroy $vmid 2>/dev/null || true
done

echo "🏗️ Creating new Edge VMs using Debian template..."

# Function to create VM with static IP
create_edge_vm() {
    local vmid=$1
    local name=$2
    local ip_address=$3

    echo "Creating Edge VM $vmid ($name) with IP $ip_address..."

    # Clone from Debian template
    qm clone 9000 $vmid --name $name --full

    # Configure VM with static IP
    qm set $vmid \
        --cores 2 \
        --memory 2048 \
        --balloon 1024 \
        --agent 1 \
        --onboot 1 \
        --ciuser VespianRex \
        --cipassword "${ADMIN_PASSWORD:-ChangeMe}" \
        --ipconfig0 "ip=$ip_address/24,gw=192.168.0.1" \
        --nameserver "8.8.8.8" \
        --searchdomain "andub.go.ro" \
        --sshkeys /tmp/ssh_key.pub

    # Resize disk
    qm resize $vmid scsi0 10G

    echo "✅ VM $vmid ($name) created with IP $ip_address"
}

# Create SSH key file
cat > /tmp/ssh_key.pub << 'KEYEOF'
${SSH_PUBKEY}
KEYEOF

echo "🔨 Creating Debian-based Edge VMs..."

# Create Edge VMs with their expected static IPs
create_edge_vm 201 "edge-a-debian" "192.168.0.163"
create_edge_vm 202 "edge-b-debian" "192.168.0.236"

echo "🚀 Starting Edge VMs..."

for vmid in 201 202; do
    echo "Starting VM $vmid..."
    qm start $vmid
done

echo "⏳ Waiting 60 seconds for VMs to boot..."
sleep 60

echo "📋 VM status:"
qm list | grep -E "(VMID|201|202)"

echo "🎉 Edge VMs recreated with Debian!"

ENDSSH

echo "Testing SSH access to new Edge VMs..."
sleep 30

for ip in 192.168.0.163 192.168.0.236; do
  echo "Testing SSH to $ip..."
  if timeout 10 ssh -i ~/.ssh/id_ed25519_clarity -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null VespianRex@$ip 'hostname' 2>/dev/null; then
    echo "✅ $ip - SSH working"
  else
    echo "❌ $ip - SSH not ready yet"
  fi
done
