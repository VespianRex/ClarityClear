#!/bin/bash
set -euo pipefail

echo "🔨 Building Alpine Linux template with SSH pre-installed..."

ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 << 'ENDSSH'

set -euo pipefail

echo "📦 Downloading Alpine Linux ISO..."
cd /var/lib/vz/template/iso/

# Download Alpine Virtual ISO if not present
if [ ! -f alpine-virt-3.20.3-x86_64.iso ]; then
    wget https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.3-x86_64.iso
fi

echo "🆕 Creating new VM for Alpine SSH template..."
# Create a new VM for building the template
qm create 9002 \
    --name alpine-ssh-template \
    --memory 1024 \
    --cores 1 \
    --net0 virtio,bridge=vmbr0 \
    --scsihw virtio-scsi-pci \
    --scsi0 local-lvm:8 \
    --ide2 local:iso/alpine-virt-3.20.3-x86_64.iso,media=cdrom \
    --serial0 socket \
    --vga serial0 \
    --boot c \
    --bootdisk scsi0 \
    --ostype l26

echo "🚀 Starting VM 9002 for installation..."
qm start 9002

echo "⏳ Waiting 30 seconds for VM to boot..."
sleep 30

echo "📝 Creating Alpine installation script..."
cat > /tmp/setup-alpine-ssh.sh << 'SCRIPT'
#!/bin/sh
# This script sets up Alpine with SSH

# Setup answers for Alpine installer
cat > /tmp/answerfile << 'ANSWERS'
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n alpine"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
DNSOPTS="-n 8.8.8.8"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys /dev/sda"
ANSWERS

# Run setup-alpine with answer file
setup-alpine -f /tmp/answerfile

# After base install, add SSH and other packages
apk update
apk add openssh openssh-server sudo qemu-guest-agent cloud-init curl wget bash

# Create default user
adduser -D alpine
echo 'alpine:alpine' | chpasswd

# Create VespianRex user
adduser -D VespianRex
echo 'VespianRex:ClarityInfra2025!' | chpasswd
addgroup VespianRex wheel

# Configure sudo
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Setup SSH keys
mkdir -p /home/VespianRex/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro' > /home/VespianRex/.ssh/authorized_keys
chown -R VespianRex:VespianRex /home/VespianRex/.ssh
chmod 700 /home/VespianRex/.ssh
chmod 600 /home/VespianRex/.ssh/authorized_keys

# Configure SSH
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Enable services to start at boot
rc-update add sshd default
rc-update add qemu-guest-agent default

# Enable cloud-init
rc-update add cloud-init-local default
rc-update add cloud-init default
rc-update add cloud-config default
rc-update add cloud-final default

# Configure cloud-init datasources
cat > /etc/cloud/cloud.cfg.d/99_pve.cfg << 'CLOUDCFG'
datasource_list: [ NoCloud, ConfigDrive ]
datasource:
  NoCloud:
    seedfrom: /dev/sr0
CLOUDCFG

# Start services
rc-service sshd start
rc-service qemu-guest-agent start

echo "SSH setup complete!"
SCRIPT

echo "⚠️  Manual steps required:"
echo "1. Access VM 9002 console through Proxmox web UI"
echo "2. Login as root (no password initially)"
echo "3. Run: setup-alpine"
echo "4. Follow prompts:"
echo "   - Keyboard: us"
echo "   - Hostname: alpine-ssh"  
echo "   - Network: dhcp"
echo "   - Root password: Set a temporary password"
echo "   - Timezone: UTC"
echo "   - Proxy: none"
echo "   - Mirror: 1 (fastest)"
echo "   - SSH: openssh"
echo "   - Disk: sys mode on sda"
echo "5. After reboot, login and run:"

cat << 'CMDS'
# Install packages
apk update
apk add openssh openssh-server sudo qemu-guest-agent cloud-init curl wget bash

# Create VespianRex user
adduser -D VespianRex
echo 'VespianRex:ClarityInfra2025!' | chpasswd
addgroup VespianRex wheel

# Configure sudo
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Setup SSH keys
mkdir -p /home/VespianRex/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro' > /home/VespianRex/.ssh/authorized_keys
chown -R VespianRex:VespianRex /home/VespianRex/.ssh
chmod 700 /home/VespianRex/.ssh
chmod 600 /home/VespianRex/.ssh/authorized_keys

# Configure SSH
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Enable services
rc-update add sshd default
rc-update add qemu-guest-agent default
rc-service sshd restart
rc-service qemu-guest-agent restart

# Clean up
rm -f /etc/ssh/ssh_host_*

# Shutdown to convert to template
poweroff
CMDS

echo ""
echo "6. After VM shuts down, run:"
echo "   qm template 9002"
echo ""
echo "Then you can clone this template for the Edge VMs!"

ENDSSH

echo "✅ Alpine SSH template VM created as VM 9002"
echo "⚠️  Manual installation required - see instructions above"
