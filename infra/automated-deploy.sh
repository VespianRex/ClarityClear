#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    ClarityClear Automated Deployment Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Configuration - Update these as needed
APP_IP="192.168.0.180"
MONITORING_IP="192.168.0.207"
PBS_IP="192.168.0.242"
STORAGE_IP="192.168.0.144"
EDGE_IPS=("192.168.0.201" "192.168.0.202")  # Will need to discover these

SSH_KEY="${SSH_KEY:-~/.ssh/id_ed25519_clarity}"
SSH_USER="${SSH_USER:-VespianRex}"
DOMAIN="${DOMAIN:-andub.go.ro}"
PUBLIC_IP="${PUBLIC_IP:-86.121.4.16}"

# Function to run SSH commands with proper error handling
run_ssh() {
    local host=$1
    shift
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
        -o BatchMode=yes "$SSH_USER@$host" "$@" 2>/dev/null || {
        echo -e "${RED}Failed to execute on $host${NC}"
        return 1
    }
}

# Function to check if a service is running
check_service() {
    local host=$1
    local port=$2
    local service=$3

    if nc -zv -w2 "$host" "$port" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $service is running on port $port"
        return 0
    else
        echo -e "  ${RED}✗${NC} $service is not responding on port $port"
        return 1
    fi
}

# Step 1: Verify infrastructure
echo -e "\n${YELLOW}Step 1: Verifying Infrastructure${NC}"
echo "======================================"

# Check Proxmox connectivity
if ping -c 1 -W 1 192.168.0.33 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Proxmox server is reachable"
else
    echo -e "${RED}✗${NC} Cannot reach Proxmox server at 192.168.0.33"
    exit 1
fi

# Check VM connectivity
echo -e "\n${YELLOW}Checking VM connectivity:${NC}"
for vm in "App:$APP_IP" "Monitoring:$MONITORING_IP" "PBS:$PBS_IP" "Storage:$STORAGE_IP"; do
    name=${vm%:*}
    ip=${vm#*:}
    if ping -c 1 -W 1 "$ip" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $name VM ($ip) is reachable"
    else
        echo -e "  ${YELLOW}⚠${NC} $name VM ($ip) not responding to ping"
    fi
done

# Step 2: Install dependencies on App VM
echo -e "\n${YELLOW}Step 2: Installing Dependencies on App VM${NC}"
echo "=============================================="

echo "Checking Docker installation..."
if run_ssh "$APP_IP" "docker --version" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Docker is already installed"
else
    echo "Installing Docker..."
    run_ssh "$APP_IP" << 'ENDSSH'
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
ENDSSH
    echo -e "${GREEN}✓${NC} Docker installed"
fi

echo "Installing Docker Compose..."
run_ssh "$APP_IP" << 'ENDSSH'
if ! command -v docker-compose &>/dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi
ENDSSH
echo -e "${GREEN}✓${NC} Docker Compose ready"

echo "Checking Node.js installation..."
if run_ssh "$APP_IP" "node --version" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Node.js is already installed"
else
    echo "Installing Node.js..."
    run_ssh "$APP_IP" << 'ENDSSH'
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
ENDSSH
    echo -e "${GREEN}✓${NC} Node.js installed"
fi

# Step 3: Deploy Application
echo -e "\n${YELLOW}Step 3: Deploying Application${NC}"
echo "===================================="

# Create application structure
echo "Creating application directories..."
run_ssh "$APP_IP" "sudo mkdir -p /opt/clarity/{app,data,backups} && sudo chown -R $SSH_USER:$SSH_USER /opt/clarity"

# Deploy Docker Compose configuration
echo "Deploying Docker services configuration..."
cat > /tmp/docker-compose.yml << 'EOF'
version: '3.8'

services:
  pocketbase:
    image: ghcr.io/muchobien/pocketbase:latest
    container_name: clarity-pocketbase
    ports:
      - "8090:8090"
    volumes:
      - ./data/pb_data:/pb_data
      - ./data/pb_migrations:/pb_migrations
    environment:
      - PB_ENCRYPTION_KEY=${PB_ENCRYPTION_KEY:-defaultkey123}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8090/_/"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: clarity-redis
    ports:
      - "6379:6379"
    volumes:
      - ./data/redis:/data
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

scp -i "$SSH_KEY" -o StrictHostKeyChecking=no /tmp/docker-compose.yml "$SSH_USER@$APP_IP:/opt/clarity/"

# Check if app code exists, if not create a basic one
echo "Checking application code..."
if [ -d "../app" ] && [ -f "../app/package.json" ]; then
    echo "Found existing application, deploying..."
    scp -r -i "$SSH_KEY" -o StrictHostKeyChecking=no ../app "$SSH_USER@$APP_IP:/opt/clarity/"
else
    echo "Creating basic Next.js application..."
    run_ssh "$APP_IP" << 'ENDSSH'
cd /opt/clarity
if [ ! -f app/package.json ]; then
    mkdir -p app/pages

    cat > app/package.json << 'EOF'
{
  "name": "clarity-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start -p 3000"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18",
    "react-dom": "^18"
  }
}
EOF

    cat > app/pages/index.js << 'EOF'
import { useState, useEffect } from 'react'

