#!/usr/bin/env bash
set -euo pipefail

# Prepare Proxmox for deployment

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }

# Load environment
cd "$(dirname "$0")/.."
source .env

PVE_HOST="192.168.0.33"
PVE_USER="root"
PVE_PASS="sonicx555"

log "Connecting to Proxmox at $PVE_HOST..."

# Remove existing test VM
log "Checking for existing test VMs..."
ssh-keyscan -H $PVE_HOST >> ~/.ssh/known_hosts 2>/dev/null || true

# Use sshpass for automated login (install if needed)
if ! command -v sshpass &> /dev/null; then
    log "Installing sshpass..."
    brew install hudochenkov/sshpass/sshpass 2>/dev/null || true
fi

# List and remove test VMs
log "Removing test VMs if they exist..."
sshpass -p "$PVE_PASS" ssh root@$PVE_HOST "
    # List all VMs
    qm list

    # Stop and destroy VM 100 if it exists (common test VM ID)
    if qm status 100 &>/dev/null; then
        echo 'Stopping VM 100...'
        qm stop 100 || true
        sleep 2
        echo 'Destroying VM 100...'
        qm destroy 100 --purge
    fi

    # Remove any other test VMs (101-110)
    for vmid in {101..110}; do
        if qm status \$vmid &>/dev/null; then
            echo \"Removing VM \$vmid...\"
            qm stop \$vmid || true
            qm destroy \$vmid --purge
        fi
    done
"

log "Proxmox cleanup complete!"