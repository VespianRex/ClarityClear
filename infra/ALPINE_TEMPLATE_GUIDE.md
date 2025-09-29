# Alpine Edge VM Template Creation Guide

This guide covers creating and using Proxmox VM templates from successfully built Alpine edge VMs, enabling rapid deployment of additional edge nodes.

## Overview

Template creation allows you to:
- **Accelerate deployment**: Clone pre-configured VMs in seconds instead of building from scratch
- **Ensure consistency**: All edge nodes start from the same baseline configuration
- **Reduce resource usage**: Templates use minimal storage and can be cloned efficiently
- **Enable scaling**: Quickly spin up multiple edge nodes for testing or production

## Template Creation Process

### Prerequisites

1. **Successful Alpine VM build**: Complete the build process using `./infra/build-alpine-image-corrected.sh`
2. **VM validation**: Ensure the VM passes connectivity tests with `./infra/scripts/test-alpine-connectivity.sh`
3. **Clean state**: Run cleanup if needed: `./infra/scripts/cleanup-alpine-build.sh`
4. **Local tooling**: `python3` available on the operator machine (used by automation script for JSON parsing)
5. **Proxmox tooling**: `vzdump` available on the host if backups are enabled (default)

### Automated Template Creation

Use the automated script for standard template creation:

```bash
./infra/scripts/create-alpine-template.sh
```

#### Advanced Options:
```bash
# Create template from different source VM
./infra/scripts/create-alpine-template.sh --source-vmid 9009 --template-id 9001

# Custom template name
./infra/scripts/create-alpine-template.sh --template-name "alpine-edge-v2"

# Skip source VM backup (faster, but less safe)
./infra/scripts/create-alpine-template.sh --no-backup-source

# Preview what would be done
./infra/scripts/create-alpine-template.sh --dry-run
```

### Manual Template Creation

If you need more control or the automated script fails:

#### 1. Prepare Source VM

```bash
# Connect to Proxmox host
ssh root@192.168.0.33

# Ensure VM is stopped
qm stop 9008

# Optional: Create backup first
vzdump 9008 --mode stop --compress lz4 --notes "Pre-template backup $(date)"
```

#### 2. Clean VM for Template Use

Start the VM temporarily to clean it:

```bash
# Start VM
qm start 9008

# Wait for guest agent
sleep 30

# Get VM IP
VM_IP=$(qm guest cmd 9008 network-get-interfaces | jq -r '.[]."ip-addresses"[]."ip-address"' | grep -v '^127\.' | head -n1)

# Clean up via SSH
ssh VespianRex@$VM_IP 'sudo bash -c "
  # Remove SSH host keys (regenerated on boot)
  rm -f /etc/ssh/ssh_host_*

  # Clear machine ID
  echo > /etc/machine-id

  # Clear histories
  history -c
  rm -f ~/.bash_history /home/VespianRex/.bash_history /root/.bash_history

  # Clean logs
  find /var/log -type f -exec truncate -s 0 {} \\;

  # Clear temporary files
  rm -rf /tmp/* /var/tmp/*

  # Clean package cache
  apk cache clean

  # Remove DHCP leases
  rm -f /var/lib/dhcp/dhclient.*
"'

# Stop VM after cleanup
qm stop 9008
```

#### 3. Create Template

```bash
# Clone VM to template ID
qm clone 9008 9000 --name alpine-edge-template --full

# Convert to template
qm template 9000

# Add description
qm set 9000 --description "Alpine Edge VM Template
Created: $(date)
Source VM: 9008
Base: Alpine Linux 3.20 with SSH, QEMU Guest Agent
Default User: VespianRex
Use: qm clone 9000 <new_vmid> --name <vm_name>"
```

## Using Templates

### Cloning from Template

#### Using the Convenience Script

The template creation process generates a clone script:

```bash
# Clone and start new VM
./infra/scripts/clone-from-alpine-template.sh 9009 edge-node-2 --start

# Clone without starting
./infra/scripts/clone-from-alpine-template.sh 9010 edge-node-3
```

#### Manual Cloning

```bash
# Clone template to new VM
qm clone 9000 9009 --name edge-node-2 --full

# Optional: Customize before starting
qm set 9009 --memory 4096  # Increase RAM
qm set 9009 --cores 4      # More CPU cores

# Start the VM
qm start 9009
```

### Post-Clone Configuration

After cloning and starting a VM:

#### 1. Wait for Boot and Agent

```bash
# Wait for guest agent
sleep 30
qm agent 9009 ping

# Get network information
qm guest cmd 9009 network-get-interfaces
```

#### 2. SSH Host Key Regeneration

The first boot automatically regenerates SSH host keys. Monitor the first connection:

```bash
# Get VM IP
VM_IP=$(qm guest cmd 9009 network-get-interfaces | jq -r '.[]."ip-addresses"[]."ip-address"' | grep -v '^127\.' | head -n1)

# Test SSH (accept new host key)
ssh VespianRex@$VM_IP hostname
```

#### 3. Customize for Role

Each cloned VM should be customized for its specific role:

```bash
# Connect to VM
ssh VespianRex@$VM_IP

# Set unique hostname
sudo hostname edge-node-2
echo 'edge-node-2' | sudo tee /etc/hostname

# Configure static IP if needed
sudo vi /etc/network/interfaces

# Install role-specific packages
sudo apk add docker docker-compose

# Configure services
sudo rc-update add docker default
sudo rc-service docker start
```

## Template Management

### Listing Templates

