#!/bin/bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════════
#  Proxmox VM Snapshot Manager for Deployments
#  Run on Proxmox host to create/manage deployment snapshots
# ════════════════════════════════════════════════════════════════════

# Configuration
VMID=203  # App VM
SNAPSHOT_PREFIX="auto-deploy"
MAX_SNAPSHOTS=10  # Keep last 10 deployment snapshots

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2; }

# ═══════════════════════════════════════════════════════════════════
# Functions
# ═══════════════════════════════════════════════════════════════════

create_snapshot() {
    local vmid=$1
    local description=$2
    local snapshot_name="${SNAPSHOT_PREFIX}-$(date +%s)"

    log "Creating VM snapshot: $snapshot_name"

    if qm snapshot "$vmid" "$snapshot_name" --description "$description"; then
        log "✓ Snapshot created: $snapshot_name"
        echo "$snapshot_name"
        return 0
    else
        error "Failed to create snapshot"
        return 1
    fi
}

list_snapshots() {
    local vmid=$1

    log "Listing snapshots for VM $vmid:"
    qm listsnapshot "$vmid" | grep "$SNAPSHOT_PREFIX" || echo "No deployment snapshots found"
}

cleanup_old_snapshots() {
    local vmid=$1

    log "Cleaning up old snapshots (keeping last $MAX_SNAPSHOTS)..."

    # Get all auto-deploy snapshots, sorted by timestamp
    local snapshots=$(qm listsnapshot "$vmid" 2>/dev/null | grep "$SNAPSHOT_PREFIX" | awk '{print $2}' | sort -r)
    local count=0

    for snap in $snapshots; do
        count=$((count + 1))
        if [ $count -gt $MAX_SNAPSHOTS ]; then
            log "Deleting old snapshot: $snap"
            qm delsnapshot "$vmid" "$snap" || warn "Failed to delete $snap"
        fi
    done

    log "✓ Cleanup complete"
}

rollback_to_snapshot() {
    local vmid=$1
    local snapshot_name=$2

    warn "Rolling back VM $vmid to snapshot: $snapshot_name"
    warn "This will STOP the VM and restore to previous state!"

    # Stop VM
    log "Stopping VM $vmid..."
    qm stop "$vmid" || true
    sleep 5

    # Rollback
    log "Rolling back to snapshot $snapshot_name..."
    if qm rollback "$vmid" "$snapshot_name"; then
        log "✓ Rollback successful"

        # Start VM
        log "Starting VM $vmid..."
        qm start "$vmid"
        sleep 10

        log "✓ VM started. Please verify services are working."
        return 0
    else
        error "Rollback failed!"
        return 1
    fi
}

get_latest_snapshot() {
    local vmid=$1

    qm listsnapshot "$vmid" 2>/dev/null | \
        grep "$SNAPSHOT_PREFIX" | \
        awk '{print $2}' | \
        sort -r | \
        head -1
}

# ═══════════════════════════════════════════════════════════════════
# Main Script
# ═══════════════════════════════════════════════════════════════════

case "${1:-}" in
    create)
        DESCRIPTION="${2:-Automatic deployment snapshot}"
        SNAPSHOT_NAME=$(create_snapshot $VMID "$DESCRIPTION")
        echo "$SNAPSHOT_NAME"
        ;;

    list)
        list_snapshots $VMID
        ;;

    cleanup)
        cleanup_old_snapshots $VMID
        ;;

    rollback)
        if [ -z "${2:-}" ]; then
            # Rollback to latest snapshot
            SNAPSHOT=$(get_latest_snapshot $VMID)
            if [ -z "$SNAPSHOT" ]; then
                error "No snapshots found to rollback to"
                exit 1
            fi
            warn "Rolling back to latest snapshot: $SNAPSHOT"
        else
            # Rollback to specific snapshot
            SNAPSHOT=$2
        fi

        read -p "Are you sure you want to rollback VM $VMID to $SNAPSHOT? (yes/NO) " -r
        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            rollback_to_snapshot $VMID "$SNAPSHOT"
        else
            log "Rollback cancelled"
        fi
        ;;

    latest)
        get_latest_snapshot $VMID
        ;;

    help|--help|-h)
        cat << EOF
Proxmox VM Snapshot Manager for Deployments

Usage:
  $(basename $0) create [description]    - Create new deployment snapshot
  $(basename $0) list                    - List all deployment snapshots
  $(basename $0) cleanup                 - Remove old snapshots (keep last $MAX_SNAPSHOTS)
  $(basename $0) rollback [snapshot]     - Rollback to snapshot (latest if not specified)
  $(basename $0) latest                  - Show latest snapshot name

Examples:
  # Create snapshot before deployment
  $(basename $0) create "Before commit abc1234"

  # List all snapshots
  $(basename $0) list

  # Rollback to latest snapshot
  $(basename $0) rollback

  # Rollback to specific snapshot
  $(basename $0) rollback auto-deploy-1727711234

Configuration:
  VMID: $VMID (App VM)
  Snapshot prefix: $SNAPSHOT_PREFIX
  Max snapshots: $MAX_SNAPSHOTS
EOF
        ;;

    *)
        error "Invalid command: ${1:-}"
        echo "Run '$(basename $0) help' for usage"
        exit 1
        ;;
esac