#!/bin/bash
set -euo pipefail

# Final Infrastructure Deployment Script - All Fixes Included
echo "🚀 Starting final infrastructure deployment with all fixes..."

# Load environment variables
source /Users/alex/DEV/ClarityClear/infra/.env

# SSH to Proxmox and run the deployment
ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📋 Creating cloud-init snippets with all fixes..."

# Create Alpine cloud-init snippet with SSH keys AND password
cat > /var/lib/vz/snippets/alpine-config.yaml << 'EOF'
#cloud-config
users:
  - name: VespianRex
    groups: [sudo, wheel]
    lock_passwd: false
    passwd: $6$rounds=4096$salt$UiCzd0fOz/vx7Lg/mfNcJQ7L8lHF.Qc9KZB5.Nx6N1.K0fOz/vx7Lg/mfNcJQ7L8lHF.Qc9KZB5.Nx6N1
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/sh
    ssh_authorized_keys:
      - ${SSH_PUBKEY}

chpasswd:
  list: |
    root:${ADMIN_PASSWORD:-ChangeMe}
    VespianRex:${ADMIN_PASSWORD:-ChangeMe}
  expire: false

ssh_pwauth: true

package_update: true
packages:
  - openssh-server
  - qemu-guest-agent
  - sudo
  - curl
  - wget

runcmd:
  - rc-update add sshd default
  - rc-update add qemu-guest-agent default
  - rc-service sshd start
  - rc-service qemu-guest-agent start
  - mkdir -p /home/VespianRex/.ssh
  - chown -R VespianRex:VespianRex /home/VespianRex/.ssh
  - chmod 700 /home/VespianRex/.ssh
  - chmod 600 /home/VespianRex/.ssh/authorized_keys
  - sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  - rc-service sshd restart
EOF

# Create Debian cloud-init snippet
cat > /var/lib/vz/snippets/debian-config.yaml << 'EOF'
#cloud-config
users:
  - name: VespianRex
    groups: [sudo]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${SSH_PUBKEY}

package_update: true
packages:
  - qemu-guest-agent
  - curl
  - wget
  - htop
  - vim

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
EOF

echo "🏗️  Creating VMs with proper specifications..."

# Create SSH key file for qm commands
cat > /tmp/ssh_key.pub << 'KEYEOF'
${SSH_PUBKEY}
KEYEOF

# Function to create VM
create_vm() {
    local vmid=$1
    local name=$2
    local template=$3
    local cores=$4
    local memory=$5
    local disk_size=$6
    local config_snippet=$7

    echo "Creating VM $vmid ($name)..."

    # Clone from template
    qm clone $template $vmid --name $name --full

    # Configure VM
    qm set $vmid \
        --cores $cores \
        --memory $memory \
        --balloon $((memory/2)) \
        --agent 1 \
        --onboot 1 \
        --sshkeys /tmp/ssh_key.pub \
        --ciuser VespianRex \
        --serial0 socket \
        --cicustom "user=local:snippets/$config_snippet"

    # Resize disk
    qm resize $vmid scsi0 ${disk_size}G

    # Generate cloud-init
    qm cloudinit update $vmid

    echo "✅ VM $vmid ($name) created successfully"
}

echo "🔨 Creating all VMs..."

# NFS Storage VM (200) - Using Debian, will be backup/utility server since we use Synology for NFS
create_vm 200 "backup-storage" 9000 2 4096 20 "debian-config.yaml"

# Edge VMs (201, 202) - Alpine with HA configuration
create_vm 201 "edge-a" 9001 2 2048 10 "alpine-config.yaml"
create_vm 202 "edge-b" 9001 2 2048 10 "alpine-config.yaml"

# App VM (203) - Debian with more resources
create_vm 203 "clarity-app" 9000 4 8192 40 "debian-config.yaml"

# Monitoring VM (204) - Debian with sufficient space
create_vm 204 "monitoring" 9000 4 6144 30 "debian-config.yaml"

# PBS Backup VM (205) - Debian for Proxmox Backup Server
create_vm 205 "pbs-backup" 9000 2 4096 50 "debian-config.yaml"

echo "🚀 Starting all VMs..."

# Start all VMs
for vmid in 200 201 202 203 204 205; do
    echo "Starting VM $vmid..."
    qm start $vmid
done

echo "⏳ Waiting 90 seconds for VMs to boot and cloud-init to complete..."
sleep 90

echo "📋 Final VM status:"
qm list

echo "🎉 Infrastructure deployment complete!"
echo ""
echo "Next steps:"
echo "1. Verify SSH access to all VMs"
echo "2. Deploy monitoring stack"
echo "3. Configure Keepalived HA"
echo "4. Setup AmneziaVPN"

ENDSSH

echo "🎯 Deployment script completed!"
echo "Checking VM status..."

# Get VM status
ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 "qm list"