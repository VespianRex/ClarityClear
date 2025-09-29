output "edge_a_ip" {
  value       = proxmox_vm_qemu.edge_a.default_ipv4_address
  description = "Edge A VM IP address"
}

output "edge_b_ip" {
  value       = proxmox_vm_qemu.edge_b.default_ipv4_address
  description = "Edge B VM IP address"
}

output "app_vm_ip" {
  value       = proxmox_vm_qemu.app.default_ipv4_address
  description = "App VM IP address"
}

output "monitoring_vm_ip" {
  value       = proxmox_vm_qemu.monitoring.default_ipv4_address
  description = "Monitoring VM IP address"
}

output "pbs_vm_ip" {
  value       = proxmox_vm_qemu.pbs.default_ipv4_address
  description = "PBS VM IP address"
}

output "nfs_vm_ip" {
  value       = proxmox_vm_qemu.nfs.default_ipv4_address
  description = "NFS VM IP address"
}

output "vip" {
  value       = var.vip
  description = "Virtual IP for HA"
}

output "cluster_info" {
  value = {
    vip        = var.vip
    edge_nodes = [
      proxmox_vm_qemu.edge_a.default_ipv4_address,
      proxmox_vm_qemu.edge_b.default_ipv4_address
    ]
    app_ip       = proxmox_vm_qemu.app.default_ipv4_address
    monitoring   = proxmox_vm_qemu.monitoring.default_ipv4_address
    pbs          = proxmox_vm_qemu.pbs.default_ipv4_address
    domain_base  = var.domain_base
  }
  description = "Complete cluster information"
}