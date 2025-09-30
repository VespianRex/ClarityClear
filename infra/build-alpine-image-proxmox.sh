#!/bin/bash
set -euo pipefail

echo "🔨 Building Custom Alpine Linux Image with SSH on Proxmox"
echo "========================================================="

ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📦 Setting up Alpine image builder on Proxmox..."

# Install required tools
apt-get update
apt-get install -y qemu-utils wget curl gzip

# Create working directory
mkdir -p /tmp/alpine-builder
cd /tmp/alpine-builder

# Download alpine-make-vm-image script
echo "📥 Downloading alpine-make-vm-image..."
wget -O alpine-make-vm-image https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/master/alpine-make-vm-image
chmod +x alpine-make-vm-image

# Create the setup script that will configure Alpine
cat > setup-alpine-ssh.sh << 'SETUP'
#!/bin/sh
set -e

echo "🔧 Configuring Alpine Linux with SSH..."

# Update and install packages
apk update
apk add --no-cache \
    openssh \
    openssh-server \
    sudo \
    qemu-guest-agent \
    cloud-init \
    curl \
    wget \
    bash \
    python3 \
    e2fsprogs-extra \
    util-linux

# Enable services
rc-update add sshd default
rc-update add qemu-guest-agent default
rc-update add cloud-init-local default
rc-update add cloud-init default
rc-update add cloud-config default
rc-update add cloud-final default

# Create VespianRex user
adduser -D VespianRex
echo 'VespianRex:${ADMIN_PASSWORD:-ChangeMe}' | chpasswd
addgroup VespianRex wheel

# Configure sudo
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Setup SSH keys
mkdir -p /home/VespianRex/.ssh
cat > /home/VespianRex/.ssh/authorized_keys << 'SSHKEY'
${SSH_PUBKEY}
SSHKEY
chown -R VespianRex:VespianRex /home/VespianRex/.ssh
chmod 700 /home/VespianRex/.ssh
chmod 600 /home/VespianRex/.ssh/authorized_keys

# Configure SSH daemon
cat > /etc/ssh/sshd_config << 'SSHCFG'
Port 22
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/ssh/sftp-server
SSHCFG

# Generate SSH host keys
ssh-keygen -A

# Configure cloud-init for Proxmox
mkdir -p /etc/cloud/cloud.cfg.d
cat > /etc/cloud/cloud.cfg.d/99_pve.cfg << 'CLOUDCFG'
datasource_list: [ NoCloud, ConfigDrive ]
datasource:
  NoCloud:
    seedfrom: /dev/sr0
CLOUDCFG

# Load iso9660 module for cloud-init
echo "iso9660" > /etc/modules-load.d/iso9660.conf

# Configure network for DHCP
cat > /etc/network/interfaces << 'NETCFG'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname alpine-ssh
NETCFG

# Enable root login temporarily for initial access
echo "root:${ADMIN_PASSWORD:-ChangeMe}" | chpasswd

echo "✅ Alpine SSH configuration complete!"
SETUP

chmod +x setup-alpine-ssh.sh

# Build the Alpine VM image
echo "🏗️ Building Alpine VM image (this may take a few minutes)..."
./alpine-make-vm-image \
    --image-format qcow2 \
    --image-size 2G \
    --repositories-file /dev/null \
    --packages "openssh openssh-server sudo qemu-guest-agent cloud-init curl wget bash python3 e2fsprogs-extra util-linux" \
    --script-chroot ./setup-alpine-ssh.sh \
    alpine-ssh-custom.qcow2

if [ -f alpine-ssh-custom.qcow2 ]; then
    echo "✅ Alpine image created successfully!"
    
    # Move to Proxmox images directory
    mv alpine-ssh-custom.qcow2 /var/lib/vz/images/
    
    echo "📋 Creating Proxmox VM from custom Alpine image..."
    
    # Create a new VM
    VMID=9003
    
    # Remove old VM if exists
    qm stop $VMID 2>/dev/null || true
    qm destroy $VMID 2>/dev/null || true
    
    # Create new VM
    qm create $VMID \
        --name alpine-ssh-custom \
        --memory 1024 \
        --cores 1 \
        --net0 virtio,bridge=vmbr0 \
        --serial0 socket \
        --vga serial0 \
        --boot c \
        --ostype l26
    
    # Import the disk
    qm importdisk $VMID /var/lib/vz/images/alpine-ssh-custom.qcow2 local-lvm
    
    # Attach the disk
    qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
    qm set $VMID --bootdisk scsi0
    qm set $VMID --scsihw virtio-scsi-pci
    
    # Add cloud-init
    qm set $VMID --ide2 local-lvm:cloudinit
    qm set $VMID --agent 1
    
    # Start the VM
    qm start $VMID
    
    echo "✅ VM $VMID created and started!"
    echo ""
    echo "📋 Summary:"
    echo "- Custom Alpine image created with SSH pre-installed"
    echo "- VM ID: $VMID"
    echo "- Username: VespianRex"
    echo "- Password: ${ADMIN_PASSWORD:-ChangeMe}"
    echo "- SSH key already configured"
    echo ""
    echo "Wait 30 seconds for boot, then check:"
    echo "qm guest cmd $VMID network-get-interfaces"
    
else
    echo "❌ Failed to create Alpine image"
    exit 1
fi

ENDSSH

echo "✅ Script completed on Proxmox!"
