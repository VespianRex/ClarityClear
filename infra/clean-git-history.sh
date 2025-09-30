#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}         GIT HISTORY CLEANING - REMOVE SECRETS${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will rewrite Git history!${NC}"
echo -e "${YELLOW}⚠️  Make sure you have a backup before proceeding.${NC}"
echo ""

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Remove sensitive files from tracking${NC}"
echo "================================================"

# Remove sensitive files from current tracking
echo "Removing sensitive files from Git tracking..."
git rm --cached infra/.env 2>/dev/null || true
git rm --cached infra/tofu/*.tfstate 2>/dev/null || true
git rm --cached infra/tofu/*.tfstate.* 2>/dev/null || true
git rm --cached infra/ansible/vault-password.txt 2>/dev/null || true
git rm --cached infra/ansible/group_vars/all/vault.yml 2>/dev/null || true

echo -e "${GREEN}✓ Files removed from tracking${NC}"

echo -e "\n${BLUE}Step 2: Install BFG Repo Cleaner${NC}"
echo "===================================="

# Check if BFG is installed
if ! command -v bfg &> /dev/null; then
    echo "BFG not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install bfg
    else
        echo -e "${YELLOW}Please install BFG manually:${NC}"
        echo "  wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar"
        echo "  alias bfg='java -jar bfg-1.14.0.jar'"
        echo ""
        echo "Or visit: https://rtyley.github.io/bfg-repo-cleaner/"
        echo ""
        read -p "Press Enter once BFG is installed..."
    fi
fi

echo -e "\n${BLUE}Step 3: Create list of sensitive patterns${NC}"
echo "=============================================="

# Create file with sensitive patterns to remove
cat > /tmp/passwords.txt << 'EOF'
sonicx555
xKj9mP2nL8vQ3sT5rY6wA1bC4dE7fG0hI2jK5lM8nO1pQ3rS6tU9
aB3cD5eF7gH9iJ1kL3mN5oP7qR9sT1uV3wX5yZ7aB9cD1eF3gH5i
a1b2c3d4e5f6789012345678901234567
pQ2rS4tU6vW8xY0zA2bC4dE6fG8hI0jK2lM4nO6pQ8rS0tU2vW4x
${ADMIN_PASSWORD:-ChangeMe}
EOF

echo -e "${GREEN}✓ Sensitive patterns list created${NC}"

echo -e "\n${BLUE}Step 4: Clean repository history${NC}"
echo "===================================="

echo -e "${YELLOW}Creating backup...${NC}"
cp -r .git .git.backup

echo -e "${YELLOW}Cleaning with BFG...${NC}"

# Clean specific files
bfg --delete-files .env
bfg --delete-files '*.tfstate'
bfg --delete-files '*.tfstate.*'
bfg --delete-files vault-password.txt
bfg --delete-files vault.yml

# Replace sensitive text
bfg --replace-text /tmp/passwords.txt

echo -e "${GREEN}✓ History cleaned${NC}"

echo -e "\n${BLUE}Step 5: Perform Git garbage collection${NC}"
echo "=========================================="

git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo -e "${GREEN}✓ Git garbage collection complete${NC}"

# Clean up temp file
rm /tmp/passwords.txt

echo -e "\n${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}                    IMPORTANT NEXT STEPS${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"

cat << 'EOF'

⚠️  WARNING: You have rewritten Git history!

You MUST now:

1. Force push to remote (this will overwrite remote history):
   git push --force --all
   git push --force --tags

2. Notify all team members to:
   - Delete their local repositories
   - Re-clone from remote:
     git clone <repository-url>

3. Verify secrets are removed:
   - Check recent commits for sensitive data
   - Search repository for known passwords

4. Update all passwords (if not already done):
   ./rotate-passwords.sh

5. Set up secret scanning to prevent future leaks:
   - Enable GitHub secret scanning (if using GitHub)
   - Add pre-commit hooks for secret detection

ALTERNATIVE (Safer for team environments):
=========================================
Instead of rewriting history, you can:

1. Rotate all passwords immediately
2. Create a new repository with clean history:
   git init new-repo
   cp -r * new-repo/ (excluding .git)
   cd new-repo
   git add .
   git commit -m "Initial commit with secrets removed"

3. Archive the old repository

This preserves the old history but starts fresh without secrets.

EOF

echo -e "${GREEN}Script complete. Review the instructions above carefully.${NC}"