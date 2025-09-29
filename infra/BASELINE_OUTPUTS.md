# Alpine Edge Baseline Outputs (September 24, 2025)

This document captures the reference outputs collected after successfully rebuilding VM `9008` using `infra/build-alpine-image-corrected.sh`.

## VM Details
- **VMID**: 9008
- **Hostname**: alpine-ssh-final
- **IP (DHCP)**: 192.168.0.220
- **MAC**: BC:24:11:59:88:50
- **Boot Order**: scsi0

Source: `infra/logs/2025-09-24/qm-config-9008.txt` and `infra/logs/2025-09-24/qm-agent-network.txt`.

## Build Artifacts
- `/tmp/alpine-build.log`
- `/tmp/alpine-build-summary.txt`
- `/tmp/alpine-rc-update.log`
- `/tmp/alpine-rc-status.log`
- `/tmp/alpine-network.log`

All artifacts archived in `infra/logs/2025-09-24/`.

## Connectivity Check
```
$(cat infra/logs/2025-09-24/connectivity-check.txt)
```

The connectivity script confirms:
- ICMP ping success
- SSH login to `VespianRex` user
- `rc-service sshd status` and `rc-service qemu-guest-agent status` both in `started` state.

## Next Steps
Future builds should append to this document with new dated sections, highlighting deviations from baseline (e.g., IP changes, package updates).
