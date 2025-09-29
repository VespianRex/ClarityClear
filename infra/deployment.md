# Alpine Linux Custom Image Build Documentation

## Session Overview
This session focused on building a custom Alpine Linux image with SSH pre-installed to address ongoing SSH connectivity issues with standard Alpine cloud images in our Proxmox infrastructure deployment.

## Background Context
- Previous sessions had successfully deployed Debian VMs (IDs: backup-storage, clarity-app, monitoring, pbs-backup) with working SSH access
- Alpine VMs were problematic - cloud-init based Alpine deployments consistently failed SSH connectivity
- User explicitly requested building custom Alpine image with SSH pre-installed using multiple search agents
- User wanted to focus on the complex solution, not simplified alternatives

## Files Created During This Session

### 1. `/Users/alex/DEV/ClarityClear/infra/build-alpine-image-proxmox.sh`
- **Purpose**: Initial attempt at building Alpine image using alpine-make-vm-image
- **Status**: Failed due to apt package conflicts with Proxmox
- **Issue**: Attempted to install qemu-utils which would remove critical Proxmox packages (proxmox-ve, pve-container, etc.)
- **Error**: APT hook prevented package installation to protect Proxmox system integrity

### 2. `/Users/alex/DEV/ClarityClear/infra/build-alpine-image-fixed.sh`
- **Purpose**: Second attempt with error handling for repository issues
- **Status**: Failed - same package conflict issues
- **Issue**: Still tried to install packages that would break Proxmox installation

### 3. `/Users/alex/DEV/ClarityClear/infra/build-alpine-image-safe.sh`
- **Purpose**: Third attempt avoiding Proxmox package conflicts
- **Status**: Failed due to incorrect alpine-make-vm-image command syntax
- **Issue**: Used `--script-chroot ./setup-alpine-ssh.sh` instead of correct syntax
- **Error**: `qemu-nbd: Failed to blk_new_open './setup-alpine-ssh.sh': Image is not in qcow2 format`

### 4. `/Users/alex/DEV/ClarityClear/infra/build-alpine-image-corrected.sh`
- **Purpose**: Final working version with correct syntax
- **Status**: Successfully built Alpine image and created VM
- **VM Created**: ID 9008, name "alpine-ssh-final"
- **Image Details**: 3GB qcow2, expanded to 10GB, 106MB actual size

### 5. `/tmp/find_alpine_vm.sh`
- **Purpose**: Script to scan network and locate Alpine VM by SSH testing
- **Status**: Created and executed successfully
- **Result**: Failed to locate Alpine VM on network (SSH not responding)

## Research Phase (Multiple Search Agents Used)

### Search Agent 1: Alpine Image Building Research
- **Findings**: Documented alpine-make-vm-image, alpine-make-rootfs, mkimage.sh tools
- **Key Insight**: SSH not pre-installed by default in Alpine
- **Configuration**: Identified need for `apk add openssh`, `rc-update add sshd default`, `ssh-keygen -A`

### Search Agent 2: Debian/Proxmox Compatibility
- **Findings**: Package dependencies for alpine-make-vm-image on Debian
- **Key Dependencies**: qemu-utils, qemu-system
- **Issue Identified**: Potential conflicts with Proxmox packages

### Search Agent 3: Docker-Based Building
- **Findings**: Alternative approaches using Docker containers
- **Methods**: Docker export to qcow2, virt-make-fs conversion
- **Tools**: buildah, podman alternatives documented

### Search Agent 4: Packer Integration
- **Findings**: Packer QEMU builder for Alpine Linux
- **Repository**: LKummer/packer-alpine recommended
- **Configuration**: Detailed HCL templates and provisioner scripts

### Search Agent 5: Additional Methods
- **Findings**: Various Alpine building techniques and best practices
- **Security**: SSH key-based authentication recommendations
- **Architecture**: Multi-stage builds and optimization strategies

## Technical Implementation Details

### Alpine Make VM Image Process
1. **Downloaded**: alpine-make-vm-image v0.13.3 from GitHub
2. **Configuration**:
   - Image format: qcow2
   - Image size: 3GB (later expanded to 10GB)
   - Branch: v3.20 (Alpine Linux)
   - Serial console enabled
   - Packages: openssh openssh-server sudo qemu-guest-agent bash openrc curl wget

### Custom Setup Script (`setup-alpine-ssh.sh`)
```bash
# Key configurations applied:
- Alpine repositories: main + community
- Packages installed: openssh, openssh-server, openssh-client, sudo, qemu-guest-agent, curl, wget, bash, openrc
- Services enabled: sshd, qemu-guest-agent, networking, hostname
- User created: VespianRex with password ClarityInfra2025!
- SSH key installed: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJlA1A99bGtbYm1q/clybzBq1v0eJ8QaNzXwHUKV1WO
- SSH config: PermitRootLogin yes, PubkeyAuthentication yes, PasswordAuthentication yes
- Network: DHCP configuration for eth0
- Hostname: alpine-ssh
```

