# Edge VM A (Alpine) - Primary
resource "proxmox_vm_qemu" "edge_a" {
  name        = var.edge_a_name
  target_node = var.node
  clone       = "9001"  # Use template ID directly
  full_clone  = true  # Make a full clone
  vmid        = 201  # Explicit VM ID

  cores   = 2
  memory  = 2048
  balloon = 1024
  agent   = 1
  onboot  = true
  qemu_os = "l26"  # Linux 2.6/3.x/4.x/5.x/6.x

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init settings
  ciuser     = var.admin_user
  sshkeys    = var.ssh_pubkey
  ipconfig0  = "ip=dhcp"  # DHCP for now, can be changed to static
  nameserver = "192.168.0.1"
  searchdomain = "andub.go.ro"

  lifecycle {
    ignore_changes = [
      network[0].macaddr,
      disk
    ]
  }
}

# Edge VM B (Alpine) - Secondary
resource "proxmox_vm_qemu" "edge_b" {
  name        = var.edge_b_name
  target_node = var.node2 != "" ? var.node2 : var.node
  clone       = "9001"  # Use template ID directly
  full_clone  = true  # Make a full clone
  vmid        = 202  # Explicit VM ID

  cores   = 2
  memory  = 2048
  balloon = 1024
  agent   = 1
  onboot  = true
  qemu_os = "l26"  # Linux 2.6/3.x/4.x/5.x/6.x

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init settings
  ciuser     = var.admin_user
  sshkeys    = var.ssh_pubkey
  ipconfig0  = "ip=dhcp"  # DHCP for now, can be changed to static
  nameserver = "192.168.0.1"
  searchdomain = "andub.go.ro"

  lifecycle {
    ignore_changes = [
      network[0].macaddr,
      disk
    ]
  }
}

# App VM (Debian)
resource "proxmox_vm_qemu" "app" {
  name        = var.app_name
  target_node = var.node
  clone       = "9000"  # Use template ID directly
  full_clone  = true  # Make a full clone
  vmid        = 203  # Explicit VM ID

  cores   = 4
  memory  = 8192
  balloon = 4096
  agent   = 1
  onboot  = true
  qemu_os = "l26"  # Linux 2.6/3.x/4.x/5.x/6.x

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  # Disk is inherited from template, can be resized after cloning

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init settings
  ciuser     = var.admin_user
  sshkeys    = var.ssh_pubkey
  ipconfig0  = "ip=dhcp"  # DHCP for now, can be changed to static
  nameserver = "192.168.0.1"
  searchdomain = "andub.go.ro"

  lifecycle {
    ignore_changes = [
      network[0].macaddr
    ]
  }
}

# Monitoring VM (Debian)
resource "proxmox_vm_qemu" "monitoring" {
  name        = var.monitoring_name
  target_node = var.node2 != "" ? var.node2 : var.node
  clone       = "9000"  # Use template ID directly
  full_clone  = true  # Make a full clone
  vmid        = 204  # Explicit VM ID

  cores   = 2
  memory  = 4096
  balloon = 2048
  agent   = 1
  onboot  = true
  qemu_os = "l26"  # Linux 2.6/3.x/4.x/5.x/6.x

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  # Disk is inherited from template, can be resized after cloning

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init settings
  ciuser     = var.admin_user
  sshkeys    = var.ssh_pubkey
  ipconfig0  = "ip=dhcp"  # DHCP for now, can be changed to static
  nameserver = "192.168.0.1"
  searchdomain = "andub.go.ro"

  lifecycle {
    ignore_changes = [
      network[0].macaddr
    ]
  }
}

# Proxmox Backup Server VM
resource "proxmox_vm_qemu" "pbs" {
  name        = var.pbs_name
  target_node = var.node
  clone       = "9000"  # Use template ID directly
  full_clone  = true  # Make a full clone
  vmid        = 205  # Explicit VM ID

  cores   = 2
  memory  = 4096
  balloon = 2048
  agent   = 1
  onboot  = true
  qemu_os = "l26"  # Linux 2.6/3.x/4.x/5.x/6.x

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  # Disk is inherited from template
  # Additional disk for backup storage will be added after VM creation

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init settings
  ciuser     = var.admin_user
  sshkeys    = var.ssh_pubkey
  ipconfig0  = "ip=dhcp"  # DHCP for now, can be changed to static
  nameserver = "192.168.0.1"
  searchdomain = "andub.go.ro"

  lifecycle {
    ignore_changes = [
      network[0].macaddr
    ]
  }
}

# NFS Server VM (Debian) - For shared storage
resource "proxmox_vm_qemu" "nfs" {
  name        = var.nfs_name
  target_node = var.node
  clone       = "9000"  # Use template ID directly
  full_clone  = true  # Make a full clone
  vmid        = 200  # Explicit VM ID

  cores   = 1
  memory  = 1024
  balloon = 512
  agent   = 1
  onboot  = true
  qemu_os = "l26"  # Linux 2.6/3.x/4.x/5.x/6.x

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  # Disk is inherited from template, can be resized after cloning

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init settings with static IP
  ciuser       = var.admin_user
  sshkeys      = var.ssh_pubkey
  ipconfig0    = "ip=192.168.0.55/24,gw=192.168.0.1"  # Static IP for NFS
  nameserver   = "192.168.0.1"
  searchdomain = "andub.go.ro"

  lifecycle {
    ignore_changes = [
      network[0].macaddr
    ]
  }
}

# Wait for VMs to get IPs
resource "null_resource" "wait_for_ips" {
  depends_on = [
    proxmox_vm_qemu.edge_a,
    proxmox_vm_qemu.edge_b,
    proxmox_vm_qemu.app,
    proxmox_vm_qemu.monitoring,
    proxmox_vm_qemu.pbs
  ]

  provisioner "local-exec" {
    command = "sleep 30"
  }
}