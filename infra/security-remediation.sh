#!/bin/bash

# Security Remediation Script for ClarityClear Infrastructure
# This script helps address critical security issues identified in the audit

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Check if running from infra directory
if [[ ! -f "Makefile" ]] || [[ ! -d "tofu" ]]; then
    error "This script must be run from the /infra directory"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}     Infrastructure Security Remediation Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Function to generate secure random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to check if file exists in git
is_in_git() {
    git ls-files --error-unmatch "$1" 2>/dev/null
    return $?
}

# Step 1: Create .gitignore if it doesn't exist
create_gitignore() {
    info "Creating comprehensive .gitignore file..."

    cat > .gitignore << 'EOF'
# Terraform/Tofu
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.tfvars
*.tfvars.json
override.tf
override.tf.json
*_override.tf
*_override.tf.json
crash.log
*.log

# Environment files
.env
.env.*
!.env.example
!.env.sample

# SSH Keys and certificates
*.pem
*.key
*.crt
*.cer
id_rsa*
id_ed25519*
id_dsa*
known_hosts

# Ansible
*.retry
ansible/vault_pass.txt
ansible/vault_password
ansible-vault-pass
host_vars/**/vault.yml
group_vars/**/vault.yml

# Backup files
*.bak
*.backup
*~
*.swp
*.swo

# Credentials and secrets
*credentials*
*secret*
*password*
!*example*
!*sample*
!*template*

# OS Files
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.iml

# Temporary files
tmp/
temp/
cache/
EOF

    log ".gitignore created successfully"
}

# Step 2: Create .env.example template
create_env_example() {
    info "Creating .env.example template..."

    cat > .env.example << 'EOF'
# Proxmox Connection
PM_API_URL=https://YOUR_PROXMOX_IP:8006/api2/json
PM_USER=YOUR_API_USER@pve
PM_API_TOKEN_ID=YOUR_TOKEN_ID
PM_API_TOKEN_SECRET=YOUR_TOKEN_SECRET
PM_NODE=YOUR_NODE_NAME
PM_NODE2=YOUR_SECOND_NODE  # Optional for HA
PM_STORAGE=local-lvm
PM_BRIDGE=vmbr0

# Network Configuration
VIP=YOUR_VIRTUAL_IP
LAN_SUBNET=YOUR_LAN_SUBNET/24
NFS_SERVER=YOUR_NFS_SERVER_IP
NFS_PATH=/export/edge-shared

# Domain & Certificates
DOMAIN_BASE=your.domain.com
LE_EMAIL=admin@your.domain.com
PUBLIC_IP=YOUR_PUBLIC_IP

# SSH Configuration
SSH_PUBKEY="YOUR_SSH_PUBLIC_KEY"
ADMIN_USER=admin

# Template IDs
DEBIAN_TEMPLATE_ID=9000
ALPINE_TEMPLATE_ID=9001

# VM Names
EDGE_A_NAME=edge-a
EDGE_B_NAME=edge-b
APP_VM_NAME=clarity-app
MONITORING_VM_NAME=monitoring
PBS_VM_NAME=pbs-backup
NFS_VM_NAME=nfs-storage

# VPN Configuration
VPN_PROVIDER=wireguard
VPN_PORT=51820

# Backup Configuration (retrieve from secret manager)
RESTIC_PASSWORD_REF=vault:secret/data/backup#restic_password
RESTIC_REPO=/opt/clarity/backups
BACKUP_S3_BUCKET=clarity-backups
BACKUP_S3_KEY_REF=vault:secret/data/backup#s3_key
BACKUP_S3_SECRET_REF=vault:secret/data/backup#s3_secret

# Monitoring (retrieve from secret manager)
GRAFANA_ADMIN_PASSWORD_REF=vault:secret/data/monitoring#grafana_password
PROMETHEUS_RETENTION_DAYS=30

# Keepalived (retrieve from secret manager)
KEEPALIVED_PASSWORD_REF=vault:secret/data/ha#keepalived_password
KEEPALIVED_ROUTER_ID=51

# PBS (retrieve from secret manager)
PBS_ADMIN_PASSWORD_REF=vault:secret/data/backup#pbs_password
EOF

    log ".env.example created successfully"
}

# Step 3: Create secure terraform variables file
create_tfvars_example() {
    info "Creating terraform.tfvars.example..."

    cat > tofu/terraform.tfvars.example << 'EOF'
# Proxmox Connection (use environment variables or secret management)
pm_api_url = "https://YOUR_PROXMOX_IP:8006/api2/json"
pm_user    = "terraform@pve"  # Create dedicated user

# Use API tokens instead of passwords
pm_api_token_id     = "terraform@pve!automation"
pm_api_token_secret = "RETRIEVE_FROM_SECRET_MANAGER"

# Proxmox Resources
node    = "YOUR_NODE_NAME"
node2   = ""  # Optional
storage = "local-lvm"
bridge  = "vmbr0"

# SSH Configuration
ssh_pubkey  = "RETRIEVE_FROM_SECRET_MANAGER"
admin_user  = "admin"

# Domain Configuration
domain_base       = "your.domain.com"
letsencrypt_email = "admin@your.domain.com"

# Network Configuration
vip        = "YOUR_VIRTUAL_IP"
nfs_server = "YOUR_NFS_SERVER"
nfs_path   = "/export/shared"
EOF

    log "terraform.tfvars.example created successfully"
}

