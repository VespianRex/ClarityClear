#!/bin/bash
#
# clone-from-alpine-template.sh - Clone new VMs from Alpine template
#
# Usage: ./infra/scripts/clone-from-alpine-template.sh <vmid> <vm_name> [--start]
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

TEMPLATE_ID="${TEMPLATE_ID:-9000}"
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
