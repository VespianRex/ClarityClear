# Alpine Build Pipeline Cleanup & Idempotence Guide

This document outlines the cleanup and idempotence procedures for the Alpine edge VM build pipeline, ensuring reliable and repeatable builds.

## Overview

The Alpine build pipeline creates several artifacts during execution:
- **Remote artifacts**: Log files, status markers, temporary scripts on Proxmox host
- **VM artifacts**: Virtual machine instance and disk images
- **Local artifacts**: SSH test logs and archived build logs

To maintain pipeline idempotence, these artifacts must be properly cleaned between builds.

## Automated Cleanup

### Primary Cleanup Script

Use the automated cleanup script before re-running builds:

```bash
./infra/scripts/cleanup-alpine-build.sh
```

#### Options:
- `--vmid VMID` - Target VM ID (default: 9008)
- `--archive-logs` - Archive remote logs before cleanup (default: enabled)
- `--no-archive-logs` - Skip log archiving
- `--dry-run` - Show what would be cleaned without executing
- `--help` - Show usage information

#### Examples:
```bash
# Standard cleanup with log archiving
./infra/scripts/cleanup-alpine-build.sh

# Cleanup different VM ID
./infra/scripts/cleanup-alpine-build.sh --vmid 9009

# Test cleanup without making changes
./infra/scripts/cleanup-alpine-build.sh --dry-run

# Quick cleanup without archiving logs
./infra/scripts/cleanup-alpine-build.sh --no-archive-logs
```

## Manual Cleanup Procedures

If automated cleanup fails or you need granular control:

### 1. Remote Proxmox Host Cleanup

Connect to the Proxmox host and clean build artifacts:

```bash
# Connect to Proxmox host
ssh root@192.168.0.33

# Stop any running build processes
pkill -f 'alpine-build-run.sh' || true
pkill -f 'alpine-make-vm-image' || true

# Remove temporary build files
rm -f /tmp/alpine-build.log
rm -f /tmp/alpine-build.status
rm -f /tmp/alpine-build.exit
rm -f /tmp/alpine-build.pid
rm -f /tmp/alpine-build-summary.txt
rm -f /tmp/alpine-build-run.sh
rm -f /tmp/alpine-rc-*.log
rm -f /tmp/alpine-network.log
rm -rf /tmp/alpine-builder

# Stop and destroy the VM (replace 9008 with your VMID)
qm stop 9008 2>/dev/null || true
qm destroy 9008 2>/dev/null || true

# Remove old disk image
rm -f /var/lib/vz/images/alpine-ssh-custom.qcow2
```

### 2. Local Cleanup

Clean local temporary files and manage log archives:

```bash
# Remove SSH test temporary files
rm -f /tmp/ssh-test-*.log

# Optional: Clean old log archives (older than 30 days)
find ./infra/logs -type f \( -name "*.log" -o -name "*.txt" \) -mtime +30 -delete
find ./infra/logs -type d -empty -delete
```

## Build Pipeline Idempotence

### Pre-Build Checklist

Before running `./infra/build-alpine-image-corrected.sh`:

1. ✅ Run cleanup script: `./infra/scripts/cleanup-alpine-build.sh`
2. ✅ Verify SSH connectivity: `ssh root@192.168.0.33 echo "Connected"`
3. ✅ Check disk space on Proxmox: `ssh root@192.168.0.33 df -h`
4. ✅ Ensure no conflicting VMs exist: `ssh root@192.168.0.33 qm status 9008` (should fail)

### Post-Build Validation

After successful build completion:

1. ✅ Archive logs automatically (if enabled in cleanup script)
2. ✅ Test VM connectivity: `./infra/scripts/test-alpine-connectivity.sh`
3. ✅ Verify VM configuration: `ssh root@192.168.0.33 qm config 9008`
4. ✅ Check guest agent: `ssh root@192.168.0.33 qm agent 9008 ping`

## Log Management

### Archive Structure

Logs are automatically archived to `infra/logs/YYYY-MM-DD/` with timestamps:

```
infra/logs/2025-09-24/
├── alpine-build-20-15.log          # Main build log
├── alpine-build-status-20-15.txt   # Build status marker
├── alpine-build-exit-20-15.txt     # Exit code
├── alpine-build-summary-20-15.txt  # Build summary
├── alpine-rc-status-20-15.log      # Service status
├── alpine-network-20-15.log        # Network configuration
└── connectivity-check-20-15.txt    # Post-build connectivity
```

### Log Rotation

- Logs older than 30 days are automatically removed during cleanup
- Archive before cleanup to preserve important build history
- Use `--no-archive-logs` only for development/testing builds

## Environment Variables

Key environment variables that affect cleanup behavior:

```bash
export REMOTE_HOST="root@192.168.0.33"           # Proxmox host
export SSH_KEY_PATH="$HOME/.ssh/id_ed25519_clarity"  # SSH key
export VMID="9008"                                # Target VM ID
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Test SSH connectivity
   ssh -i ~/.ssh/id_ed25519_clarity root@192.168.0.33 echo "test"
   ```

2. **VM Still Running**
   ```bash
   # Force stop and destroy
   ssh root@192.168.0.33 "qm stop 9008 --skiplock || qm destroy 9008 --skiplock"
   ```

3. **Disk Space Full**
   ```bash
   # Check and clean Proxmox storage
   ssh root@192.168.0.33 "df -h && qm list && lvs"
   ```

4. **Process Still Running**
   ```bash
   # Find and kill hanging processes
   ssh root@192.168.0.33 "ps aux | grep alpine"
   ssh root@192.168.0.33 "pkill -f alpine-make-vm-image"
   ```

### Recovery Procedures

If builds consistently fail after cleanup:

1. **Full Reset**:
   ```bash
   ./infra/scripts/cleanup-alpine-build.sh --dry-run  # Verify what will be cleaned
   ./infra/scripts/cleanup-alpine-build.sh           # Execute cleanup
   ./infra/build-alpine-image-corrected.sh --follow  # Fresh build
   ```

2. **Verify Template Source**:
   ```bash
   # Check if alpine-make-vm-image is accessible
   ssh root@192.168.0.33 "wget -q --spider https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.3/alpine-make-vm-image"
   ```

3. **Check Proxmox Resources**:
   ```bash
   # Verify storage and compute availability
   ssh root@192.168.0.33 "pvesm status && qm list && free -h"
   ```

## Integration with CI/CD

For automated pipeline integration:

```bash
# In CI script or Makefile
make edge-clean:
	./infra/scripts/cleanup-alpine-build.sh --no-archive-logs

make edge-build: edge-clean
	./infra/build-alpine-image-corrected.sh

make edge-validate:
	./infra/scripts/test-alpine-connectivity.sh
```

This ensures each CI run starts with a clean state and validates results consistently.