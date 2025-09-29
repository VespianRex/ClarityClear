# Proxmox Connection
variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_user" {
  description = "Proxmox user"
  type        = string
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

# Proxmox Resources
variable "node" {
  description = "Primary Proxmox node"
  type        = string
}

variable "node2" {
  description = "Secondary Proxmox node for HA"
  type        = string
  default     = ""
}

variable "storage" {
  description = "Storage pool"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
}

# Templates
variable "debian_template_id" {
  description = "Debian template VM ID or name"
  type        = string
  default     = "9000"
}

variable "alpine_template_id" {
  description = "Alpine template VM ID or name"
  type        = string
  default     = "9001"
}

# SSH Configuration
variable "ssh_pubkey" {
  description = "SSH public key for cloud-init"
  type        = string
}

variable "admin_user" {
  description = "Admin username"
  type        = string
  default     = "alex"
}

# Domain Configuration
variable "domain_base" {
  description = "Base domain"
  type        = string
}

variable "letsencrypt_email" {
  description = "Let's Encrypt email"
  type        = string
}

# VM Names
variable "edge_a_name" {
  description = "Edge A VM name"
  type        = string
  default     = "edge-a"
}

variable "edge_b_name" {
  description = "Edge B VM name"
  type        = string
  default     = "edge-b"
}

variable "app_name" {
  description = "App VM name"
  type        = string
  default     = "clarity-app"
}

variable "monitoring_name" {
  description = "Monitoring VM name"
  type        = string
  default     = "monitoring"
}

variable "pbs_name" {
  description = "PBS VM name"
  type        = string
  default     = "pbs-backup"
}

variable "nfs_name" {
  description = "NFS VM name"
  type        = string
  default     = "nfs-storage"
}

# Network Configuration
variable "vip" {
  description = "Virtual IP for HA"
  type        = string
}

variable "nfs_server" {
  description = "NFS server IP"
  type        = string
}

variable "nfs_path" {
  description = "NFS export path"
  type        = string
}

# Alternative deployment option
variable "use_iso" {
  description = "Use ISO instead of templates"
  type        = bool
  default     = false
}

variable "deploy_full" {
  description = "Deploy full infrastructure (set to false for testing)"
  type        = bool
  default     = true
}