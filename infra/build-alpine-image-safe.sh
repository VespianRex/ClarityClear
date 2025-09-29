#!/bin/bash
set -euo pipefail

echo "🔨 Building Custom Alpine Linux Image with SSH - Safe Version"
echo "=============================================================="
echo "This version doesn't modify Proxmox packages"

ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📦 Checking for required tools..."

# Check if qemu-img is available (should be on Proxmox by default)
if ! command -v qemu-img &> /dev/null; then
    echo "❌ qemu-img not found. Cannot continue."
    exit 1
fi

# Create working directory
rm -rf /tmp/alpine-builder
mkdir -p /tmp/alpine-builder
cd /tmp/alpine-builder

# Download alpine-make-vm-image script
echo "📥 Downloading alpine-make-vm-image..."
wget -q -O alpine-make-vm-image https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.3/alpine-make-vm-image
chmod +x alpine-make-vm-image

# Create the setup script that will configure Alpine
cat > setup-alpine-ssh.sh << 'SETUP'
#!/bin/sh
set -e

echo "🔧 Configuring Alpine Linux with SSH..."

# Configure repositories
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
    openrc

# Enable services
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
    hostname alpine-ssh
NETCFG

# Set hostname
echo "alpine-ssh" > /etc/hostname

# Enable root login for debugging
echo "root:ClarityInfra2025!" | chpasswd

echo "✅ Alpine SSH configuration complete!"
SETUP

chmod +x setup-alpine-ssh.sh

# Build the Alpine VM image
echo "🏗️ Building Alpine VM image..."
echo "Using Alpine 3.20 with minimal packages first..."

# Try a simpler build without dependencies that might break Proxmox
QEMU_NBD_PID="" ./alpine-make-vm-image \
    --image-format qcow2 \
    --image-size 2G \
    --serial-console \
    --branch v3.20 \
    --packages "openssh openssh-server sudo bash openrc" \
    --script-chroot ./setup-alpine-ssh.sh \
    alpine-ssh.qcow2 2>&1 | tee build.log

# Check if build succeeded
if [ -f alpine-ssh.qcow2 ]; then
    echo "✅ Alpine image created successfully!"

    # Check the image
    qemu-img info alpine-ssh.qcow2

    # Move to a safe location
    mkdir -p /var/lib/vz/images/
    mv alpine-ssh.qcow2 /var/lib/vz/images/alpine-ssh-custom.qcow2

    echo "📋 Creating Proxmox VM from custom Alpine image..."

    # Create a new VM
    VMID=9007

    # Remove old VM if exists
    qm stop $VMID 2>/dev/null || true
    sleep 2
    qm destroy $VMID 2>/dev/null || true

    # Create new VM
    qm create $VMID \
        --name alpine-custom-ssh \
        --memory 2048 \
        --balloon 1024 \
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

    # Resize disk to 10GB
    qm resize $VMID scsi0 10G

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
    echo "⏳ Waiting 90 seconds for full boot..."
    sleep 90

    echo "🔍 Checking VM status..."
    qm status $VMID

    # Try to get agent info
    if qm agent $VMID ping 2>/dev/null; then
        echo "✅ Guest agent responding!"
        echo "Getting network info..."
        qm guest cmd $VMID network-get-interfaces 2>/dev/null || echo "Network info not yet available"
    else
        echo "⚠️ Guest agent not ready yet, checking network..."
    fi

else
    echo "❌ Failed to create Alpine image"
    echo "Checking build log for errors..."
    tail -20 build.log
    exit 1
fi

ENDSSH

echo "✅ Script execution completed!"