### VM Creation Process (VM ID 9008)
```bash
# VM Specifications:
- Name: alpine-ssh-final
- Memory: 2048MB with balloon 1024MB
- CPU: 2 cores
- Network: virtio NIC with MAC BC:24:11:2A:72:22 on vmbr0 bridge
- Storage: SCSI disk on local-lvm, 10GB
- Boot: Serial console enabled
- Agent: QEMU guest agent enabled
```

## Build Process Success Indicators
1. **Image Creation**: alpine-ssh.qcow2 successfully created (106MB actual size)
2. **Disk Import**: Successfully imported to Proxmox local-lvm storage
3. **VM Creation**: VM 9008 created without errors
4. **VM Start**: VM started successfully, status shows "running"
5. **Disk Resize**: Successfully expanded from 3GB to 10GB

## Issues Encountered and Analysis

### Primary Issue: SSH Connectivity Failure
- **Symptom**: VM running but not accessible via SSH on any scanned IP (192.168.0.50-200)
- **QEMU Guest Agent**: Not responding (`QEMU guest agent is not running`)
- **Network**: No IP address discoverable through standard scanning methods

### Boot Configuration Issue (Resolved)
- **Initial Problem**: VM configured to boot from network (boot: order=net0)
- **Resolution**: Changed to boot from disk (boot: order=scsi0)
- **Result**: VM restarts successfully but SSH issue persists

### Potential Root Causes for SSH Failure

#### 1. Network Configuration Issues
- DHCP client may not be starting properly
- Network interface (eth0) configuration might be incorrect
- Bridge networking (vmbr0) connectivity problems

#### 2. SSH Service Issues
- SSH daemon might not be starting on boot
- Service dependencies (networking, hostname) might not be resolved
- SSH configuration might have syntax errors

#### 3. System Boot Problems
- Bootloader (extlinux) configuration issues
- Kernel modules for virtio networking not loading
- Init system (OpenRC) service startup failures

#### 4. Alpine-Specific Issues
- Alpine's musl libc vs. glibc compatibility
- OpenRC service management differences from systemd
- Alpine's networking configuration format

## Current State

### Working Components
- ✅ Alpine image build process (alpine-make-vm-image)
- ✅ Custom setup script execution
- ✅ VM creation and disk import
- ✅ VM startup and running status
- ✅ Storage and memory allocation

### Non-Working Components
- ❌ SSH connectivity to Alpine VM
- ❌ QEMU guest agent communication
- ❌ Network IP address assignment/discovery
- ❌ Service verification within Alpine VM

### File Locations
- **Build Scripts**: `/Users/alex/DEV/ClarityClear/infra/build-alpine-image-*.sh`
- **VM Disk**: `/var/lib/vz/images/alpine-ssh-custom.qcow2` on Proxmox
- **Test Script**: `/tmp/find_alpine_vm.sh`
- **VM**: Proxmox VM ID 9008 "alpine-ssh-final"

## What Remains To Be Done

### Immediate Debugging Required
1. **Console Access**: Use Proxmox console to access VM directly and check:
   - Boot process completion
   - Network interface status (`ip addr show`)
   - SSH service status (`rc-service sshd status`)
   - System logs (`dmesg`, `/var/log/messages`)

2. **Network Troubleshooting**:
   - Verify DHCP client is running (`rc-service dhcp status`)
   - Check if interface gets IP (`ip route show`)
   - Test local connectivity within VM

3. **Service Verification**:
   - Confirm SSH daemon is running and listening on port 22
   - Verify firewall settings (if any)
   - Check SSH configuration syntax

### Long-term Solutions
1. **Image Rebuild**: If debugging reveals fundamental issues, rebuild with corrections
2. **Alternative Approach**: Consider using working Debian infrastructure instead
3. **Hybrid Solution**: Use Debian for edge servers, reserve Alpine for specific use cases

### Infrastructure Integration
- Once SSH connectivity is resolved, integrate Alpine VM into:
  - Keepalived HA configuration
  - Ansible inventory management
  - Overall infrastructure monitoring

## Lessons Learned
1. **Package Conflicts**: Proxmox systems require careful package management to avoid breaking core functionality
2. **Syntax Precision**: alpine-make-vm-image requires exact command syntax (script path as separate argument, not in --script-chroot)
3. **Testing Necessity**: VM creation success doesn't guarantee functional networking/SSH
4. **Alpine Complexity**: Alpine Linux networking and service management differs significantly from Debian/Ubuntu
5. **Research Value**: Multiple search agents provided comprehensive understanding of available approaches

## Session Conclusion
Successfully built custom Alpine Linux image with SSH pre-installed using researched best practices, but final SSH connectivity verification failed. VM exists and runs but requires console-level debugging to resolve network/service issues before declaring the custom image approach successful.