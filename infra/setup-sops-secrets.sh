#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Open Source Secret Management with Mozilla SOPS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to generate secure passwords
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-30
}

# Check and install SOPS
install_sops() {
    echo -e "${YELLOW}Checking for SOPS installation...${NC}"

    if ! command -v sops &> /dev/null; then
        echo -e "${YELLOW}Installing Mozilla SOPS...${NC}"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            brew install sops age
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            wget https://github.com/getsops/sops/releases/latest/download/sops-linux-amd64
            chmod +x sops-linux-amd64
            sudo mv sops-linux-amd64 /usr/local/bin/sops

            # Install age
            wget https://github.com/FiloSottile/age/releases/latest/download/age-linux-amd64.tar.gz
            tar -xzf age-linux-amd64.tar.gz
            sudo mv age/age /usr/local/bin/
            sudo mv age/age-keygen /usr/local/bin/
        fi
    fi

    if ! command -v age &> /dev/null; then
        echo -e "${RED}age not found. Please install it manually.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ SOPS and age installed${NC}"
}

# Generate age key for encryption
setup_age_keys() {
    echo -e "\n${YELLOW}Setting up age encryption keys...${NC}"

    KEY_DIR="$HOME/.config/sops/age"
    mkdir -p "$KEY_DIR"

    if [ ! -f "$KEY_DIR/keys.txt" ]; then
        echo -e "Generating new age key..."
        age-keygen -o "$KEY_DIR/keys.txt" 2>&1 | tee "$KEY_DIR/key-info.txt"
        chmod 600 "$KEY_DIR/keys.txt"

        # Extract public key
        PUBLIC_KEY=$(grep "public key:" "$KEY_DIR/key-info.txt" | cut -d' ' -f3)
        echo "$PUBLIC_KEY" > "$KEY_DIR/public-key.txt"

        echo -e "${GREEN}✓ Age key generated${NC}"
        echo -e "${BLUE}Public key: $PUBLIC_KEY${NC}"
    else
        PUBLIC_KEY=$(age-keygen -y "$KEY_DIR/keys.txt")
        echo -e "${GREEN}✓ Using existing age key${NC}"
        echo -e "${BLUE}Public key: $PUBLIC_KEY${NC}"
    fi
}

# Create SOPS configuration
create_sops_config() {
    echo -e "\n${YELLOW}Creating SOPS configuration...${NC}"

    PUBLIC_KEY=$(age-keygen -y "$HOME/.config/sops/age/keys.txt")

    cat > .sops.yaml << EOF
# SOPS configuration
creation_rules:
  - path_regex: \.secrets\.ya?ml$
    age: $PUBLIC_KEY
  - path_regex: \.enc\.ya?ml$
    age: $PUBLIC_KEY
  - path_regex: secrets/.*\.ya?ml$
    age: $PUBLIC_KEY
EOF

    echo -e "${GREEN}✓ SOPS configuration created${NC}"
}

# Create encrypted secrets file
create_secrets_file() {
    echo -e "\n${YELLOW}Creating encrypted secrets file...${NC}"

    mkdir -p secrets

    # Generate new secure passwords
    cat > secrets/infrastructure.yaml << EOF
# ClarityClear Infrastructure Secrets
# This file will be encrypted with SOPS

proxmox:
  api_url: "https://192.168.0.33:8006/api2/json"
  user: "terraform@pve!terraform-token"
  password: "$(generate_password)"
  root_password: "CHANGE_ON_SERVER_$(generate_password)"

services:
  grafana:
    admin_password: "$(generate_password)"
  pbs:
    admin_password: "$(generate_password)"
  restic:
    password: "$(generate_password)"
    s3_access_key: "CONFIGURE_IF_USING_S3"
    s3_secret_key: "CONFIGURE_IF_USING_S3"

monitoring:
  prometheus:
    token: "$(generate_password)"
  loki:
    token: "$(generate_password)"
  uptime_kuma:
    password: "$(generate_password)"

networking:
  keepalived:
    password: "$(generate_password)"
  vpn:
    psk: "$(generate_password)"

databases:
  postgres:
    password: "$(generate_password)"
  redis:
    password: "$(generate_password)"

application:
  secret_key: "$(generate_password)"
  jwt_secret: "$(generate_password)"
  encryption_key: "$(generate_password)"

backup:
  encryption_key: "$(generate_password)"
  repository_password: "$(generate_password)"
EOF

    # Encrypt the file with SOPS
    sops -e -i secrets/infrastructure.yaml

    echo -e "${GREEN}✓ Encrypted secrets file created${NC}"
}

