#!/bin/bash
set -euo pipefail

echo "🔨 Building Custom Alpine Linux Image with SSH Pre-installed"
echo "============================================================"

# Method 1: Using alpine-make-vm-image (Recommended)
cat > /Users/alex/DEV/ClarityClear/infra/alpine-vm-image-builder.sh << 'BUILDER'
#!/bin/bash
set -euo pipefail

echo "📦 Building Alpine VM Image with alpine-make-vm-image..."

# Configuration
ALPINE_VERSION="3.20"
IMAGE_FORMAT="qcow2"
IMAGE_SIZE="2G"
OUTPUT_FILE="alpine-ssh-custom.qcow2"

# Packages to install
PACKAGES="openssh openssh-server sudo qemu-guest-agent cloud-init curl wget bash python3"

# Create a script that will run inside the chroot during image creation
cat > /tmp/alpine-setup.sh << 'SETUP'
#!/bin/sh
set -e

echo "🔧 Configuring Alpine Linux..."

# Enable SSH service
rc-update add sshd default

# Enable guest agent
rc-update add qemu-guest-agent default

# Enable cloud-init services
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
echo '${SSH_PUBKEY}
chown -R VespianRex:VespianRex /home/VespianRex/.ssh
chmod 700 /home/VespianRex/.ssh
chmod 600 /home/VespianRex/.ssh/authorized_keys

# Configure SSH
cat > /etc/ssh/sshd_config << 'SSHCFG'
Port 22
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
PrintMotd no
Subsystem sftp /usr/lib/ssh/sftp-server
SSHCFG

# Configure cloud-init
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
NETCFG

echo "✅ Alpine configuration complete!"
SETUP

chmod +x /tmp/alpine-setup.sh

# Download alpine-make-vm-image if not available
if [ ! -f /tmp/alpine-make-vm-image ]; then
    echo "📥 Downloading alpine-make-vm-image..."
    curl -L https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/master/alpine-make-vm-image -o /tmp/alpine-make-vm-image
    chmod +x /tmp/alpine-make-vm-image
fi

echo "🏗️ Building Alpine VM image..."
sudo /tmp/alpine-make-vm-image \
    --image-format "$IMAGE_FORMAT" \
    --image-size "$IMAGE_SIZE" \
    --repositories-file /dev/null \
    --packages "$PACKAGES" \
    --script-chroot /tmp/alpine-setup.sh \
    "$OUTPUT_FILE"

echo "✅ Alpine VM image created: $OUTPUT_FILE"
echo ""
echo "📋 Next steps to use in Proxmox:"
echo "1. Upload $OUTPUT_FILE to Proxmox storage"
echo "2. Create VM with this disk image"
echo "3. Add cloud-init drive"
echo "4. Start VM and enjoy SSH access!"
BUILDER

chmod +x /Users/alex/DEV/ClarityClear/infra/alpine-vm-image-builder.sh

# Method 2: Using Docker to build Alpine image
cat > /Users/alex/DEV/ClarityClear/infra/alpine-docker-builder.sh << 'DOCKER'
#!/bin/bash
set -euo pipefail

echo "🐳 Building Alpine Image using Docker..."

# Create Dockerfile
cat > /tmp/Dockerfile.alpine << 'DOCKERFILE'
FROM alpine:3.20

# Install packages
RUN apk add --no-cache \
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

# Create user
RUN adduser -D VespianRex && \
    echo 'VespianRex:${ADMIN_PASSWORD:-ChangeMe}' | chpasswd && \
    addgroup VespianRex wheel

# Configure sudo
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Setup SSH
RUN mkdir -p /home/VespianRex/.ssh && \
    echo '${SSH_PUBKEY}
    chown -R VespianRex:VespianRex /home/VespianRex/.ssh && \
    chmod 700 /home/VespianRex/.ssh && \
    chmod 600 /home/VespianRex/.ssh/authorized_keys

# Configure SSH daemon
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Enable services
RUN rc-update add sshd default && \
    rc-update add qemu-guest-agent default && \
    rc-update add cloud-init-local default && \
    rc-update add cloud-init default && \
    rc-update add cloud-config default && \
    rc-update add cloud-final default

# Configure cloud-init
RUN echo 'datasource_list: [ NoCloud, ConfigDrive ]' > /etc/cloud/cloud.cfg.d/99_pve.cfg && \
    echo 'iso9660' > /etc/modules-load.d/iso9660.conf

# Configure network
RUN cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
