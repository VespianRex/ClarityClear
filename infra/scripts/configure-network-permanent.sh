#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }

# Configuration
NEW_IP="192.168.0.100"
SUBNET_MASK="255.255.255.0"
ROUTER="192.168.0.1"
DNS_SERVERS="1.1.1.1 8.8.8.8"

show_current_config() {
    log "Current Network Configuration:"
    echo "------------------------"
    networksetup -getinfo "Wi-Fi" 2>/dev/null || networksetup -getinfo "Ethernet"
    echo "------------------------"
}

set_static_ip() {
    log "Setting up static IP configuration..."

    # Detect network interface (Wi-Fi or Ethernet)
    if networksetup -listallhardwareports | grep -q "Wi-Fi"; then
        INTERFACE="Wi-Fi"
        log "Configuring Wi-Fi interface"
    else
        INTERFACE="Ethernet"
        log "Configuring Ethernet interface"
    fi

    # Show current configuration
    show_current_config

    # Backup current settings
    log "Backing up current network settings..."
    networksetup -getinfo "$INTERFACE" > ~/network-backup-$(date +%Y%m%d-%H%M%S).txt

    # Set manual IP
    log "Setting static IP: $NEW_IP"
    sudo networksetup -setmanual "$INTERFACE" $NEW_IP $SUBNET_MASK $ROUTER

    # Set DNS servers
    log "Setting DNS servers: $DNS_SERVERS"
    sudo networksetup -setdnsservers "$INTERFACE" $DNS_SERVERS

    # Apply changes
    log "Applying network changes..."
    sudo ifconfig en0 down
    sleep 2
    sudo ifconfig en0 up
    sleep 3

    # Verify new configuration
    log "New Network Configuration:"
    show_current_config

    # Test connectivity
    log "Testing connectivity..."
    if ping -c 1 -t 2 $ROUTER > /dev/null 2>&1; then
        log "✅ Router ($ROUTER) is reachable"
    else
        warn "⚠️  Cannot reach router"
    fi

    if ping -c 1 -t 2 192.168.0.33 > /dev/null 2>&1; then
        log "✅ Proxmox (192.168.0.33) is reachable"
    else
        warn "⚠️  Cannot reach Proxmox"
    fi

    if ping -c 1 -t 2 8.8.8.8 > /dev/null 2>&1; then
        log "✅ Internet connectivity working"
    else
        warn "⚠️  No internet connectivity"
    fi
}

revert_to_dhcp() {
    log "Reverting to DHCP configuration..."

    # Detect network interface
    if networksetup -listallhardwareports | grep -q "Wi-Fi"; then
        INTERFACE="Wi-Fi"
    else
        INTERFACE="Ethernet"
    fi

    # Set DHCP
    sudo networksetup -setdhcp "$INTERFACE"

    # Reset DNS to automatic
    sudo networksetup -setdnsservers "$INTERFACE" Empty

    # Apply changes
    sudo ifconfig en0 down
    sleep 2
    sudo ifconfig en0 up
    sleep 3

    log "Reverted to DHCP"
    show_current_config
}

# Main menu
case "${1:-}" in
    set)
        log "Configuring permanent static IP for Proxmox network..."
        echo ""
        warn "This will change your network configuration permanently!"
        warn "Your Mac will get IP: $NEW_IP"
        warn "Make sure this doesn't conflict with other devices!"
        echo ""
        read -p "Continue? (y/yes/no): " confirm
        if [[ "$confirm" == "yes" ]] || [[ "$confirm" == "y" ]]; then
            set_static_ip
            echo ""
            log "Configuration complete!"
            log "Your Mac now has IP: $NEW_IP"
            log "You can now access:"
            echo "  - Proxmox: https://192.168.0.33:8006"
            echo "  - SSH: ssh root@192.168.0.33"
            echo ""
            log "To revert to DHCP later, run: $0 revert"
        else
            log "Cancelled"
        fi
        ;;
    revert)
        log "Reverting to DHCP..."
        revert_to_dhcp
        ;;
    status)
        show_current_config
        ;;
    *)
        echo "Usage: $0 [set|revert|status]"
        echo ""
        echo "Commands:"
        echo "  set    - Set static IP (192.168.0.100) to access Proxmox network"
        echo "  revert - Revert to DHCP (automatic IP)"
        echo "  status - Show current network configuration"
        echo ""
        echo "Example:"
        echo "  $0 set    # Change to static IP"
        echo "  $0 revert  # Go back to DHCP"
        exit 1
        ;;
esac