# Create helper scripts
create_helper_scripts() {
    echo -e "\n${YELLOW}Creating helper scripts...${NC}"

    # Script to edit secrets
    cat > edit-secrets.sh << 'EOF'
#!/bin/bash
# Edit encrypted secrets file

sops secrets/infrastructure.yaml
EOF
    chmod +x edit-secrets.sh

    # Script to view secrets
    cat > view-secrets.sh << 'EOF'
#!/bin/bash
# View decrypted secrets

sops -d secrets/infrastructure.yaml | less
EOF
    chmod +x view-secrets.sh

    # Script to export secrets as environment variables
    cat > export-secrets.sh << 'EOF'
#!/bin/bash
# Export secrets as environment variables

# Decrypt and parse YAML to export as env vars
eval $(sops -d secrets/infrastructure.yaml | yq eval -o=shell '.proxmox | to_entries | .[] | "export PM_" + (.key | ascii_upcase) + "=\"" + .value + "\""' -)
eval $(sops -d secrets/infrastructure.yaml | yq eval -o=shell '.services.grafana | to_entries | .[] | "export GRAFANA_" + (.key | ascii_upcase) + "=\"" + .value + "\""' -)
eval $(sops -d secrets/infrastructure.yaml | yq eval -o=shell '.services.restic | to_entries | .[] | "export RESTIC_" + (.key | ascii_upcase) + "=\"" + .value + "\""' -)

echo "Secrets loaded into environment"
EOF
    chmod +x export-secrets.sh

    # Secure deployment wrapper
    cat > deploy-secure.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Loading encrypted secrets..."

# Source the export script to load secrets
source ./export-secrets.sh

# Run the main deployment with secrets loaded
echo "Starting deployment with secure credentials..."
./run.sh "$@"
EOF
    chmod +x deploy-secure.sh

    echo -e "${GREEN}✓ Helper scripts created${NC}"
}

