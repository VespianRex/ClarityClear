#!/bin/bash

# Proxmox credentials
PM_API_URL="https://192.168.0.33:8006/api2/json"
PM_USER="root@pam"
PM_PASSWORD="sonicx555"
NODE="prox00"

# Get authentication ticket
AUTH_RESPONSE=$(curl -k -s "$PM_API_URL/access/ticket" \
    -d "username=$PM_USER&password=$PM_PASSWORD")

TICKET=$(echo "$AUTH_RESPONSE" | jq -r '.data.ticket')

echo "VM Network Information:"
echo "======================="

# Get running VMs
VMS=$(curl -k -s "$PM_API_URL/nodes/$NODE/qemu" \
    -H "Cookie: PVEAuthCookie=$TICKET" | \
    jq -r '.data[] | select(.status=="running") | .vmid')

for VMID in $VMS; do
    # Get VM details
    VM_INFO=$(curl -k -s "$PM_API_URL/nodes/$NODE/qemu/$VMID/config" \
        -H "Cookie: PVEAuthCookie=$TICKET")

    VM_NAME=$(echo "$VM_INFO" | jq -r '.data.name // "unknown"')

    # Get agent network info if available
    AGENT_INFO=$(curl -k -s "$PM_API_URL/nodes/$NODE/qemu/$VMID/agent/network-get-interfaces" \
        -H "Cookie: PVEAuthCookie=$TICKET" 2>/dev/null)

    if [ $? -eq 0 ] && [ "$AGENT_INFO" != "" ]; then
        IP=$(echo "$AGENT_INFO" | jq -r '.data.result[] | select(.name!="lo") | ."ip-addresses"[]? | select(.["ip-address-type"]=="ipv4") | .["ip-address"]' 2>/dev/null | head -1)
        if [ "$IP" != "" ] && [ "$IP" != "null" ]; then
            echo "VM $VMID ($VM_NAME): $IP"
        else
            echo "VM $VMID ($VM_NAME): No IP found (guest agent may not be running)"
        fi
    else
        echo "VM $VMID ($VM_NAME): Guest agent not responding"
    fi
done

echo ""
echo "Testing Application VM (clarity-app)..."
# Look for the app VM specifically
APP_VMID=$(curl -k -s "$PM_API_URL/nodes/$NODE/qemu" \
    -H "Cookie: PVEAuthCookie=$TICKET" | \
    jq -r '.data[] | select(.name=="clarity-app") | .vmid')

if [ "$APP_VMID" != "" ]; then
    echo "Found clarity-app VM ID: $APP_VMID"
    # Try to get console or more details
    curl -k -s "$PM_API_URL/nodes/$NODE/qemu/$APP_VMID/status/current" \
        -H "Cookie: PVEAuthCookie=$TICKET" | jq '.data'
fi