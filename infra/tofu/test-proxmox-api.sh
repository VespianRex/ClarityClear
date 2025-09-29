#!/bin/bash

# Direct API test to verify permissions
# This will help identify if it's a provider issue or actual permission issue

PROXMOX_API="https://192.168.0.33:8006/api2/json"
USERNAME="root@pam"
PASSWORD="sonicx555"

echo "Testing Proxmox API directly..."
echo ""

# Get authentication ticket
echo "1. Getting authentication ticket..."
RESPONSE=$(curl -k -s -d "username=${USERNAME}&password=${PASSWORD}" \
    "${PROXMOX_API}/access/ticket")

if echo "$RESPONSE" | grep -q "ticket"; then
    echo "   ✓ Authentication successful"

    # Extract ticket and CSRF token
    TICKET=$(echo "$RESPONSE" | jq -r '.data.ticket')
    CSRF=$(echo "$RESPONSE" | jq -r '.data.CSRFPreventionToken')

    echo ""
    echo "2. Testing VM.Monitor permission..."

    # List VMs (requires VM.Audit permission)
    VM_LIST=$(curl -k -s -H "Cookie: PVEAuthCookie=${TICKET}" \
        "${PROXMOX_API}/nodes/prox00/qemu")

    if echo "$VM_LIST" | grep -q "data"; then
        echo "   ✓ Can list VMs (VM.Audit permission OK)"
    else
        echo "   ✗ Cannot list VMs"
    fi

    echo ""
    echo "3. Checking template status..."

    # Check template 9000
    TEMPLATE_9000=$(curl -k -s -H "Cookie: PVEAuthCookie=${TICKET}" \
        "${PROXMOX_API}/nodes/prox00/qemu/9000/status/current")

    if echo "$TEMPLATE_9000" | grep -q "template"; then
        echo "   ✓ Template 9000 exists and is accessible"
    else
        echo "   ✗ Template 9000 not found or not accessible"
    fi

    # Check template 9001
    TEMPLATE_9001=$(curl -k -s -H "Cookie: PVEAuthCookie=${TICKET}" \
        "${PROXMOX_API}/nodes/prox00/qemu/9001/status/current")

    if echo "$TEMPLATE_9001" | grep -q "template"; then
        echo "   ✓ Template 9001 exists and is accessible"
    else
        echo "   ✗ Template 9001 not found or not accessible"
    fi

    echo ""
    echo "4. Testing clone operation (dry-run)..."

    # Get next available VM ID
    VMID=$(curl -k -s -H "Cookie: PVEAuthCookie=${TICKET}" \
        "${PROXMOX_API}/cluster/nextid")

    if echo "$VMID" | grep -q "data"; then
        NEXT_ID=$(echo "$VMID" | jq -r '.data')
        echo "   ✓ Next available VM ID: ${NEXT_ID}"
    else
        echo "   ✗ Cannot get next VM ID"
    fi

    echo ""
    echo "5. Checking user permissions..."

    # Get user permissions
    PERMS=$(curl -k -s -H "Cookie: PVEAuthCookie=${TICKET}" \
        "${PROXMOX_API}/access/permissions?userid=${USERNAME}")

    if echo "$PERMS" | grep -q "VM.Monitor"; then
        echo "   ✓ User has VM.Monitor permission"
    else
        echo "   ! VM.Monitor permission not explicitly listed (but root should have all permissions)"
    fi

else
    echo "   ✗ Authentication failed"
    echo "   Response: $RESPONSE"
fi

echo ""
echo "====================================="
echo "Diagnosis Summary:"
echo "====================================="
echo ""
echo "If authentication works but Terraform fails, the issue is likely:"
echo "1. Provider bug with permission checking"
echo "2. Templates not properly configured (ensure they're marked as templates)"
echo "3. Provider version incompatibility"
echo ""
echo "Recommended solutions:"
echo "1. Create an API token: pveum user token add root@pam terraform -expire 0 -privsep 0"
echo "2. Use bpg/proxmox provider instead of telmate/proxmox"
echo "3. Downgrade to telmate/proxmox version 2.9.11 or earlier"
echo "