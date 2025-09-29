#!/bin/bash

# Proxmox credentials
PM_API_URL="https://192.168.0.33:8006/api2/json"
PM_USER="root@pam"
PM_PASSWORD="sonicx555"

echo "Checking Proxmox cluster status..."
echo "=================================="

# Get authentication ticket
AUTH_RESPONSE=$(curl -k -s "$PM_API_URL/access/ticket" \
    -d "username=$PM_USER&password=$PM_PASSWORD")

if [ $? -ne 0 ]; then
    echo "Failed to connect to Proxmox"
    exit 1
fi

TICKET=$(echo "$AUTH_RESPONSE" | jq -r '.data.ticket')
CSRF=$(echo "$AUTH_RESPONSE" | jq -r '.data.CSRFPreventionToken')

if [ "$TICKET" == "null" ]; then
    echo "Authentication failed"
    exit 1
fi

echo "✓ Connected to Proxmox"
echo ""

# Get nodes
echo "Cluster Nodes:"
curl -k -s "$PM_API_URL/nodes" \
    -H "Cookie: PVEAuthCookie=$TICKET" | jq -r '.data[] | "  - \(.node) (Status: \(.status))"'

echo ""
echo "Virtual Machines:"

# Get all VMs from all nodes
NODES=$(curl -k -s "$PM_API_URL/nodes" -H "Cookie: PVEAuthCookie=$TICKET" | jq -r '.data[].node')

for NODE in $NODES; do
    echo "  Node: $NODE"
    curl -k -s "$PM_API_URL/nodes/$NODE/qemu" \
        -H "Cookie: PVEAuthCookie=$TICKET" | \
        jq -r '.data[] | "    - VM \(.vmid): \(.name) (\(.status))"' 2>/dev/null || echo "    No VMs"
done

echo ""
echo "Templates:"
for NODE in $NODES; do
    curl -k -s "$PM_API_URL/nodes/$NODE/qemu" \
        -H "Cookie: PVEAuthCookie=$TICKET" | \
        jq -r '.data[] | select(.template==1) | "  - Template \(.vmid): \(.name)"' 2>/dev/null
done

echo ""
echo "Storage Status:"
curl -k -s "$PM_API_URL/storage" \
    -H "Cookie: PVEAuthCookie=$TICKET" | \
    jq -r '.data[] | "  - \(.storage): \(.type) (\(.enabled))"' 2>/dev/null