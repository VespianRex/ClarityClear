#!/bin/bash

# DDNS Updater Script for andub.go.ro
# This script updates your dynamic DNS record

# Configuration
DDNS_HOSTNAME="andub.go.ro"
DDNS_USERNAME="your_username"  # Update with your DDNS username
DDNS_PASSWORD="your_password"  # Update with your DDNS password
UPDATE_URL="https://ddns.provider.com/update"  # Update with your DDNS provider's update URL

# Log file
LOG_FILE="/var/log/ddns-updater.log"
CACHE_FILE="/tmp/ddns_last_ip.txt"

# Function to get current public IP
get_public_ip() {
    # Try multiple services for redundancy
    IP=$(curl -s https://api.ipify.org 2>/dev/null)
    if [ -z "$IP" ]; then
        IP=$(curl -s https://ipinfo.io/ip 2>/dev/null)
    fi
    if [ -z "$IP" ]; then
        IP=$(curl -s https://checkip.amazonaws.com 2>/dev/null)
    fi
    echo "$IP"
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Main update function
update_ddns() {
    # Get current public IP
    CURRENT_IP=$(get_public_ip)
    
    if [ -z "$CURRENT_IP" ]; then
        log_message "ERROR: Could not determine public IP"
        exit 1
    fi
    
    # Check if IP has changed
    if [ -f "$CACHE_FILE" ]; then
        LAST_IP=$(cat "$CACHE_FILE")
        if [ "$CURRENT_IP" = "$LAST_IP" ]; then
            log_message "INFO: IP has not changed ($CURRENT_IP)"
            exit 0
        fi
    fi
    
    # Update DDNS
    log_message "INFO: Updating DDNS from ${LAST_IP:-unknown} to $CURRENT_IP"
    
    # Generic DDNS update (adjust based on your provider)
    # Example for DynDNS-style API:
    RESPONSE=$(curl -s -u "$DDNS_USERNAME:$DDNS_PASSWORD" \
        "${UPDATE_URL}?hostname=${DDNS_HOSTNAME}&myip=${CURRENT_IP}")
    
    # Alternative for some providers (using GET parameters):
    # RESPONSE=$(curl -s "${UPDATE_URL}?username=${DDNS_USERNAME}&password=${DDNS_PASSWORD}&hostname=${DDNS_HOSTNAME}&myip=${CURRENT_IP}")
    
    # Check response (adjust based on your provider's response format)
    if echo "$RESPONSE" | grep -q "good\|nochg\|OK"; then
        log_message "SUCCESS: DDNS updated successfully"
        echo "$CURRENT_IP" > "$CACHE_FILE"
    else
        log_message "ERROR: DDNS update failed - Response: $RESPONSE"
        exit 1
    fi
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Run update
update_ddns

# Add this to crontab for automatic updates every 5 minutes:
# */5 * * * * /home/alexa/DEV/ClarityClear/ClarityClear/ddns-updater.sh