#!/bin/bash

# Secure Deployment Script
set -e

echo "========================================"
echo "ClarityClear Secure Deployment"
echo "========================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check if running on WSL2
if grep -q microsoft /proc/version; then
    echo -e "${RED}WARNING: You are running on WSL2!${NC}"
    echo -e "${RED}WSL2 has significant security vulnerabilities for production hosting.${NC}"
    echo -e "${RED}It is STRONGLY recommended to use native Linux instead.${NC}"
    read -p "Do you want to continue anyway? (not recommended) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo -e "${RED}.env.production file not found!${NC}"
    echo "Please create it from .env.production.example"
    exit 1
fi

# Validate environment variables
echo -e "${YELLOW}Validating configuration...${NC}"
source .env.production

if [[ "$NEXTAUTH_SECRET" == *"generate"* ]]; then
    echo -e "${RED}Please update NEXTAUTH_SECRET in .env.production${NC}"
    exit 1
fi

if [[ "$PB_ENCRYPTION_KEY" == *"generate"* ]]; then
    echo -e "${RED}Please update PB_ENCRYPTION_KEY in .env.production${NC}"
    exit 1
fi

# Build containers
echo -e "${GREEN}Building Docker containers...${NC}"
docker-compose -f docker-compose.secure.yml build

# Create required directories
echo -e "${GREEN}Creating required directories...${NC}"
mkdir -p logs fail2ban/jail.d fail2ban/filter.d secrets

# Start services
echo -e "${GREEN}Starting services...${NC}"
docker-compose -f docker-compose.secure.yml up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
sleep 10

# Check service status
echo -e "${GREEN}Checking service status...${NC}"
docker-compose -f docker-compose.secure.yml ps

# Display logs
echo -e "${YELLOW}Recent logs:${NC}"
docker-compose -f docker-compose.secure.yml logs --tail=20

echo -e "${GREEN}========================================"
echo -e "Deployment Complete!"
echo -e "========================================${NC}"
echo
echo -e "${YELLOW}Important:${NC}"
echo -e "1. Configure your router to forward ports 80 and 443 to this machine"
echo -e "2. Update ddns-updater.sh with your DDNS provider credentials"
echo -e "3. Run: crontab -e and add:"
echo -e "   */5 * * * * /home/alexa/DEV/ClarityClear/ClarityClear/ddns-updater.sh"
echo -e "   0 3 * * * /home/alexa/DEV/ClarityClear/ClarityClear/backup.sh"
echo
echo -e "${YELLOW}Security Checklist:${NC}"
echo -e "[ ] Router firewall configured"
echo -e "[ ] Ports 80 and 443 forwarded"
echo -e "[ ] DDNS updater configured"
echo -e "[ ] UFW firewall enabled (run: sudo ufw status)"
echo -e "[ ] Fail2ban configured"
echo -e "[ ] Backup script scheduled"
echo -e "[ ] Monitor script scheduled"
echo
echo -e "${YELLOW}Monitor your site:${NC}"
echo -e "- Logs: docker-compose -f docker-compose.secure.yml logs -f"
echo -e "- Status: docker-compose -f docker-compose.secure.yml ps"
echo -e "- Stop: docker-compose -f docker-compose.secure.yml down"
echo
echo -e "${RED}Security Warning:${NC}"
echo -e "Home hosting with DDNS exposes your IP address and has inherent risks."
echo -e "Consider using Cloudflare Tunnel for better security."
echo