#!/bin/bash
#
# create-alpine-template.sh - Automated Alpine VM template creation script
#
# This script creates a Proxmox VM template from a successfully built Alpine edge VM,
# enabling rapid deployment of additional edge nodes with consistent configuration.
#
# Usage:
#   ./infra/scripts/create-alpine-template.sh [--source-vmid VMID] [--template-id TMPL_ID] [--dry-run]
#
# Options:
#   --source-vmid VMID    Source VM to convert to template (default: 9008)
#   --template-id TMPL_ID Template ID to create (default: 9000)
#   --template-name NAME  Template name (default: alpine-edge-template)
#   --backup-source       Backup source VM before conversion (default: true)
#   --dry-run            Show what would be done without executing
#   --help               Show this help message
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
# Requires local python3 for JSON parsing fallback when jq is unavailable on Proxmox host.
REMOTE_HOST="${REMOTE_HOST:-root@192.168.0.33}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519_clarity}"
SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
  -o BatchMode=yes
)

SOURCE_VMID="${SOURCE_VMID:-9008}"
TEMPLATE_ID="${TEMPLATE_ID:-9000}"
TEMPLATE_NAME="${TEMPLATE_NAME:-alpine-edge-template}"
BACKUP_SOURCE=true
DRY_RUN=false

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
}

log() {
  printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"
}

dry_echo() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] $*"
  else
    "$@"
  fi
}

