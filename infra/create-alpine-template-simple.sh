#!/bin/bash
set -euo pipefail

echo "🔨 Creating Alpine Template using Official Cloud Image"
echo "======================================================"

ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📦 Downloading official Alpine cloud image..."
cd /var/lib/vz/template/iso/

# Download Alpine cloud image (already has cloud-init)
if [ ! -f alpine-3.20-cloud.qcow2 ]; then
    wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/cloud/nocloud_alpine-3.20.3-x86_64-uefi-cloudinit-r0.qcow2 \
         -O alpine-3.20-cloud.qcow2
fi

echo "🏗️ Creating VM from Alpine cloud image..."

VMID=9004
VM_NAME="alpine-cloud-ssh"

# Remove old VM if exists
qm stop $VMID 2>/dev/null || true
sleep 2
qm destroy $VMID 2>/dev/null || true

# Create new VM
qm create $VMID \
    --name $VM_NAME \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --serial0 socket \
    --vga serial0 \
    --boot c \
    --ostype l26 \
    --agent 1

# Import the cloud image as disk
qm importdisk $VMID /var/lib/vz/template/iso/alpine-3.20-cloud.qcow2 local-lvm

# Attach the imported disk
qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
qm set $VMID --bootdisk scsi0
qm set $VMID --scsihw virtio-scsi-pci

# Add cloud-init drive
qm set $VMID --ide2 local-lvm:cloudinit

# Configure cloud-init
qm set $VMID --ciuser VespianRex
qm set $VMID --cipassword ${ADMIN_PASSWORD:-ChangeMe}
qm set $VMID --ipconfig0 ip=dhcp

# Add SSH key
cat > /tmp/ssh_key.pub << 'KEYEOF'
${SSH_PUBKEY}
KEYEOF

qm set $VMID --sshkeys /tmp/ssh_key.pub

# Resize disk to 5GB
qm resize $VMID scsi0 5G

# Create custom cloud-init user-data to ensure SSH is installed
mkdir -p /var/lib/vz/snippets/
cat > /var/lib/vz/snippets/alpine-cloud-ssh.yaml << 'USERDATA'
#cloud-config
hostname: alpine-cloud
manage_etc_hosts: true

users:
  - name: VespianRex
    groups: [wheel]
    lock_passwd: false
    passwd: $6$salt$3hFtqz6t4z.1JK8lP/1qRFP6qYvlQz9VyHHqPBp0sJpQJmfMBOhKLz3V7Mx6FnGw.gqXH.5kMYdQPzKUqjHfC0
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/ash
    ssh_authorized_keys:
      - ${SSH_PUBKEY}

package_update: true
package_upgrade: true
packages:
  - openssh
  - openssh-server
  - qemu-guest-agent
  - sudo
  - bash
  - curl
  - wget

runcmd:
  - rc-update add sshd default
  - rc-update add qemu-guest-agent default
  - rc-service sshd start
  - rc-service qemu-guest-agent start
  - sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  - rc-service sshd restart
USERDATA

# Apply custom user-data
qm set $VMID --cicustom "user=local:snippets/alpine-cloud-ssh.yaml"

echo "✅ Alpine cloud VM created!"
echo ""
echo "🚀 Starting VM $VMID..."
qm start $VMID

echo "⏳ Waiting 60 seconds for cloud-init to complete..."
sleep 60

echo "📋 Checking VM status..."
qm status $VMID

echo "🔍 Checking guest agent..."
qm agent $VMID ping 2>/dev/null && echo "Agent responding!" || echo "Agent not responding yet"

echo ""
echo "📋 VM Details:"
echo "- VM ID: $VMID"
echo "- Name: $VM_NAME"
echo "- Username: VespianRex"
echo "- Password: ${ADMIN_PASSWORD:-ChangeMe}"
echo "- SSH key configured"
echo ""
echo "Try: qm guest cmd $VMID network-get-interfaces"

ENDSSH

echo "✅ Alpine cloud template created!"