# Step 4: Check for exposed secrets in git history
check_git_history() {
    warn "Checking for exposed secrets in git history..."

    local found_secrets=false

    # Check if sensitive files are tracked
    for file in ".env" "*.tfvars" "*.tfstate" "*password*" "*secret*" "*credential*"; do
        if is_in_git "$file"; then
            error "Sensitive file found in git: $file"
            found_secrets=true
        fi
    done

    if [ "$found_secrets" = true ]; then
        warn "Sensitive files found in git history!"
        info "To remove them from history, use:"
        echo "  git filter-branch --force --index-filter \\"
        echo "    'git rm --cached --ignore-unmatch .env *.tfvars *.tfstate' \\"
        echo "    --prune-empty --tag-name-filter cat -- --all"
        echo
        info "Or use BFG Repo-Cleaner for easier cleanup:"
        echo "  bfg --delete-files '.env' --delete-files '*.tfvars'"
        echo "  git reflog expire --expire=now --all && git gc --prune=now --aggressive"
    else
        log "No sensitive files found in current git tracking"
    fi
}

# Step 5: Create Ansible vault setup script
create_ansible_vault_setup() {
    info "Creating Ansible vault setup..."

    cat > ansible/setup-vault.sh << 'EOF'
#!/bin/bash
# Ansible Vault Setup Script

# Generate vault password
VAULT_PASS=$(openssl rand -base64 32)
echo "$VAULT_PASS" > vault_pass.txt
chmod 600 vault_pass.txt

# Create encrypted group_vars
ansible-vault create group_vars/all/vault.yml --vault-password-file vault_pass.txt

echo "Vault password saved to vault_pass.txt"
echo "Keep this file secure and never commit it to git!"
echo ""
echo "To edit vault file:"
echo "  ansible-vault edit group_vars/all/vault.yml --vault-password-file vault_pass.txt"
echo ""
echo "To use in playbooks:"
echo "  ansible-playbook site.yml --vault-password-file vault_pass.txt"
EOF

    chmod +x ansible/setup-vault.sh
    log "Ansible vault setup script created"
}

# Step 6: Create HashiCorp Vault configuration
create_vault_config() {
    info "Creating HashiCorp Vault configuration template..."

    mkdir -p vault

    cat > vault/docker-compose.yml << 'EOF'
version: '3.8'

services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_ADDR: 'http://0.0.0.0:8200'
      VAULT_API_ADDR: 'http://0.0.0.0:8200'
      VAULT_LOCAL_CONFIG: |
        {
          "backend": {
            "file": {
              "path": "/vault/file"
            }
          },
          "listener": {
            "tcp": {
              "address": "0.0.0.0:8200",
              "tls_disable": 1
            }
          },
          "ui": true
        }
    volumes:
      - ./data:/vault/file
      - ./config:/vault/config
      - ./logs:/vault/logs
    ports:
      - "8200:8200"
    restart: unless-stopped
    command: server

networks:
  default:
    name: vault-net
EOF

    cat > vault/init-vault.sh << 'EOF'
#!/bin/bash
# Initialize Vault and store infrastructure secrets

export VAULT_ADDR='http://127.0.0.1:8200'

# Initialize Vault
vault operator init -key-shares=5 -key-threshold=3 > vault-init.txt

# Extract keys and token
export VAULT_TOKEN=$(grep 'Initial Root Token:' vault-init.txt | awk '{print $4}')

# Unseal Vault (in production, distribute keys securely)
for i in 1 2 3; do
    KEY=$(grep "Unseal Key $i:" vault-init.txt | awk '{print $4}')
    vault operator unseal $KEY
done

# Enable KV v2 secret engine
vault secrets enable -version=2 kv

# Store Proxmox credentials
vault kv put kv/proxmox \
    api_url="$PM_API_URL" \
    api_token_id="$PM_API_TOKEN_ID" \
    api_token_secret="$PM_API_TOKEN_SECRET"

# Store backup passwords
vault kv put kv/backup \
    restic_password="$(generate_password)" \
    pbs_password="$(generate_password)" \
    s3_access_key="$BACKUP_S3_KEY" \
    s3_secret_key="$BACKUP_S3_SECRET"

# Store monitoring passwords
vault kv put kv/monitoring \
    grafana_password="$(generate_password)" \
    prometheus_password="$(generate_password)"

# Store HA passwords
vault kv put kv/ha \
    keepalived_password="$(generate_password)"

echo "Vault initialized and secrets stored!"
echo "Save vault-init.txt in a secure location!"
EOF

    chmod +x vault/init-vault.sh
    log "HashiCorp Vault configuration created"
}

