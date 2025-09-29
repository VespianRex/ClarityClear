#!/usr/bin/env bash
set -euo pipefail

# Comprehensive health check script for all infrastructure components

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load environment
cd "$(dirname "$0")/.."
source .env

# Health check functions
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}

    response=$(curl -sk -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

    if [[ "$response" == "$expected_code" ]] || [[ "$response" == "301" ]] || [[ "$response" == "302" ]]; then
        echo -e "${GREEN}✓${NC} $name: OK (HTTP $response)"
        return 0
    else
        echo -e "${RED}✗${NC} $name: FAILED (HTTP $response)"
        return 1
    fi
}

check_container() {
    local host=$1
    local container=$2

    if ssh "$ADMIN_USER@$host" "docker ps --format '{{.Names}}' | grep -q '$container'" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $container on $host: Running"
        return 0
    else
        echo -e "${RED}✗${NC} $container on $host: Not running"
        return 1
    fi
}

check_disk_space() {
    local host=$1
    local threshold=80

    usage=$(ssh "$ADMIN_USER@$host" "df / | awk 'NR==2 {print \$(NF-1)}' | sed 's/%//'" 2>/dev/null || echo "0")

    if [[ "$usage" -lt "$threshold" ]]; then
        echo -e "${GREEN}✓${NC} Disk space on $host: ${usage}% used"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Disk space on $host: ${usage}% used (above $threshold% threshold)"
        return 1
    fi
}

# Main health checks
echo "=== Infrastructure Health Check ==="
echo ""

echo "--- Edge Services ---"
check_service "VIP HTTPS" "https://$VIP"
check_service "App" "https://app.$DOMAIN_BASE"
check_service "PocketBase" "https://pb.$DOMAIN_BASE"
check_service "Grafana" "https://metrics.$DOMAIN_BASE"
check_service "Uptime Kuma" "https://status.$DOMAIN_BASE"
echo ""

echo "--- Container Status ---"
for edge in "$EDGE_A_NAME" "$EDGE_B_NAME"; do
    check_container "$edge" "traefik"
    check_container "$edge" "amnezia-vpn"
done
check_container "$APP_VM_NAME" "pocketbase"
check_container "$APP_VM_NAME" "clarity-web"
check_container "$MONITORING_VM_NAME" "prometheus"
check_container "$MONITORING_VM_NAME" "grafana"
echo ""

echo "--- System Resources ---"
for host in "$EDGE_A_NAME" "$EDGE_B_NAME" "$APP_VM_NAME" "$MONITORING_VM_NAME"; do
    check_disk_space "$host"
done
echo ""

echo "--- VRRP Status ---"
for host in "$EDGE_A_NAME" "$EDGE_B_NAME"; do
    status=$(ssh "$ADMIN_USER@$host" "ip addr show | grep -q '$VIP' && echo 'MASTER' || echo 'BACKUP'" 2>/dev/null || echo "ERROR")
    if [[ "$status" == "MASTER" ]]; then
        echo -e "${GREEN}✓${NC} $host: $status"
    else
        echo -e "  $host: $status"
    fi
done
echo ""

echo "--- Backup Status ---"
# Check last backup time
last_backup=$(ssh "$ADMIN_USER@$APP_VM_NAME" "ls -t /opt/clarity/backups/*.tar 2>/dev/null | head -1 | xargs -r stat -c '%y'" 2>/dev/null || echo "No backups found")
echo "Last app backup: $last_backup"

# Check PBS status
if ssh "$ADMIN_USER@$PBS_VM_NAME" "systemctl is-active proxmox-backup" &>/dev/null; then
    echo -e "${GREEN}✓${NC} PBS: Active"
else
    echo -e "${RED}✗${NC} PBS: Not active"
fi
echo ""

echo "=== Health Check Complete ==="