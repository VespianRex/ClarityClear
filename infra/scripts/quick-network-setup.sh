#!/usr/bin/env bash
set -euo pipefail

echo "Setting static IP for Proxmox access..."

# Set static IP
sudo networksetup -setmanual "Wi-Fi" 192.168.0.100 255.255.255.0 192.168.0.1

# Set DNS
sudo networksetup -setdnsservers "Wi-Fi" 1.1.1.1 8.8.8.8

# Restart interface
sudo ifconfig en0 down
sleep 2
sudo ifconfig en0 up
sleep 3

echo "Done! Your Mac now has IP: 192.168.0.100"
echo ""

# Test connectivity
echo "Testing connectivity..."
ping -c 1 192.168.0.1 > /dev/null 2>&1 && echo "✅ Router reachable" || echo "❌ Router not reachable"
ping -c 1 192.168.0.33 > /dev/null 2>&1 && echo "✅ Proxmox reachable" || echo "❌ Proxmox not reachable"
ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "✅ Internet working" || echo "❌ No internet"

echo ""
echo "Current IP:"
ifconfig en0 | grep "inet " | grep -v 127.0.0.1

echo ""
echo "To revert: networksetup -setdhcp Wi-Fi"