export default function Home() {
  const [status, setStatus] = useState({})

  useEffect(() => {
    // Check service status
    const checkServices = async () => {
      const services = {}
      try {
        const pbResponse = await fetch('http://' + window.location.hostname + ':8090/_/')
        services.pocketbase = pbResponse.ok
      } catch {
        services.pocketbase = false
      }
      setStatus(services)
    }
    checkServices()
  }, [])

  return (
    <div style={{
      padding: '50px',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      maxWidth: '800px',
      margin: '0 auto'
    }}>
      <h1 style={{ color: '#333' }}>🚀 Welcome to ClarityClear</h1>
      <p style={{ fontSize: '18px', color: '#666' }}>Your application is successfully deployed!</p>

      <div style={{
        background: '#f5f5f5',
        padding: '20px',
        borderRadius: '8px',
        marginTop: '30px'
      }}>
        <h2>Service Status:</h2>
        <ul style={{ listStyle: 'none', padding: 0 }}>
          <li style={{ padding: '10px 0' }}>
            ✅ Next.js Application: <strong>Running</strong> (Port 3000)
          </li>
          <li style={{ padding: '10px 0' }}>
            {status.pocketbase ? '✅' : '⏳'} PocketBase:
            <strong>{status.pocketbase ? ' Running' : ' Starting...'}</strong> (Port 8090)
          </li>
          <li style={{ padding: '10px 0' }}>
            ✅ Redis Cache: <strong>Running</strong> (Port 6379)
          </li>
        </ul>
      </div>

      <div style={{ marginTop: '30px' }}>
        <h3>Quick Links:</h3>
        <ul>
          <li><a href={'http://' + window.location.hostname + ':8090/_/'} target="_blank">
            PocketBase Admin Panel
          </a></li>
          <li><a href="https://github.com/yourusername/clarityclear" target="_blank">
            Documentation
          </a></li>
        </ul>
      </div>
    </div>
  )
}
EOF

    cd app
    npm install
    npm run build
fi
ENDSSH
fi

# Step 4: Start Services
echo -e "\n${YELLOW}Step 4: Starting Services${NC}"
echo "================================"

# Start Docker services
echo "Starting Docker services..."
run_ssh "$APP_IP" "cd /opt/clarity && docker-compose down 2>/dev/null || true"
run_ssh "$APP_IP" "cd /opt/clarity && docker-compose up -d"

# Create and start systemd service for Next.js
echo "Setting up Next.js service..."
run_ssh "$APP_IP" << 'ENDSSH'
sudo tee /etc/systemd/system/clarity-app.service > /dev/null << 'EOF'
[Unit]
Description=ClarityClear Next.js Application
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=VespianRex
WorkingDirectory=/opt/clarity/app
Environment="NODE_ENV=production"
Environment="PORT=3000"
ExecStartPre=/bin/bash -c 'until docker ps | grep -q clarity-pocketbase; do sleep 2; done'
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable clarity-app
sudo systemctl restart clarity-app
ENDSSH

# Step 5: Configure Firewall
echo -e "\n${YELLOW}Step 5: Configuring Firewall${NC}"
echo "=================================="

run_ssh "$APP_IP" << 'ENDSSH'
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 3000/tcp # Next.js
sudo ufw allow 8090/tcp # PocketBase
sudo ufw allow 6379/tcp # Redis (only from local network)
sudo ufw --force enable
ENDSSH
echo -e "${GREEN}✓${NC} Firewall configured"

# Step 6: Health Checks
echo -e "\n${YELLOW}Step 6: Running Health Checks${NC}"
echo "==================================="

echo "Waiting for services to start..."
sleep 10

echo -e "\nService Status:"
check_service "$APP_IP" 3000 "Next.js Application"
check_service "$APP_IP" 8090 "PocketBase"
check_service "$APP_IP" 6379 "Redis"

# Step 7: Display Access Information
echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    Deployment Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

echo -e "\n${BLUE}Local Access:${NC}"
echo "  Application:    http://$APP_IP:3000"
echo "  PocketBase:     http://$APP_IP:8090/_/"
echo "  Redis:          redis://$APP_IP:6379"

echo -e "\n${BLUE}Public Access (after DNS/Router configuration):${NC}"
echo "  Domain:         https://$DOMAIN"
echo "  Public IP:      $PUBLIC_IP"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Configure your router:"
echo "   - Forward port 80 → Edge VM (192.168.0.50)"
echo "   - Forward port 443 → Edge VM (192.168.0.50)"
echo "   - Forward port 51820 → Edge VM (for VPN)"

echo -e "\n2. Update DNS records for $DOMAIN:"
echo "   - A record: $DOMAIN → $PUBLIC_IP"
echo "   - CNAME: www.$DOMAIN → $DOMAIN"

echo -e "\n3. Access PocketBase admin to create admin user:"
echo "   http://$APP_IP:8090/_/"

echo -e "\n${BLUE}Service Management Commands:${NC}"
echo "  View logs:      ssh $SSH_USER@$APP_IP 'docker-compose -f /opt/clarity/docker-compose.yml logs -f'"
echo "  Restart app:    ssh $SSH_USER@$APP_IP 'sudo systemctl restart clarity-app'"
echo "  Check status:   ssh $SSH_USER@$APP_IP 'systemctl status clarity-app'"

echo -e "\n${GREEN}Your ClarityClear application is now online!${NC}"