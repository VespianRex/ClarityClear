#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}ClarityClear Secret Management Setup${NC}"
echo "======================================="
echo ""

# Function to generate secure passwords
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"

    if ! command -v ansible-vault &> /dev/null; then
        echo -e "${RED}ansible-vault not found. Installing ansible...${NC}"
        pip3 install ansible-core
    fi

    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}openssl not found. Please install openssl.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All requirements met${NC}"
}

# Create Ansible Vault password file
setup_ansible_vault() {
    echo -e "\n${YELLOW}Setting up Ansible Vault...${NC}"

    # Generate vault password if not exists
    if [ ! -f "ansible/vault-password.txt" ]; then
        echo -e "Generating vault password..."
        openssl rand -base64 32 > ansible/vault-password.txt
        chmod 600 ansible/vault-password.txt
        echo -e "${GREEN}✓ Vault password created${NC}"
    else
        echo -e "${YELLOW}⚠ Vault password already exists${NC}"
    fi
}

# Create encrypted secrets file
create_encrypted_secrets() {
    echo -e "\n${YELLOW}Creating encrypted secrets file...${NC}"

    # Create ansible directory structure
    mkdir -p ansible/group_vars/all

    # Generate new passwords
    echo -e "Generating secure passwords..."

    cat > /tmp/vault.yml << EOF
---
# Proxmox Credentials
proxmox_api_url: "https://192.168.0.33:8006/api2/json"
proxmox_user: "terraform@pve!terraform-token"
proxmox_password: "$(generate_password)"

# Service Passwords
grafana_admin_password: "$(generate_password)"
pbs_admin_password: "$(generate_password)"
restic_password: "$(generate_password)"
keepalived_password: "$(generate_password)"

# Database Passwords
postgres_password: "$(generate_password)"
redis_password: "$(generate_password)"

# VPN Secrets
vpn_psk: "$(generate_password)"

# Monitoring Tokens
prometheus_token: "$(generate_password)"
loki_token: "$(generate_password)"

# Application Secrets
app_secret_key: "$(generate_password)"
jwt_secret: "$(generate_password)"

# Backup Encryption
backup_encryption_key: "$(generate_password)"
EOF

    # Encrypt the file
    ansible-vault encrypt /tmp/vault.yml --vault-password-file ansible/vault-password.txt
    mv /tmp/vault.yml ansible/group_vars/all/vault.yml

    echo -e "${GREEN}✓ Encrypted secrets file created${NC}"
}

# Create secure environment loader
create_env_loader() {
    echo -e "\n${YELLOW}Creating secure environment loader...${NC}"

    cat > load-secrets.sh << 'EOF'
#!/bin/bash
# Load secrets from Ansible Vault into environment

VAULT_FILE="ansible/group_vars/all/vault.yml"
VAULT_PASS="ansible/vault-password.txt"

if [ ! -f "$VAULT_FILE" ]; then
    echo "Error: Vault file not found"
    exit 1
fi

if [ ! -f "$VAULT_PASS" ]; then
    echo "Error: Vault password file not found"
    exit 1
fi

# Decrypt and load variables
eval $(ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASS" | \
    yq eval -o=shell -)

echo "Secrets loaded into environment"
EOF

    chmod +x load-secrets.sh
    echo -e "${GREEN}✓ Environment loader created${NC}"
}

# Update deployment scripts to use vault
update_deployment_scripts() {
    echo -e "\n${YELLOW}Creating secure deployment wrapper...${NC}"

    cat > run-secure.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Load secrets from vault
source ./load-secrets.sh

# Export for Terraform/Tofu
export PM_PASSWORD="$proxmox_password"
export PM_USER="$proxmox_user"
export PM_API_URL="$proxmox_api_url"

# Export for Ansible
export ANSIBLE_VAULT_PASSWORD_FILE="ansible/vault-password.txt"

# Run the original deployment
./run.sh "$@"
EOF

    chmod +x run-secure.sh
    echo -e "${GREEN}✓ Secure deployment wrapper created${NC}"
}

# Create Proxmox API token setup script
create_proxmox_token_script() {
    echo -e "\n${YELLOW}Creating Proxmox API token script...${NC}"

    cat > setup-proxmox-token.sh << 'EOF'
#!/bin/bash
# Run this on your Proxmox server to create an API token

echo "Creating Terraform user and API token on Proxmox..."

# Create user
pveum user add terraform@pve

# Create role with necessary permissions
pveum role add TerraformRole -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt User.Modify"

# Assign role to user
pveum aclmod / -user terraform@pve -role TerraformRole

# Create API token
pveum user token add terraform@pve terraform-token --privsep 0

echo ""
echo "IMPORTANT: Save the token secret shown above!"
echo "Add it to your vault.yml as 'proxmox_password'"
EOF

    chmod +x setup-proxmox-token.sh
    echo -e "${GREEN}✓ Proxmox token setup script created${NC}"
}

# Main execution
main() {
    check_requirements
    setup_ansible_vault
    create_encrypted_secrets
    create_env_loader
    update_deployment_scripts
    create_proxmox_token_script

    echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Secret Management Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. Run ${GREEN}./setup-proxmox-token.sh${NC} on your Proxmox server"
    echo -e "2. Update ${GREEN}ansible/group_vars/all/vault.yml${NC} with the API token"
    echo -e "3. Remove ${RED}infra/.env${NC} from Git history"
    echo -e "4. Use ${GREEN}./run-secure.sh${NC} instead of ./run.sh for deployments"
    echo -e "5. Never commit ${RED}vault-password.txt${NC} to Git!"

    echo -e "\n${YELLOW}To view/edit encrypted secrets:${NC}"
    echo -e "  ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file ansible/vault-password.txt"
    echo -e "  ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file ansible/vault-password.txt"
}

main "$@"