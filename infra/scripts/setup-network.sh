#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }

# Function to add secondary IP
add_secondary_ip() {
    log "Adding secondary IP to access Proxmox network..."

    # Check current IPs
    log "Current network configuration:"
    ifconfig en0 | grep inet

    # Add alias IP
    log "Adding 192.168.0.100 as secondary IP..."
    sudo ifconfig en0 alias 192.168.0.100 netmask 255.255.255.0

    # Verify
    log "New configuration:"
    ifconfig en0 | grep inet

    # Test connectivity
    log "Testing connectivity to Proxmox..."
    if ping -c 1 -t 2 192.168.0.33 > /dev/null 2>&1; then
        log "✅ Successfully connected to Proxmox!"
    else
        warn "Cannot reach Proxmox yet. You may need to:"
        echo "  1. Check if Proxmox firewall allows connections"
        echo "  2. Ensure Proxmox is running"
    fi
}

# Function to remove secondary IP
remove_secondary_ip() {
    log "Removing secondary IP..."
    sudo ifconfig en0 -alias 192.168.0.100
    log "Secondary IP removed"
}

# Main menu
case "${1:-add}" in
    add)
        add_secondary_ip
        echo ""
        log "You can now access Proxmox at https://192.168.0.33:8006"
        log "SSH should work: ssh root@192.168.0.33"
        echo ""
        log "To remove this IP later, run: $0 remove"
        ;;
    remove)
        remove_secondary_ip
        ;;
    *)
        echo "Usage: $0 [add|remove]"
        echo "  add    - Add secondary IP to access Proxmox network"
        echo "  remove - Remove secondary IP"
        exit 1
        ;;
esac