# Alternative configuration that creates VMs from ISO instead of templates
# Use this if templates aren't available or there are permission issues with cloning

# NFS Server VM (Debian) - Created from ISO
resource "proxmox_vm_qemu" "nfs_iso" {
  count       = var.use_iso ? 1 : 0
  name        = var.nfs_name
  target_node = var.node
  vmid        = 200

  cores   = 1
  memory  = 1024
  balloon = 512
  agent   = 1
  onboot  = true

  scsihw  = "virtio-scsi-pci"
  boot    = "order=scsi0;ide2"
  iso     = "local:iso/debian-12-generic-amd64.iso"  # Adjust ISO path as needed

  disk {
    type    = "scsi"
    storage = var.storage
    size    = "20G"
    slot    = 0
  }

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Cloud-init drive
  disk {
    type    = "ide"
    storage = var.storage
    size    = "4M"
    slot    = 2
    media   = "cloudinit"
  }

  # Cloud-init configuration
  ciuser       = var.admin_user
  cipassword   = "TempPassword123!"  # Change after first boot
  sshkeys      = var.ssh_pubkey
  ipconfig0    = "ip=192.168.0.55/24,gw=192.168.0.1"
  nameserver   = "192.168.0.1"
  searchdomain = "andub.go.ro"
}