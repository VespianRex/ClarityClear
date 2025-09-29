# 🔒 Security Remediation Quick Start Guide

## ⚠️ CRITICAL: Your Passwords Are Exposed!

Your infrastructure passwords are currently exposed in Git. Follow these steps **IMMEDIATELY**:

## Step 1: Choose Your Secret Management Solution

### Option A: Mozilla SOPS (Recommended - Simpler)
```bash
cd infra
./setup-sops-secrets.sh
```

### Option B: Ansible Vault (Already Familiar)
```bash
cd infra
./setup-secrets.sh
```

## Step 2: Remove Sensitive Files from Git (NOW!)

```bash
# Remove from tracking
git rm --cached infra/.env
git rm --cached infra/tofu/*.tfstate*

# Commit the removal
git add .gitignore
git commit -m "Remove sensitive files from tracking"
```

## Step 3: Rotate ALL Passwords

### 3.1 Generate New Passwords
```bash
./rotate-passwords.sh
```

### 3.2 Update Proxmox Root Password
```bash
ssh root@192.168.0.33
passwd
# Enter new secure password
```

### 3.3 Create Proxmox API Token (Better than root)
```bash
# On Proxmox server:
pveum user add terraform@pve
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Monitor VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"
pveum aclmod / -user terraform@pve -role TerraformRole
pveum user token add terraform@pve terraform-token --privsep 0
# SAVE THE TOKEN!
```

### 3.4 Update Secrets File
If using SOPS:
```bash
./edit-secrets.sh
# Update all passwords with new ones from step 3.1
```

If using Ansible Vault:
```bash
ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file ansible/vault-password.txt
```

## Step 4: Clean Git History

### ⚠️ WARNING: This rewrites history!

```bash
# Install BFG if not installed
brew install bfg  # macOS
# or download from https://rtyley.github.io/bfg-repo-cleaner/

# Clean history
./clean-git-history.sh

# Force push (coordinate with team!)
git push --force --all
git push --force --tags
```

### Alternative (Safer): Start Fresh
```bash
# Create new repo without history
cd ..
git clone --depth 1 file://$(pwd)/ClarityClear ClarityClear-clean
cd ClarityClear-clean
rm -rf .git
git init
git add .
git commit -m "Initial commit with secrets removed"
# Push to new remote
```

## Step 5: Deploy with New Secrets

```bash
# If using SOPS:
./deploy-secure.sh

# If using Ansible Vault:
./run-secure.sh
```

## Step 6: Verify Everything Works

```bash
# Test each service:
curl https://192.168.0.50  # Edge load balancer
curl http://192.168.0.50:3000  # Grafana
curl http://192.168.0.50:3001  # Uptime Kuma

# Check logs for errors
docker logs -f traefik
docker logs -f grafana
```

## Prevention: Set Up Secret Scanning

### GitHub Secret Scanning
1. Go to Settings → Security → Code security
2. Enable "Secret scanning"
3. Enable "Push protection"

### Pre-commit Hooks
```bash
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
EOF

# Install hooks
pre-commit install

# Create baseline
detect-secrets scan > .secrets.baseline
```

## Summary Checklist

- [ ] Backed up current .env file
- [ ] Set up secret management (SOPS or Vault)
- [ ] Removed .env from Git tracking
- [ ] Rotated Proxmox root password
- [ ] Created Proxmox API token
- [ ] Updated all service passwords
- [ ] Cleaned Git history or created new repo
- [ ] Deployed with new secrets
- [ ] Tested all services
- [ ] Set up secret scanning

## Need Help?

- Mozilla SOPS Docs: https://github.com/getsops/sops
- Ansible Vault Docs: https://docs.ansible.com/ansible/latest/vault_guide/
- BFG Repo Cleaner: https://rtyley.github.io/bfg-repo-cleaner/

## Important Files Created

```
infra/
├── .gitignore                      # Prevents tracking secrets
├── .sops.yaml                      # SOPS configuration
├── setup-sops-secrets.sh           # Mozilla SOPS setup
├── setup-secrets.sh                # Ansible Vault setup
├── rotate-passwords.sh             # Password rotation helper
├── clean-git-history.sh            # Git history cleaner
├── deploy-secure.sh                # Secure deployment
├── edit-secrets.sh                 # Edit encrypted secrets
├── view-secrets.sh                 # View decrypted secrets
└── secrets/
    └── infrastructure.yaml         # Encrypted secrets (safe to commit)
```

**Remember**: The age private key at `~/.config/sops/age/keys.txt` is your master key. **BACK IT UP** in a password manager!