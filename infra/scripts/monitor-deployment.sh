#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

clear
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Infrastructure Deployment Monitor     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Monitor templates
log "Template Status:"
ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 "
    echo -n '  Debian Template (9000): '
    if qm config 9000 >/dev/null 2>&1; then
        echo '✅ Ready'
    else
        if ls /var/lib/vz/template/iso/debian*.qcow2 >/dev/null 2>&1; then
            echo '⏳ Creating...'
        else
            echo '📥 Downloading...'
        fi
    fi

    echo -n '  Alpine Template (9001): '
    if qm config 9001 >/dev/null 2>&1; then
        echo '✅ Ready'
    else
        if ls /var/lib/vz/template/iso/*alpine*.qcow2 >/dev/null 2>&1; then
            echo '⏳ Creating...'
        else
            echo '📥 Downloading...'
        fi
    fi
" 2>/dev/null

echo ""

# Monitor VMs
log "VM Status:"
ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 "qm list 2>/dev/null | grep -v VMID || echo '  No VMs yet...'" 2>/dev/null

echo ""

# Check if OpenTofu is running
if pgrep -f "tofu apply" >/dev/null; then
    info "OpenTofu is running..."
fi

# Check if Ansible is running
if pgrep -f "ansible-playbook" >/dev/null; then
    info "Ansible configuration in progress..."
fi

# Check deployment log
if [ -f deployment-full.log ]; then
    echo ""
    log "Recent activity:"
    tail -5 deployment-full.log | sed 's/^/  /'
fi

echo ""
echo "Press Ctrl+C to stop monitoring"