verify_source_vm() {
  log "Verifying source VM $SOURCE_VMID"

  # Check VM exists
  if ! ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm status $SOURCE_VMID >/dev/null 2>&1"; then
    log "ERROR: Source VM $SOURCE_VMID does not exist"
    return 1
  fi

  # Check VM is stopped
  local vm_status
  vm_status=$(ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm status $SOURCE_VMID" | awk '{print $2}')
  if [[ "$vm_status" == "running" ]]; then
    log "Source VM $SOURCE_VMID is running, stopping it first"
    if [[ "$DRY_RUN" != "true" ]]; then
      ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm stop $SOURCE_VMID"
      # Wait for shutdown
      for i in {1..30}; do
        vm_status=$(ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm status $SOURCE_VMID" | awk '{print $2}')
        [[ "$vm_status" == "stopped" ]] && break
        sleep 2
      done
    fi
  fi

  log "Source VM $SOURCE_VMID is ready ($vm_status)"
}

backup_source_vm() {
  if [[ "$BACKUP_SOURCE" != "true" ]]; then
    log "Skipping source VM backup (--no-backup-source specified)"
    return
  fi

  log "Creating backup of source VM $SOURCE_VMID"

  local timestamp
  timestamp=$(date '+%Y%m%d_%H%M%S')
  local backup_notes="Pre-template backup created $(date)"

  if [[ "$DRY_RUN" != "true" ]]; then
    # Create backup using Proxmox backup system
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "vzdump $SOURCE_VMID --mode stop --compress lz4 --notes '$backup_notes'" || {
      log "Warning: Backup creation failed, continuing anyway"
    }
  else
    log "Would create backup of VM $SOURCE_VMID"
  fi
}

check_template_conflicts() {
  log "Checking for template ID conflicts"

  if ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm status $TEMPLATE_ID >/dev/null 2>&1"; then
    log "ERROR: VM/Template with ID $TEMPLATE_ID already exists"
    log "Use --template-id to specify a different ID or remove the existing VM/template"
    return 1
  fi

  log "Template ID $TEMPLATE_ID is available"
}

prepare_vm_for_template() {
  log "Preparing VM $SOURCE_VMID for template conversion"

  # SSH into the VM and clean it for template use
  log "Connecting to VM to clean up for template use"

  if [[ "$DRY_RUN" != "true" ]]; then
    # Start VM temporarily for cleanup
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm start $SOURCE_VMID"

    # Wait for VM to be ready
    log "Waiting for VM to start and guest agent to be ready"
    sleep 30

    # Wait for guest agent
    for i in {1..30}; do
      if ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm agent $SOURCE_VMID ping >/dev/null 2>&1"; then
        break
      fi
      sleep 2
    done

    # Get VM IP for SSH cleanup
    local interfaces_json vm_ip
    interfaces_json=$(ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm guest cmd $SOURCE_VMID network-get-interfaces 2>/dev/null" 2>/dev/null || true)

    if command -v python3 >/dev/null 2>&1 && [[ -n "$interfaces_json" ]]; then
      vm_ip=$(python3 - <<'PY'
import json, sys
data = sys.stdin.read().strip()
if not data:
    sys.exit()
try:
    interfaces = json.loads(data)
except json.JSONDecodeError:
    sys.exit()

for iface in interfaces:
    for addr in iface.get("ip-addresses", []):
        ip = addr.get("ip-address")
        if ip and not ip.startswith("127.") and ":" not in ip:
            print(ip)
            sys.exit()
PY
"$interfaces_json")
    fi

    if [[ -z "$vm_ip" && -n "$interfaces_json" ]]; then
      vm_ip=$(echo "$interfaces_json" | grep -Eo '"ip-address"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' | head -n1 | awk -F'"' '{print $4}')
    fi

    if [[ -n "$vm_ip" ]]; then
      log "Cleaning VM at $vm_ip for template use"

      # Clean up SSH host keys and other unique identifiers
      ssh "${SSH_OPTS[@]}" "VespianRex@$vm_ip" 'sudo bash -c "
        # Remove SSH host keys (will be regenerated on first boot)
        rm -f /etc/ssh/ssh_host_*

        # Clear machine ID
        echo > /etc/machine-id

        # Clear command history
        history -c
        rm -f ~/.bash_history /home/VespianRex/.bash_history /root/.bash_history

        # Clean log files
        find /var/log -type f -exec truncate -s 0 {} \\;

        # Clear temporary files
        rm -rf /tmp/* /var/tmp/*

        # Clear package cache
        apk cache clean

        # Clear network configuration artifacts that should be dynamic
        # (keeping the base configuration but removing lease files)
        rm -f /var/lib/dhcp/dhclient.*

        echo \"VM cleaned for template use\"
      "' || log "Warning: VM cleanup partially failed"
    else
      log "Warning: Could not determine VM IP for cleanup"
    fi

    # Stop VM after cleanup
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm stop $SOURCE_VMID"

    # Wait for shutdown
    for i in {1..30}; do
      local vm_status
      vm_status=$(ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm status $SOURCE_VMID" | awk '{print $2}')
      [[ "$vm_status" == "stopped" ]] && break
      sleep 2
    done
  else
    log "Would start VM, clean it up, and stop it"
  fi
}

create_template() {
  log "Converting VM $SOURCE_VMID to template $TEMPLATE_ID"

  if [[ "$DRY_RUN" != "true" ]]; then
    # Clone the VM to the template ID
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm clone $SOURCE_VMID $TEMPLATE_ID --name $TEMPLATE_NAME --full"

    # Convert clone to template
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm template $TEMPLATE_ID"

    # Add template description
    local description="Alpine Edge VM Template
Created: $(date)
Source VM: $SOURCE_VMID
Base Image: Alpine Linux 3.20 with SSH, QEMU Guest Agent
Default User: VespianRex
Use: qm clone $TEMPLATE_ID <new_vmid> --name <vm_name>"

    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm set $TEMPLATE_ID --description '$description'"
  else
    log "Would clone VM $SOURCE_VMID to $TEMPLATE_ID and convert to template"
  fi

  log "Template $TEMPLATE_ID ($TEMPLATE_NAME) created successfully"
}

validate_template() {
  log "Validating template $TEMPLATE_ID"

  if [[ "$DRY_RUN" != "true" ]]; then
    # Check template exists and is marked as template
    local config
    config=$(ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm config $TEMPLATE_ID")

    if echo "$config" | grep -q "template: 1"; then
      log "✅ Template validation successful"

      # Show template configuration
      log "Template configuration:"
      echo "$config" | sed 's/^/  /'
    else
      log "❌ Template validation failed - not marked as template"
      return 1
    fi
  else
    log "Would validate template configuration"
  fi
}

create_clone_script() {
  log "Creating convenience script for template cloning"

  local clone_script="$PROJECT_ROOT/infra/scripts/clone-from-alpine-template.sh"

  cat > "$clone_script" <<'EOF'
#!/bin/bash
#
# clone-from-alpine-template.sh - Clone new VMs from Alpine template
#
# Usage: ./clone-from-alpine-template.sh <vmid> <vm_name> [--start]
#

set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@192.168.0.33}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519_clarity}"
SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o BatchMode=yes
)

TEMPLATE_ID="9000"
NEW_VMID="${1:-}"
NEW_NAME="${2:-}"
START_VM=false

if [[ "${3:-}" == "--start" ]]; then
  START_VM=true
fi

if [[ -z "$NEW_VMID" || -z "$NEW_NAME" ]]; then
  echo "Usage: $0 <vmid> <vm_name> [--start]"
  exit 1
fi

echo "🔄 Cloning template $TEMPLATE_ID to VM $NEW_VMID ($NEW_NAME)"

ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm clone $TEMPLATE_ID $NEW_VMID --name $NEW_NAME --full"

echo "📝 Configuring new VM..."
ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm set $NEW_VMID --onboot 0"

if [[ "$START_VM" == "true" ]]; then
  echo "🚀 Starting VM $NEW_VMID"
  ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm start $NEW_VMID"

  echo "⏳ Waiting for guest agent..."
  sleep 30

  if ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm agent $NEW_VMID ping >/dev/null 2>&1"; then
    echo "📋 Getting VM network info..."
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm guest cmd $NEW_VMID network-get-interfaces" || true
  fi
fi

echo "✅ VM $NEW_VMID ($NEW_NAME) cloned from template successfully"
EOF

  chmod +x "$clone_script"
  log "Clone script created: $clone_script"
}

show_usage_examples() {
  log ""
  log "Template creation completed successfully!"
  log ""
  log "📋 Template Information:"
  log "  Template ID: $TEMPLATE_ID"
  log "  Template Name: $TEMPLATE_NAME"
  log "  Source VM: $SOURCE_VMID"
  log ""
  log "🚀 Usage Examples:"
  log "  # Clone template to new VM"
  log "  ssh $REMOTE_HOST 'qm clone $TEMPLATE_ID 9009 --name edge-node-2 --full'"
  log ""
  log "  # Use convenience script"
  log "  ./infra/scripts/clone-from-alpine-template.sh 9009 edge-node-2 --start"
  log ""
  log "  # List all templates"
  log "  ssh $REMOTE_HOST 'qm list | grep template'"
  log ""
}

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --source-vmid)
        SOURCE_VMID="$2"
        shift 2
        ;;
      --template-id)
        TEMPLATE_ID="$2"
        shift 2
        ;;
      --template-name)
        TEMPLATE_NAME="$2"
        shift 2
        ;;
      --backup-source)
        BACKUP_SOURCE=true
        shift
        ;;
      --no-backup-source)
        BACKUP_SOURCE=false
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  log "Starting Alpine VM template creation"
  log "Source VM: $SOURCE_VMID -> Template: $TEMPLATE_ID ($TEMPLATE_NAME)"
  [[ "$DRY_RUN" == "true" ]] && log "DRY RUN MODE - no changes will be made"

  # Test SSH connectivity
  if ! ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "echo 'SSH connectivity test successful'" >/dev/null 2>&1; then
    log "ERROR: Cannot connect to $REMOTE_HOST via SSH"
    log "Check REMOTE_HOST and SSH_KEY_PATH settings"
    exit 1
  fi

  # Execute template creation steps
  verify_source_vm
  check_template_conflicts
  backup_source_vm
  prepare_vm_for_template
  create_template
  validate_template
  create_clone_script
  show_usage_examples

  log "Template creation completed successfully!"
}

main "$@"
