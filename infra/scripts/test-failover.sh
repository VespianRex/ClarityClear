#!/usr/bin/env bash
set -euo pipefail

# Test HA failover for Edge VMs

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }

# Load environment
cd "$(dirname "$0")/.."
source .env

# Test connectivity to VIP
test_vip() {
    log "Testing VIP connectivity ($VIP)..."
    if ping -c 3 "$VIP" > /dev/null 2>&1; then
        log "VIP is reachable"
        return 0
    else
        error "VIP is not reachable"
        return 1
    fi
}

# Check which node is master
check_master() {
    log "Checking VRRP master status..."
    for host in "$EDGE_A_NAME" "$EDGE_B_NAME"; do
        ip=$(ssh "$ADMIN_USER@$host" "hostname -I | awk '{print \$1}'" 2>/dev/null || echo "unknown")
        status=$(ssh "$ADMIN_USER@$host" "ip addr show | grep -q '$VIP' && echo 'MASTER' || echo 'BACKUP'" 2>/dev/null || echo "ERROR")
        echo "  $host ($ip): $status"
    done
}

# Test service availability
test_services() {
    log "Testing service availability through VIP..."

    # Test HTTP redirect
    if curl -sI "http://$VIP" | grep -q "301\|302"; then
        log "  HTTP redirect: OK"
    else
        warn "  HTTP redirect: FAILED"
    fi

    # Test HTTPS
    if curl -sk "https://$VIP" > /dev/null 2>&1; then
        log "  HTTPS: OK"
    else
        warn "  HTTPS: FAILED"
    fi

    # Test specific endpoints
    for domain in "app.$DOMAIN_BASE" "pb.$DOMAIN_BASE" "metrics.$DOMAIN_BASE"; do
        if curl -sk --resolve "$domain:443:$VIP" "https://$domain" > /dev/null 2>&1; then
            log "  $domain: OK"
        else
            warn "  $domain: FAILED"
        fi
    done
}

# Simulate failover
simulate_failover() {
    log "Simulating failover..."

    # Find current master
    current_master=""
    for host in "$EDGE_A_NAME" "$EDGE_B_NAME"; do
        if ssh "$ADMIN_USER@$host" "ip addr show | grep -q '$VIP'" 2>/dev/null; then
            current_master="$host"
            break
        fi
    done

    if [[ -z "$current_master" ]]; then
        error "Could not determine current master"
        return 1
    fi

    log "Current master: $current_master"
    log "Stopping keepalived on $current_master to trigger failover..."

    ssh "$ADMIN_USER@$current_master" "sudo systemctl stop keepalived" || \
        ssh "$ADMIN_USER@$current_master" "sudo rc-service keepalived stop"

    log "Waiting for failover (10 seconds)..."
    sleep 10

    # Check new master
    check_master
    test_services

    log "Restarting keepalived on $current_master..."
    ssh "$ADMIN_USER@$current_master" "sudo systemctl start keepalived" || \
        ssh "$ADMIN_USER@$current_master" "sudo rc-service keepalived start"

    log "Waiting for recovery (10 seconds)..."
    sleep 10

    check_master
}

# Main execution
main() {
    log "Starting HA failover test"
    echo ""

    test_vip || exit 1
    echo ""

    check_master
    echo ""

    test_services
    echo ""

    read -p "Do you want to simulate a failover? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        simulate_failover
    fi

    echo ""
    log "HA failover test completed"
}

main "$@"