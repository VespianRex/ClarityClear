#!/bin/bash
set -euo pipefail

echo "🔨 Building Custom Alpine Linux Image with SSH - Fixed Version"
echo "=============================================================="

ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📦 Setting up Alpine image builder on Proxmox..."

# Update package lists ignoring enterprise repo errors
apt-get update 2>&1 | grep -v "enterprise.proxmox.com" || true

# Install required tools
echo "Installing required dependencies..."
apt-get install -y qemu-utils wget curl gzip e2fsprogs parted kpartx || {
    echo "Failed to install some packages, trying alternatives..."
    apt-get install -y --no-install-recommends qemu-utils wget curl || true
}

# Create working directory
rm -rf /tmp/alpine-builder
mkdir -p /tmp/alpine-builder
cd /tmp/alpine-builder

# Download alpine-make-vm-image script (specific version for stability)
echo "📥 Downloading alpine-make-vm-image v0.13.3..."
wget -O alpine-make-vm-image https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.3/alpine-make-vm-image
chmod +x alpine-make-vm-image

# Create the setup script that will configure Alpine
cat > setup-alpine-ssh.sh << 'SETUP'
#!/bin/sh
set -e

echo "🔧 Configuring Alpine Linux with SSH..."

# Configure repositories first
cat > /etc/apk/repositories << 'REPOS'
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
REPOS

# Update and install packages
apk update
apk add --no-cache \
    openssh \
    openssh-server \
    openssh-client \
    sudo \
    qemu-guest-agent \
    curl \
    wget \
    bash \
    python3 \
    e2fsprogs-extra \
    util-linux \
    openrc

# Enable services with OpenRC
rc-update add sshd default
rc-update add qemu-guest-agent default
rc-update add networking boot
rc-update add hostname boot

# Create VespianRex user
adduser -D -s /bin/bash VespianRex
echo 'VespianRex:ClarityInfra2025!' | chpasswd
addgroup VespianRex wheel

# Configure sudo
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Setup SSH keys
mkdir -p /home/VespianRex/.ssh
cat > /home/VespianRex/.ssh/authorized_keys << 'SSHKEY'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro
SSHKEY
chown -R VespianRex:VespianRex /home/VespianRex/.ssh
chmod 700 /home/VespianRex/.ssh
chmod 600 /home/VespianRex/.ssh/authorized_keys

# Also setup for root
mkdir -p /root/.ssh
cp /home/VespianRex/.ssh/authorized_keys /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

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

# Configure network for DHCP
cat > /etc/network/interfaces << 'NETCFG'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname alpine-ssh-custom
NETCFG

# Set hostname
echo "alpine-ssh-custom" > /etc/hostname

# Enable root login for debugging
echo "root:ClarityInfra2025!" | chpasswd

# Create startup script for first boot
cat > /etc/local.d/first-boot.start << 'FIRSTBOOT'
#!/bin/sh
# Ensure SSH is running
rc-service sshd restart || rc-service sshd start
# Ensure guest agent is running
rc-service qemu-guest-agent restart || rc-service qemu-guest-agent start
FIRSTBOOT
chmod +x /etc/local.d/first-boot.start
rc-update add local default

echo "✅ Alpine SSH configuration complete!"
SETUP

chmod +x setup-alpine-ssh.sh

# Build the Alpine VM image with specific Alpine version
echo "🏗️ Building Alpine VM image (this may take a few minutes)..."

# Use a simpler command first to test
./alpine-make-vm-image \
    --image-format qcow2 \
    --image-size 3G \
    --serial-console \
    --packages "openssh openssh-server sudo qemu-guest-agent curl wget bash python3 e2fsprogs-extra util-linux openrc" \
    --script-chroot ./setup-alpine-ssh.sh \
    alpine-ssh-custom.qcow2

if [ -f alpine-ssh-custom.qcow2 ]; then
    echo "✅ Alpine image created successfully!"

    # Move to Proxmox images directory
    mv alpine-ssh-custom.qcow2 /var/lib/vz/images/

    echo "📋 Creating Proxmox VM from custom Alpine image..."

    # Create a new VM
    VMID=9006

    # Remove old VM if exists
    qm stop $VMID 2>/dev/null || true
    sleep 2
    qm destroy $VMID 2>/dev/null || true

    # Create new VM
    qm create $VMID \
        --name alpine-ssh-custom \
        --memory 2048 \
        --cores 2 \
        --net0 virtio,bridge=vmbr0 \
        --serial0 socket \
        --vga serial0 \
        --ostype l26

    # Import the disk
    qm importdisk $VMID /var/lib/vz/images/alpine-ssh-custom.qcow2 local-lvm

    # Attach the disk
    qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
    qm set $VMID --bootdisk scsi0
    qm set $VMID --scsihw virtio-scsi-pci

    # Enable QEMU guest agent
    qm set $VMID --agent 1

    # Start the VM
    qm start $VMID

    echo "✅ VM $VMID created and started!"
    echo ""
    echo "📋 Summary:"
    echo "- Custom Alpine image created with SSH pre-installed"
    echo "- VM ID: $VMID"
    echo "- Username: VespianRex (also root access)"
    echo "- Password: ClarityInfra2025!"
    echo "- SSH key already configured"
    echo ""
    echo "⏳ Waiting 60 seconds for boot..."
    sleep 60

    echo "🔍 Checking VM status..."
    qm status $VMID

    # Try to get agent info
    qm agent $VMID ping 2>/dev/null && echo "✅ Guest agent responding!" || echo "⚠️ Guest agent not ready yet"

else
    echo "❌ Failed to create Alpine image"
    echo "Checking for errors..."
    ls -la /tmp/alpine-builder/
    exit 1
fi

ENDSSH

echo "✅ Script completed on Proxmox!"