# Create team onboarding script
create_team_script() {
    echo -e "\n${YELLOW}Creating team member onboarding script...${NC}"

    cat > add-team-member.sh << 'EOF'
#!/bin/bash
# Add a new team member to secret management

if [ $# -eq 0 ]; then
    echo "Usage: $0 <team-member-public-key>"
    echo "Team member should run: age-keygen -o ~/.config/sops/age/keys.txt"
    echo "Then share their public key with you"
    exit 1
fi

NEW_KEY="$1"

# Update .sops.yaml to include new key
CURRENT_KEYS=$(grep "age:" .sops.yaml | head -1 | sed 's/.*age: //')
NEW_KEYS="$CURRENT_KEYS,$NEW_KEY"

# Update configuration
sed -i.bak "s/age: .*/age: $NEW_KEYS/" .sops.yaml

# Re-encrypt all secret files with new keys
echo "Re-encrypting secrets with new team member key..."
find secrets -name "*.yaml" -o -name "*.yml" | while read file; do
    sops updatekeys -y "$file"
done

echo "Team member added successfully!"
echo "They can now decrypt secrets using their private key"
EOF
    chmod +x add-team-member.sh

    echo -e "${GREEN}✓ Team onboarding script created${NC}"
}

# Create documentation
create_documentation() {
    echo -e "\n${YELLOW}Creating documentation...${NC}"

    cat > SECRETS_MANAGEMENT.md << 'EOF'
# Secret Management with Mozilla SOPS

This project uses Mozilla SOPS with age encryption for secure secret management.

## Overview

SOPS (Secrets OPerationS) is an open-source tool that encrypts files using AWS KMS, GCP KMS, Azure Key Vault, age, or PGP. We use age for simplicity and portability.

## Initial Setup

1. Install required tools:
   ```bash
   # macOS
   brew install sops age

   # Linux
   ./setup-sops-secrets.sh  # Will auto-install
   ```

2. Your age key is stored in: `~/.config/sops/age/keys.txt`
   - **BACKUP THIS KEY** - Without it, you cannot decrypt secrets
   - Never commit this key to Git

## Daily Usage

### View Secrets
```bash
./view-secrets.sh
# or directly:
sops -d secrets/infrastructure.yaml
```

### Edit Secrets
```bash
./edit-secrets.sh
# or directly:
sops secrets/infrastructure.yaml
```

### Deploy with Secrets
```bash
./deploy-secure.sh
```

### Export to Environment
```bash
source ./export-secrets.sh
```

## Team Collaboration

### Adding a New Team Member

1. Team member generates their key:
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

2. Team member shares their public key

3. Admin adds them:
   ```bash
   ./add-team-member.sh <public-key>
   ```

### Sharing Encrypted Secrets

The encrypted files in `secrets/` can be safely committed to Git.
Only team members with authorized keys can decrypt them.

## Security Best Practices

1. **Never commit unencrypted secrets**
2. **Backup your age private key** (in a password manager)
3. **Rotate secrets regularly**
4. **Use different secrets per environment**
5. **Audit access logs regularly**

## File Structure

```
infra/
├── .sops.yaml              # SOPS configuration
├── secrets/
│   └── infrastructure.yaml # Encrypted secrets
├── edit-secrets.sh        # Helper to edit secrets
├── view-secrets.sh        # Helper to view secrets
├── export-secrets.sh      # Export to environment
└── deploy-secure.sh       # Deploy with secrets
```

## Troubleshooting

### "Could not decrypt file"
- Check if your age key exists: `ls ~/.config/sops/age/keys.txt`
- Verify you have the correct key for this file

### "Error loading config"
- Check `.sops.yaml` exists and is valid YAML
- Verify the age public key is correct

## Alternative: HashiCorp Vault

For enterprise environments, consider HashiCorp Vault:
- Dynamic secret generation
- Secret rotation
- Audit logging
- Fine-grained access control

Setup script available: `setup-vault.sh`

## Recovery

If all keys are lost:
1. Restore from secure backup
2. Rotate ALL secrets immediately
3. Re-encrypt with new keys
EOF

    echo -e "${GREEN}✓ Documentation created${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Installing and configuring Mozilla SOPS...${NC}"

    install_sops
    setup_age_keys
    create_sops_config
    create_secrets_file
    create_helper_scripts
    create_team_script
    create_documentation

    echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    Secret Management Setup Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

    echo -e "\n${YELLOW}Your age private key location:${NC}"
    echo -e "  ${BLUE}~/.config/sops/age/keys.txt${NC}"
    echo -e "  ${RED}⚠️  BACKUP THIS KEY IMMEDIATELY!${NC}"

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. ${GREEN}./edit-secrets.sh${NC} - Update with your actual passwords"
    echo -e "2. ${GREEN}./rotate-passwords.sh${NC} - Rotate compromised passwords on servers"
    echo -e "3. ${GREEN}git rm --cached infra/.env${NC} - Remove .env from Git"
    echo -e "4. ${GREEN}./clean-git-history.sh${NC} - Clean Git history"
    echo -e "5. ${GREEN}./deploy-secure.sh${NC} - Deploy with encrypted secrets"

    echo -e "\n${YELLOW}Quick Commands:${NC}"
    echo -e "  View secrets:  ${BLUE}./view-secrets.sh${NC}"
    echo -e "  Edit secrets:  ${BLUE}./edit-secrets.sh${NC}"
    echo -e "  Deploy:        ${BLUE}./deploy-secure.sh${NC}"

    echo -e "\n${GREEN}Secrets are encrypted in: secrets/infrastructure.yaml${NC}"
    echo -e "${GREEN}This file is safe to commit to Git (it's encrypted)${NC}"
}

main "$@"