# Step 7: Create Proxmox API token setup script
create_proxmox_token_script() {
    info "Creating Proxmox API token setup script..."

    cat > tofu/setup-proxmox-token.sh << 'EOF'
#!/bin/bash
# Create API token for Terraform/Tofu instead of using root password

PROXMOX_HOST="192.168.0.33"
PROXMOX_USER="root"

echo "This script will create a dedicated API user and token for Terraform"
echo "You'll need to enter your Proxmox root password"
echo

# SSH to Proxmox and create user
ssh root@$PROXMOX_HOST << 'ENDSSH'
# Create user for Terraform
pveum user add terraform@pve --comment "Terraform Automation User"

# Create role with necessary permissions
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Pool.Allocate"

# Assign role to user
pveum acl modify / -user terraform@pve -role TerraformRole

# Create API token
pveum user token add terraform@pve terraform-token -privsep=0 -expire=0

echo "Save the token ID and secret securely!"
ENDSSH
EOF

    chmod +x tofu/setup-proxmox-token.sh
    log "Proxmox API token setup script created"
}

# Step 8: Create security check script
create_security_check() {
    info "Creating security check script..."

    cat > security-check.sh << 'EOF'
#!/bin/bash
# Security Configuration Checker

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Security Configuration Check"
echo "============================"
echo

ISSUES=0

# Check for .gitignore
if [ ! -f .gitignore ]; then
    echo -e "${RED}[✗]${NC} Missing .gitignore file"
    ((ISSUES++))
else
    echo -e "${GREEN}[✓]${NC} .gitignore exists"
fi

# Check for .env file
if [ -f .env ]; then
    if git ls-files --error-unmatch .env 2>/dev/null; then
        echo -e "${RED}[✗]${NC} .env file is tracked by git!"
        ((ISSUES++))
    else
        echo -e "${YELLOW}[!]${NC} .env file exists (ensure it's not in git)"
    fi
fi

# Check for terraform state files
if ls *.tfstate* 1> /dev/null 2>&1; then
    echo -e "${YELLOW}[!]${NC} Terraform state files found locally"
    for f in *.tfstate*; do
        if git ls-files --error-unmatch "$f" 2>/dev/null; then
            echo -e "${RED}[✗]${NC} $f is tracked by git!"
            ((ISSUES++))
        fi
    done
fi

# Check for hardcoded passwords in files
echo -e "\nScanning for potential hardcoded passwords..."
if grep -r "password\|secret\|token" --include="*.sh" --include="*.yml" --include="*.yaml" --include="*.tf" --exclude-dir=".git" . | grep -v "#\|example\|template\|REF\|vault" | grep -E "=|:" > /dev/null; then
    echo -e "${YELLOW}[!]${NC} Potential hardcoded credentials found:"
    grep -r "password\|secret\|token" --include="*.sh" --include="*.yml" --include="*.yaml" --include="*.tf" --exclude-dir=".git" . | grep -v "#\|example\|template\|REF\|vault" | grep -E "=|:" | head -5
fi

# Check SSH configuration
if grep -q "StrictHostKeyChecking.*no" ansible/inventory/hosts.yml 2>/dev/null; then
    echo -e "${YELLOW}[!]${NC} SSH StrictHostKeyChecking is disabled"
fi

echo
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}Security check passed!${NC}"
else
    echo -e "${RED}Found $ISSUES critical security issues that need fixing${NC}"
    exit 1
fi
EOF

    chmod +x security-check.sh
    log "Security check script created"
}

# Main execution
main() {
    echo "Starting security remediation process..."
    echo

    # Step 1: Create .gitignore
    if [ ! -f .gitignore ]; then
        create_gitignore
    else
        warn ".gitignore already exists, skipping..."
    fi

    # Step 2: Create example files
    create_env_example
    create_tfvars_example

    # Step 3: Check git history
    check_git_history

    # Step 4: Create Ansible vault setup
    create_ansible_vault_setup

    # Step 5: Create Vault configuration
    create_vault_config

    # Step 6: Create Proxmox token script
    create_proxmox_token_script

    # Step 7: Create security check script
    create_security_check

    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}     Remediation Scripts Created Successfully!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo

    echo "Next Steps:"
    echo "1. Remove .env from git tracking: git rm --cached .env"
    echo "2. Set up HashiCorp Vault: cd vault && docker-compose up -d"
    echo "3. Initialize Vault: cd vault && ./init-vault.sh"
    echo "4. Create Proxmox API token: ./tofu/setup-proxmox-token.sh"
    echo "5. Set up Ansible vault: cd ansible && ./setup-vault.sh"
    echo "6. Rotate ALL passwords and update them in Vault"
    echo "7. Run security check: ./security-check.sh"
    echo
    warn "CRITICAL: Rotate all exposed passwords immediately!"
    warn "Never commit sensitive data to version control!"
    echo
    info "Review SECURITY_AUDIT_REPORT.md for complete recommendations"
}

# Run main function
main "$@"