#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }

# Test Proxmox connectivity
PVE_HOST="192.168.0.33"
PVE_USER="root"
PVE_PASS="sonicx555"

log "Testing Proxmox connectivity..."

# Test ping
if ping -c 1 -t 2 $PVE_HOST > /dev/null 2>&1; then
    log "✅ Ping successful"
else
    error "❌ Cannot ping Proxmox"
    exit 1
fi

# Test SSH port
if nc -zv $PVE_HOST 22 2>&1 | grep -q succeeded; then
    log "✅ SSH port (22) is open"
else
    warn "⚠️  SSH port might be closed"
fi

# Test Proxmox web port
if nc -zv $PVE_HOST 8006 2>&1 | grep -q succeeded; then
    log "✅ Proxmox web UI port (8006) is open"
else
    warn "⚠️  Proxmox web UI port might be closed"
fi

# Add SSH key to known hosts
log "Adding Proxmox to known hosts..."
ssh-keyscan -H $PVE_HOST >> ~/.ssh/known_hosts 2>/dev/null || true

# Test SSH connection with password
log "Testing SSH connection (will prompt for password: sonicx555)..."
if sshpass -p "$PVE_PASS" ssh -o ConnectTimeout=5 root@$PVE_HOST "hostname && qm list" 2>/dev/null; then
    log "✅ SSH connection successful!"
else
    error "❌ SSH connection failed"
    echo "Please ensure:"
    echo "  1. SSH is enabled on Proxmox"
    echo "  2. Root login is permitted"
    echo "  3. Password is correct"
    exit 1
fi

log "All tests passed! Ready to deploy."