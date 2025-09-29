#!/bin/bash
set -euo pipefail

echo "🔧 Recreating VMs with fixed cloud-init and static IPs..."

# Load environment variables
source /Users/alex/DEV/ClarityClear/infra/.env

# SSH to Proxmox and recreate VMs with proper configuration
ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📋 Stopping and removing existing VMs..."
for vmid in 200 201 202 203 204 205; do
    echo "Removing VM $vmid..."
    qm stop $vmid 2>/dev/null || true
    sleep 2
    qm destroy $vmid 2>/dev/null || true
done

echo "📋 Creating cloud-init snippets with static IP configuration..."

# Create Alpine cloud-init snippet with static IP
cat > /var/lib/vz/snippets/alpine-static.yaml << 'ALPINECFG'
#cloud-config
hostname: alpine-vm
manage_etc_hosts: true

users:
  - name: VespianRex
    groups: [wheel]
    lock_passwd: false
    passwd: $6$salt$3hFtqz6t4z.1JK8lP/1qRFP6qYvlQz9VyHHqPBp0sJpQJmfMBOhKLz3V7Mx6FnGw.gqXH.5kMYdQPzKUqjHfC0
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/ash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro

package_update: true
packages:
  - openssh
  - openssh-server
  - sudo
  - qemu-guest-agent

runcmd:
  - rc-update add sshd default
  - rc-update add qemu-guest-agent default
  - rc-service sshd start
  - rc-service qemu-guest-agent start
ALPINECFG

# Create Debian cloud-init snippet with static IP
cat > /var/lib/vz/snippets/debian-static.yaml << 'DEBIANCFG'
#cloud-config
hostname: debian-vm
manage_etc_hosts: true

users:
  - name: VespianRex
    groups: [sudo]
    lock_passwd: false
    passwd: $6$salt$3hFtqz6t4z.1JK8lP/1qRFP6qYvlQz9VyHHqPBp0sJpQJmfMBOhKLz3V7Mx6FnGw.gqXH.5kMYdQPzKUqjHfC0
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro

package_update: true
packages:
  - qemu-guest-agent
  - openssh-server
  - sudo

runcmd:
  - systemctl enable ssh
  - systemctl start ssh
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
DEBIANCFG

echo "🏗️ Creating VMs with static IP configuration..."

# Function to create VM with static IP
create_vm_static() {
    local vmid=$1
    local name=$2
    local template=$3
    local cores=$4
    local memory=$5
    local disk_size=$6
    local config_snippet=$7
    local ip_address=$8

    echo "Creating VM $vmid ($name) with IP $ip_address..."

    # Clone from template
    qm clone $template $vmid --name $name --full

    # Configure VM with static IP
    qm set $vmid \
        --cores $cores \
        --memory $memory \
        --balloon $((memory/2)) \
        --agent 1 \
        --onboot 1 \
        --ciuser VespianRex \
        --cipassword "ClarityInfra2025!" \
        --ipconfig0 "ip=$ip_address/24,gw=192.168.0.1" \
        --nameserver "8.8.8.8" \
        --searchdomain "andub.go.ro" \
        --cicustom "user=local:snippets/$config_snippet"

    # Resize disk
    qm resize $vmid scsi0 ${disk_size}G

    echo "✅ VM $vmid ($name) created with IP $ip_address"
}

echo "🔨 Creating all VMs with static IPs..."

# Create VMs with their expected static IPs
create_vm_static 200 "backup-storage" 9000 2 4096 20 "debian-static.yaml" "192.168.0.144"
create_vm_static 201 "edge-a" 9001 2 2048 10 "alpine-static.yaml" "192.168.0.163"
create_vm_static 202 "edge-b" 9001 2 2048 10 "alpine-static.yaml" "192.168.0.236"
create_vm_static 203 "clarity-app" 9000 4 8192 40 "debian-static.yaml" "192.168.0.180"
create_vm_static 204 "monitoring" 9000 4 6144 30 "debian-static.yaml" "192.168.0.207"
create_vm_static 205 "pbs-backup" 9000 2 4096 50 "debian-static.yaml" "192.168.0.242"

echo "🚀 Starting all VMs..."

# Start all VMs
for vmid in 200 201 202 203 204 205; do
    echo "Starting VM $vmid..."
    qm start $vmid
done

echo "⏳ Waiting 60 seconds for VMs to boot and configure..."
sleep 60

echo "📋 VM status:"
qm list

echo "🎉 VMs recreated with static IP configuration!"

ENDSSH

echo "🎯 Deployment completed! Testing SSH access..."

# Test SSH access to all VMs
for ip in 192.168.0.144 192.168.0.163 192.168.0.236 192.168.0.180 192.168.0.207 192.168.0.242; do
  echo "Testing SSH to $ip..."
  if timeout 10 ssh -i ~/.ssh/id_ed25519_clarity -o ConnectTimeout=5 -o StrictHostKeyChecking=no VespianRex@$ip 'hostname' 2>/dev/null; then
    echo "✅ $ip - SSH working"
  else
    echo "❌ $ip - SSH failed"
  fi
done
