#!/bin/bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════════
#  Emergency VM Rollback Script
#  Rollback App VM to last known good Proxmox snapshot
# ════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROXMOX_HOST="192.168.0.33"
VMID=203

echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}           EMERGENCY VM ROLLBACK                           ${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will restore the VM to a previous snapshot!${NC}"
echo -e "${YELLOW}⚠️  The VM will be STOPPED and RESTORED!${NC}"
echo -e "${YELLOW}⚠️  Any changes after the snapshot will be LOST!${NC}"
echo ""

# List available snapshots
echo "Available deployment snapshots:"
echo "──────────────────────────────────"
ssh root@$PROXMOX_HOST "/usr/local/bin/proxmox-snapshot.sh list"

echo ""
echo "Latest snapshot:"
LATEST=$(ssh root@$PROXMOX_HOST "/usr/local/bin/proxmox-snapshot.sh latest")
echo "  $LATEST"

echo ""
read -p "Rollback to LATEST snapshot? (type 'YES' to confirm): " -r
echo ""

if [[ $REPLY != "YES" ]]; then
    echo "Rollback cancelled"
    exit 0
fi

echo -e "${YELLOW}Starting rollback process...${NC}"

# Execute rollback on Proxmox
ssh root@$PROXMOX_HOST "/usr/local/bin/proxmox-snapshot.sh rollback" << EOF
yes
EOF

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Rollback Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "1. Wait ~30 seconds for VM to boot"
echo "2. Check services: ssh VespianRex@192.168.0.180 'systemctl status clarity-app pocketbase'"
echo "3. Test website: curl https://andub.go.ro"
echo "4. Check what commit is deployed: ssh VespianRex@192.168.0.180 'cd /opt/clarity/app && git log -1'"
echo ""
echo -e "${YELLOW}Remember: The VM was restored to the snapshot state${NC}"
echo -e "${YELLOW}Any deployments after that snapshot are now gone${NC}"