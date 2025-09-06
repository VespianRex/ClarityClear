#!/bin/bash

# Security Setup Script for DDNS Home Hosting
# Run with: sudo bash security-setup.sh

set -e

echo "========================================"
echo "ClarityClear Security Setup"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}[1/10] Installing security dependencies...${NC}"
apt-get update
apt-get install -y ufw fail2ban iptables-persistent netfilter-persistent

echo -e "${GREEN}[2/10] Setting up UFW firewall...${NC}"
# Reset UFW to defaults
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

# Allow SSH (adjust port if needed)
read -p "Enter your SSH port (default 22): " ssh_port
ssh_port=${ssh_port:-22}
ufw allow $ssh_port/tcp comment 'SSH'

# Allow HTTP and HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Rate limiting for SSH
ufw limit $ssh_port/tcp

# Enable UFW
ufw --force enable

echo -e "${GREEN}[3/10] Configuring Fail2ban...${NC}"
# Create fail2ban directory
mkdir -p fail2ban/jail.d

# Create Fail2ban jail configuration
cat > fail2ban/jail.d/caddy.conf << 'EOF'
[caddy-status]
enabled = true
port = http,https
filter = caddy-status
logpath = /var/log/caddy/access.log
maxretry = 5
findtime = 600
bantime = 3600
action = iptables-multiport[name=caddy, port="http,https", protocol=tcp]

[caddy-404]
enabled = true
port = http,https
filter = caddy-404
logpath = /var/log/caddy/access.log
maxretry = 30
findtime = 600
bantime = 600

[caddy-rate]
enabled = true
port = http,https
filter = caddy-rate
logpath = /var/log/caddy/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF

# Create filter definitions
mkdir -p fail2ban/filter.d

cat > fail2ban/filter.d/caddy-status.conf << 'EOF'
[Definition]
failregex = ^.*"remote_addr":"<HOST>".*"status":(4\d{2}|5\d{2}).*$
ignoreregex =
EOF

cat > fail2ban/filter.d/caddy-404.conf << 'EOF'
[Definition]
failregex = ^.*"remote_addr":"<HOST>".*"status":404.*$
ignoreregex =
EOF

cat > fail2ban/filter.d/caddy-rate.conf << 'EOF'
[Definition]
failregex = ^.*"remote_addr":"<HOST>".*$
ignoreregex =
EOF

echo -e "${GREEN}[4/10] Creating secrets directory...${NC}"
mkdir -p secrets
chmod 700 secrets

# Generate secure passwords
echo -e "${YELLOW}Generating secure passwords...${NC}"
pb_admin_password=$(openssl rand -base64 32)
nextauth_secret=$(openssl rand -base64 32)
pb_encryption_key=$(openssl rand -hex 16)

# Save secrets
echo "admin@clarityclear.com" > secrets/pb_admin_email.txt
echo "$pb_admin_password" > secrets/pb_admin_password.txt
chmod 600 secrets/*

echo -e "${GREEN}[5/10] Updating .env.production with generated secrets...${NC}"
sed -i "s/generate_unique_secret_here/$nextauth_secret/g" .env.production
sed -i "s/generate_32_char_random_string_here/$pb_encryption_key/g" .env.production

echo -e "${GREEN}[6/10] Setting up Docker security...${NC}"
# Enable Docker content trust
echo "export DOCKER_CONTENT_TRUST=1" >> ~/.bashrc

# Configure Docker daemon security
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp/default.json",
  "icc": false,
  "userns-remap": "default"
}
EOF

# Restart Docker
systemctl restart docker

echo -e "${GREEN}[7/10] Setting up system hardening...${NC}"
# Kernel hardening
cat > /etc/sysctl.d/99-security.conf << 'EOF'
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore Directed pings
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Enable TCP/IP SYN cookies
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2

# Increase TCP syn backlog
net.ipv4.tcp_max_syn_backlog = 4096

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

sysctl -p /etc/sysctl.d/99-security.conf

echo -e "${GREEN}[8/10] Creating backup script...${NC}"
cat > backup.sh << 'EOF'
#!/bin/bash
# Automated backup script
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup PocketBase data
docker exec pocketbase tar czf - /pb/pb_data | gzip > $BACKUP_DIR/pocketbase_$DATE.tar.gz

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF
chmod +x backup.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 3 * * * /home/alexa/DEV/ClarityClear/ClarityClear/backup.sh") | crontab -

echo -e "${GREEN}[9/10] Creating monitoring script...${NC}"
cat > monitor.sh << 'EOF'
#!/bin/bash
# Health monitoring script

# Check if services are running
check_service() {
    if docker ps | grep -q $1; then
        echo "✓ $1 is running"
    else
        echo "✗ $1 is NOT running"
        # Restart service
        docker-compose -f docker-compose.secure.yml up -d $1
    fi
}

check_service "caddy"
check_service "nextjs"
check_service "pocketbase"
check_service "fail2ban"

# Check disk usage
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "⚠ WARNING: Disk usage is at ${DISK_USAGE}%"
fi

# Check for failed login attempts
FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    echo "⚠ WARNING: $FAILED_LOGINS failed login attempts detected"
fi
EOF
chmod +x monitor.sh

echo -e "${GREEN}[10/10] Setting up log rotation...${NC}"
cat > /etc/logrotate.d/caddy << 'EOF'
/var/log/caddy/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        docker exec caddy caddy reload --config /etc/caddy/Caddyfile
    endscript
}
EOF

echo -e "${GREEN}========================================"
echo -e "Security Setup Complete!"
echo -e "========================================${NC}"
echo
echo -e "${YELLOW}Important Information:${NC}"
echo -e "1. PocketBase Admin Password: $pb_admin_password"
echo -e "2. Save this password securely - it won't be shown again"
echo -e "3. Firewall is configured and active"
echo -e "4. Fail2ban is configured for intrusion prevention"
echo -e "5. Automated backups scheduled for 3 AM daily"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Update .env.production with your actual values"
echo -e "2. Configure your router to forward ports 80 and 443 to this machine"
echo -e "3. Set up DDNS client for andub.go.ro"
echo -e "4. Run: docker-compose -f docker-compose.secure.yml up -d"
echo
echo -e "${RED}Security Warnings:${NC}"
echo -e "- Change default passwords immediately"
echo -e "- Keep all software updated"
echo -e "- Monitor logs regularly"
echo -e "- Consider using Cloudflare Tunnel instead for better security"
echo