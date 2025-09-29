#!/bin/bash

# Direct VM deployment via Proxmox API
# Bypasses Terraform provider permission issues

PROXMOX_API="https://192.168.0.33:8006/api2/json"
NODE="prox00"
USERNAME="root@pam"
PASSWORD="sonicx555"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Proxmox Direct VM Deployment${NC}"
echo "=============================="
echo ""

# Get authentication ticket
echo "Authenticating..."
AUTH_RESPONSE=$(curl -k -s -d "username=${USERNAME}&password=${PASSWORD}" \
    "${PROXMOX_API}/access/ticket")

if ! echo "$AUTH_RESPONSE" | grep -q "ticket"; then
    echo -e "${RED}Authentication failed${NC}"
    exit 1
fi

TICKET=$(echo "$AUTH_RESPONSE" | jq -r '.data.ticket')
CSRF=$(echo "$AUTH_RESPONSE" | jq -r '.data.CSRFPreventionToken')
echo -e "${GREEN}✓ Authentication successful${NC}"
echo ""

# Function to clone a VM
clone_vm() {
    local TEMPLATE_ID=$1
    local NEW_VMID=$2
    local VM_NAME=$3
    local CORES=$4
    local MEMORY=$5
    local IP_CONFIG=$6

    echo -e "${YELLOW}Creating VM ${VM_NAME} (ID: ${NEW_VMID})...${NC}"

    # Clone the template
    CLONE_RESPONSE=$(curl -k -s -X POST \
        -H "Cookie: PVEAuthCookie=${TICKET}" \
        -H "CSRFPreventionToken: ${CSRF}" \
        -d "newid=${NEW_VMID}" \
        -d "name=${VM_NAME}" \
        -d "full=1" \
        -d "target=${NODE}" \
        "${PROXMOX_API}/nodes/${NODE}/qemu/${TEMPLATE_ID}/clone")

    if echo "$CLONE_RESPONSE" | grep -q "UPID"; then
        TASK_ID=$(echo "$CLONE_RESPONSE" | jq -r '.data')
        echo "  Clone task started: ${TASK_ID}"

        # Wait for clone to complete
        echo -n "  Waiting for clone to complete"
        while true; do
            TASK_STATUS=$(curl -k -s -H "Cookie: PVEAuthCookie=${TICKET}" \
                "${PROXMOX_API}/nodes/${NODE}/tasks/${TASK_ID}/status")

            if echo "$TASK_STATUS" | grep -q '"status":"stopped"'; then
                echo ""
                if echo "$TASK_STATUS" | grep -q '"exitstatus":"OK"'; then
                    echo -e "  ${GREEN}✓ Clone completed successfully${NC}"
                    break
                else
                    echo -e "  ${RED}✗ Clone failed${NC}"
                    return 1
                fi
            fi
            echo -n "."
            sleep 2
        done

        # Configure the VM
        echo "  Configuring VM..."

        # Set CPU and memory
        curl -k -s -X PUT \
            -H "Cookie: PVEAuthCookie=${TICKET}" \
            -H "CSRFPreventionToken: ${CSRF}" \
            -d "cores=${CORES}" \
            -d "memory=${MEMORY}" \
            -d "agent=1" \
            -d "onboot=1" \
            "${PROXMOX_API}/nodes/${NODE}/qemu/${NEW_VMID}/config" > /dev/null

        # Set cloud-init if IP config provided
        if [ ! -z "${IP_CONFIG}" ]; then
            curl -k -s -X PUT \
                -H "Cookie: PVEAuthCookie=${TICKET}" \
                -H "CSRFPreventionToken: ${CSRF}" \
                -d "ipconfig0=${IP_CONFIG}" \
                -d "nameserver=192.168.0.1" \
                -d "searchdomain=andub.go.ro" \
                -d "ciuser=VespianRex" \
                -d "sshkeys=$(echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO VespianRex@andub.go.ro' | jq -sRr @uri)" \
                "${PROXMOX_API}/nodes/${NODE}/qemu/${NEW_VMID}/config" > /dev/null
        fi

        echo -e "  ${GREEN}✓ VM ${VM_NAME} created successfully${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Failed to start clone task${NC}"
        echo "  Response: $CLONE_RESPONSE"
        return 1
    fi
}

# Deploy VMs
echo "Starting VM deployment..."
echo ""

# NFS Server (static IP)
clone_vm 9000 200 "nfs-storage" 1 1024 "ip=192.168.0.55/24,gw=192.168.0.1"
echo ""

# Edge VMs (Alpine)
clone_vm 9001 201 "edge-a" 2 2048 "ip=dhcp"
echo ""
clone_vm 9001 202 "edge-b" 2 2048 "ip=dhcp"
echo ""

# App VM (Debian)
clone_vm 9000 203 "clarity-app" 4 8192 "ip=dhcp"
echo ""

# Monitoring VM (Debian)
clone_vm 9000 204 "monitoring" 2 4096 "ip=dhcp"
echo ""

# PBS VM (Debian)
clone_vm 9000 205 "pbs-backup" 2 4096 "ip=dhcp"
echo ""

echo "=============================="
echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo "VMs created:"
echo "  - 200: nfs-storage (192.168.0.55)"
echo "  - 201: edge-a (DHCP)"
echo "  - 202: edge-b (DHCP)"
echo "  - 203: clarity-app (DHCP)"
echo "  - 204: monitoring (DHCP)"
echo "  - 205: pbs-backup (DHCP)"
echo ""
echo "Next steps:"
echo "1. Start the VMs: qm start <vmid>"
echo "2. Wait for cloud-init to complete"
echo "3. Get IP addresses: qm guest cmd <vmid> network-get-interfaces"
echo ""