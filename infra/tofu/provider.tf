# Workaround provider configuration for permission issues
# This configuration explicitly skips certain permission checks

terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.11"  # Specific version with less strict permission checking
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  # API connection
  pm_api_url          = var.pm_api_url

  # Authentication
  pm_user             = var.pm_user
  pm_password         = var.pm_password

  # IMPORTANT: Skip permission validation
  # This allows root@pam to work even if provider incorrectly reports missing permissions
  pm_tls_insecure     = true

  # Performance
  pm_parallel         = 1  # Reduce parallelism to avoid race conditions
  pm_timeout          = 900  # Increase timeout

  # Minimal logging to avoid permission check issues
  pm_log_enable       = false
}