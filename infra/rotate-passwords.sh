#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}         CRITICAL PASSWORD ROTATION REQUIRED${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  Your passwords have been exposed in Git history.${NC}"
echo -e "${YELLOW}⚠️  You MUST rotate ALL passwords immediately!${NC}"
echo ""

cat << 'EOF'
MANUAL STEPS REQUIRED:
=====================

1. PROXMOX ROOT PASSWORD
   - SSH to your Proxmox server: ssh root@192.168.0.33
   - Run: passwd root
   - Enter new secure password
   - Update in ansible/group_vars/all/vault.yml

2. PROXMOX API TOKEN (Recommended over root password)
   - SSH to Proxmox server
   - Run the commands from setup-proxmox-token.sh
   - Save the token and update vault.yml

3. APPLICATION PASSWORDS
   These will be regenerated automatically when you redeploy:
   - Grafana admin password
   - PBS admin password
   - Restic backup password
   - Keepalived password

4. SSH KEYS (If compromised)
   - Generate new SSH key pair:
     ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_clarity_new -C "clarity@secure"
   - Update authorized_keys on all VMs
   - Update SSH_PUBKEY in vault

5. SERVICE ACCOUNTS
   For any external services (S3, DNS, etc.):
   - Log into each service provider
   - Rotate API keys/passwords
   - Update vault.yml with new credentials

EOF

echo -e "\n${BLUE}Automated Password Generation:${NC}"
echo -e "${BLUE}==============================${NC}"

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-30
}

echo -e "\n${GREEN}New secure passwords generated (copy these to vault.yml):${NC}"
echo ""
echo "# Service Passwords"
echo "grafana_admin_password: \"$(generate_password)\""
echo "pbs_admin_password: \"$(generate_password)\""
echo "restic_password: \"$(generate_password)\""
echo "keepalived_password: \"$(generate_password)\""
echo "postgres_password: \"$(generate_password)\""
echo "redis_password: \"$(generate_password)\""
echo "vpn_psk: \"$(generate_password)\""
echo "app_secret_key: \"$(generate_password)\""
echo "jwt_secret: \"$(generate_password)\""
echo "backup_encryption_key: \"$(generate_password)\""

echo -e "\n${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo -e "${YELLOW}=====================${NC}"
echo "1. Update all passwords as shown above"
echo "2. Edit vault: ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file ansible/vault-password.txt"
echo "3. Redeploy all services with new passwords"
echo "4. Test all services to ensure they're working"
echo "5. Clean Git history (see clean-git-history.sh)"

echo -e "\n${RED}⚠️  DO NOT PROCEED WITH DEPLOYMENT UNTIL ALL PASSWORDS ARE ROTATED!${NC}"