```bash
# Show all templates
ssh root@192.168.0.33 'qm list | grep template'

# Show template configuration
ssh root@192.168.0.33 'qm config 9000'
```

### Updating Templates

To update a template with new configurations:

```bash
# Method 1: Update source VM and recreate template
./infra/build-alpine-image-corrected.sh --follow  # Build updated VM
./infra/scripts/cleanup-alpine-build.sh --dry-run  # Check what would be cleaned
ssh root@192.168.0.33 'qm destroy 9000'           # Remove old template
./infra/scripts/create-alpine-template.sh         # Create new template

# Method 2: Clone template, modify, and create new version
ssh root@192.168.0.33 'qm clone 9000 9008 --name temp-update --full'
# ... make modifications to VM 9008 ...
./infra/scripts/create-alpine-template.sh --source-vmid 9008 --template-id 9001 --template-name "alpine-edge-v2"
```

### Template Storage Management

Templates are stored efficiently but can accumulate over time:

```bash
# Check storage usage
ssh root@192.168.0.33 'pvesm status'

# List template disk usage
ssh root@192.168.0.33 'qm list | grep template' | while read line; do
  vmid=$(echo "$line" | awk '{print $1}')
  echo "Template $vmid:"
  qm config "$vmid" | grep -E 'scsi0|ide0'
done

# Remove old template
ssh root@192.168.0.33 'qm destroy 9001'  # Remove template 9001
```

## Integration with Build Pipeline

### Makefile Integration

Add template operations to your Makefile:

```makefile
# Create template from successful build
make edge-template:
	./infra/scripts/create-alpine-template.sh

# Clone template for testing
make edge-clone:
	./infra/scripts/clone-from-alpine-template.sh 9009 test-node --start

# Full pipeline with template
make edge-full: edge-clean edge-build edge-validate edge-template
```

### CI/CD Integration

For automated deployments:

```bash
# In CI pipeline
- name: Build and create template
  run: |
    ./infra/build-alpine-image-corrected.sh
    ./infra/scripts/test-alpine-connectivity.sh
    ./infra/scripts/create-alpine-template.sh --no-backup-source

- name: Deploy edge nodes
  run: |
    for i in {1..3}; do
      ./infra/scripts/clone-from-alpine-template.sh $((9010+i)) edge-node-$i --start
    done
```

## Best Practices

### Template Versioning

Use descriptive template names and IDs:

```bash
# Version-based naming
alpine-edge-v1.0  (ID: 9000)
alpine-edge-v1.1  (ID: 9001)
alpine-edge-v2.0  (ID: 9002)

# Date-based naming
alpine-edge-20250924  (ID: 9010)
alpine-edge-20250925  (ID: 9011)

# Feature-based naming
alpine-edge-docker     (ID: 9020)
alpine-edge-minimal    (ID: 9021)
```

### Resource Planning

Plan template and clone resource usage:

| Component | Template | Per Clone | 10 Clones |
|-----------|----------|-----------|-----------|
| Storage | ~2GB | ~10GB | ~100GB |
| RAM | 0MB | 2GB | 20GB |
| CPU | 0 cores | 2 cores | 20 cores |

### Security Considerations

1. **Clean Templates**: Always clean sensitive data before templating
2. **Unique Keys**: Ensure SSH host keys are regenerated on first boot
3. **Machine IDs**: Clear machine-specific identifiers
4. **Credentials**: Never template VMs with permanent credentials

### Monitoring and Alerting

Track template usage and performance:

```bash
# Monitor template storage growth
watch 'pvesm status | grep templates'

# Check clone deployment success
for vm in $(qm list | grep edge-node | awk '{print $1}'); do
  echo "VM $vm: $(qm status $vm)"
done

# Validate all edge nodes
for vm in $(qm list | grep edge-node | awk '{print $1}'); do
  if qm agent "$vm" ping >/dev/null 2>&1; then
    echo "VM $vm: Agent OK"
  else
    echo "VM $vm: Agent FAIL"
  fi
done
```

## Troubleshooting

### Common Issues

#### 1. Template Creation Fails

```bash
# Check source VM state
ssh root@192.168.0.33 'qm status 9008'

# Verify sufficient storage
ssh root@192.168.0.33 'pvesm status'

# Check for ID conflicts
ssh root@192.168.0.33 'qm list | grep 9000'
```

#### 2. Clone Boot Issues

```bash
# Check clone configuration
ssh root@192.168.0.33 'qm config 9009'

# Monitor boot process
ssh root@192.168.0.33 'qm monitor 9009'
# In monitor: 'info status'

# Check guest agent
ssh root@192.168.0.33 'qm agent 9009 ping'
```

#### 3. Network Configuration Problems

```bash
# Check network interfaces
qm guest cmd 9009 network-get-interfaces

# SSH into VM and check network
ssh VespianRex@<vm_ip> 'ip addr show && ip route show'

# Restart networking if needed
ssh VespianRex@<vm_ip> 'sudo rc-service networking restart'
```

### Recovery Procedures

#### Corrupted Template

```bash
# Remove corrupted template
ssh root@192.168.0.33 'qm destroy 9000'

# Recreate from backup or source VM
./infra/scripts/create-alpine-template.sh --source-vmid 9008
```

#### Failed Clone

```bash
# Remove failed clone
ssh root@192.168.0.33 'qm stop 9009 --skiplock; qm destroy 9009'

# Retry cloning
./infra/scripts/clone-from-alpine-template.sh 9009 edge-node-2 --start
```

This comprehensive template system enables efficient scaling and deployment of Alpine edge nodes while maintaining consistency and reliability across your infrastructure.
