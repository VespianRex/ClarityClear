#!/bin/bash
#
# cleanup-alpine-build.sh - Automated cleanup script for Alpine VM build pipeline
#
# This script ensures idempotent builds by cleaning up previous build artifacts
# both locally and remotely. Use this before re-running build-alpine-image-corrected.sh
# to ensure a clean state.
#
# Usage:
#   ./infra/scripts/cleanup-alpine-build.sh [--vmid VMID] [--archive-logs] [--dry-run]
#
# Options:
#   --vmid VMID       Target VM ID to clean (default: 9008)
#   --archive-logs    Archive remote logs before cleanup (default: true)
#   --dry-run        Show what would be cleaned without executing
#   --help           Show this help message
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
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

VMID="${VMID:-9008}"
ARCHIVE_LOGS=true
DRY_RUN=false

# Remote file paths to clean
REMOTE_FILES=(
  "/tmp/alpine-build.log"
  "/tmp/alpine-build.status"
  "/tmp/alpine-build.exit"
  "/tmp/alpine-build.pid"
  "/tmp/alpine-build-summary.txt"
  "/tmp/alpine-build-run.sh"
  "/tmp/alpine-rc-status.log"
  "/tmp/alpine-rc-status.err"
  "/tmp/alpine-rc-update.log"
  "/tmp/alpine-rc-update.err"
  "/tmp/alpine-network.log"
  "/tmp/alpine-network.err"
  "/tmp/alpine-builder"  # Build directory
)

# Local directories to clean
LOCAL_TEMP_PATTERN="/tmp/ssh-test-*.log"

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

archive_remote_logs() {
  if [[ "$ARCHIVE_LOGS" != "true" ]]; then
    log "Skipping log archiving (--no-archive-logs specified)"
    return
  fi

  local timestamp
  timestamp=$(date '+%Y%m%d-%H%M')
  local log_dir="$PROJECT_ROOT/infra/logs/$(date '+%Y-%m-%d')"

  log "Creating local log directory: $log_dir"
  dry_echo mkdir -p "$log_dir"

  log "Archiving remote logs with timestamp $timestamp"

  # Check which remote files exist and copy them
  for remote_file in "${REMOTE_FILES[@]}"; do
    [[ "$remote_file" == */alpine-builder ]] && continue  # Skip directory

    if ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "test -f '$remote_file'" 2>/dev/null; then
      local basename
      basename=$(basename "$remote_file")
      local local_file="$log_dir/${basename%.log}-${timestamp}.log"
      [[ "$basename" != *.log ]] && local_file="$log_dir/${basename}-${timestamp}.txt"

      log "  $remote_file -> $local_file"
      if [[ "$DRY_RUN" != "true" ]]; then
        scp "${SSH_OPTS[@]}" "$REMOTE_HOST:$remote_file" "$local_file" 2>/dev/null || {
          log "  Warning: Failed to copy $remote_file"
        }
      fi
    fi
  done
}

cleanup_remote_files() {
  log "Cleaning remote build artifacts on $REMOTE_HOST"

  for remote_file in "${REMOTE_FILES[@]}"; do
    log "  Removing $remote_file"
    if [[ "$DRY_RUN" != "true" ]]; then
      ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "rm -rf '$remote_file'" 2>/dev/null || true
    fi
  done

  # Stop any running Alpine build processes
  log "Stopping any running Alpine build processes"
  if [[ "$DRY_RUN" != "true" ]]; then
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "pkill -f 'alpine-build-run.sh' || true" 2>/dev/null || true
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "pkill -f 'alpine-make-vm-image' || true" 2>/dev/null || true
  fi
}

cleanup_vm_artifacts() {
  log "Cleaning VM $VMID artifacts"

  # Check if VM exists and stop it
  if [[ "$DRY_RUN" != "true" ]]; then
    if ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm status $VMID >/dev/null 2>&1"; then
      log "  Stopping VM $VMID"
      ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm stop $VMID 2>/dev/null || true"
      sleep 3

      log "  Destroying VM $VMID"
      ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "qm destroy $VMID 2>/dev/null || true"
    else
      log "  VM $VMID does not exist, skipping VM cleanup"
    fi
  else
    log "  Would stop and destroy VM $VMID"
  fi

  # Remove old disk image
  local image_path="/var/lib/vz/images/alpine-ssh-custom.qcow2"
  log "  Removing old image: $image_path"
  if [[ "$DRY_RUN" != "true" ]]; then
    ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "rm -f '$image_path'" 2>/dev/null || true
  fi
}

cleanup_local_temp() {
  log "Cleaning local temporary files"
  log "  Removing: $LOCAL_TEMP_PATTERN"
  if [[ "$DRY_RUN" != "true" ]]; then
    rm -f $LOCAL_TEMP_PATTERN 2>/dev/null || true
  fi
}

rotate_old_logs() {
  local log_base="$PROJECT_ROOT/infra/logs"
  local retention_days=30

  log "Rotating logs older than $retention_days days in $log_base"

  if [[ "$DRY_RUN" != "true" ]]; then
    find "$log_base" -type f -name "*.log" -mtime +$retention_days -delete 2>/dev/null || true
    find "$log_base" -type f -name "*.txt" -mtime +$retention_days -delete 2>/dev/null || true
    # Remove empty directories
    find "$log_base" -type d -empty -delete 2>/dev/null || true
  else
    log "  Would remove files older than $retention_days days"
    find "$log_base" -type f \( -name "*.log" -o -name "*.txt" \) -mtime +$retention_days 2>/dev/null | while read -r old_file; do
      log "    Would delete: $old_file"
    done
  fi
}

main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --vmid)
        VMID="$2"
        shift 2
        ;;
      --archive-logs)
        ARCHIVE_LOGS=true
        shift
        ;;
      --no-archive-logs)
        ARCHIVE_LOGS=false
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

  log "Starting Alpine build cleanup (VM $VMID)"
  [[ "$DRY_RUN" == "true" ]] && log "DRY RUN MODE - no changes will be made"

  # Test SSH connectivity
  if ! ssh "${SSH_OPTS[@]}" "$REMOTE_HOST" "echo 'SSH connectivity test successful'" >/dev/null 2>&1; then
    log "ERROR: Cannot connect to $REMOTE_HOST via SSH"
    log "Check REMOTE_HOST and SSH_KEY_PATH settings"
    exit 1
  fi

  # Execute cleanup steps
  if [[ "$ARCHIVE_LOGS" == "true" ]]; then
    archive_remote_logs
  fi

  cleanup_remote_files
  cleanup_vm_artifacts
  cleanup_local_temp
  rotate_old_logs

  log "Cleanup completed successfully"
  log ""
  log "Pipeline is now ready for idempotent build execution:"
  log "  ./infra/build-alpine-image-corrected.sh [--follow]"
}

main "$@"