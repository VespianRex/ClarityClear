#!/usr/bin/env bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════════
#  ClarityClear Complete Deployment Script
#  Combines all lessons learned from previous deployments
# ════════════════════════════════════════════════════════════════════

cd "$(dirname "$0")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }
info() { echo -e "${BLUE}INFO:${NC} $1"; }

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    ClarityClear Complete Deployment System${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Check for environment file
if [[ ! -f .env ]] && [[ -f .env.backup ]]; then
    warn ".env not found, using .env.backup"
    cp .env.backup .env
elif [[ ! -f .env ]]; then
    error "Missing .env file. Copy .env.example to .env and configure it."
    exit 1
fi

# Load environment
set -a
source .env
set +a

# Validate critical variables
required_vars=(PM_API_URL PM_USER PM_PASSWORD PM_NODE)
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        error "Missing required variable: $var"
        exit 1
    fi
done

# Get VM IPs from our discovery
APP_IP="${APP_IP:-192.168.0.180}"
MONITORING_IP="${MONITORING_IP:-192.168.0.207}"
PBS_IP="${PBS_IP:-192.168.0.242}"
STORAGE_IP="${STORAGE_IP:-192.168.0.144}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_clarity}"
SSH_USER="${SSH_USER:-VespianRex}"

# ═══════════════════════════════════════════════════════════════════
# PHASE 1: Infrastructure Verification
# ═══════════════════════════════════════════════════════════════════

phase1_verify_infrastructure() {
    log "Phase 1: Verifying Infrastructure"
    echo "──────────────────────────────────"

    # Check Proxmox
    if ping -c 1 -W 1 "${PM_API_URL#https://}" &>/dev/null 2>&1 || \
       ping -c 1 -W 1 "192.168.0.33" &>/dev/null 2>&1; then
        info "✓ Proxmox server is reachable"
    else
        error "Cannot reach Proxmox server"
        exit 1
    fi

    # Check VM connectivity
    log "Checking VM connectivity:"
    local all_vms_ok=true

    for vm in "App:$APP_IP" "Monitoring:$MONITORING_IP"; do
        name=${vm%:*}
        ip=${vm#*:}
        if ping -c 1 -W 1 "$ip" &>/dev/null 2>&1; then
            info "  ✓ $name VM ($ip) is reachable"
        else
            warn "  ⚠ $name VM ($ip) not responding"
            all_vms_ok=false
        fi
    done

    if ! $all_vms_ok; then
        warn "Some VMs are not responding. Continuing anyway..."
    fi
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: Install Prerequisites on App VM
# ═══════════════════════════════════════════════════════════════════

phase2_install_prerequisites() {
    log "Phase 2: Installing Prerequisites on App VM"
    echo "──────────────────────────────────────────────"

    # Helper function for SSH with error handling
    run_ssh() {
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
            -o BatchMode=yes "$SSH_USER@$1" "${@:2}" 2>/dev/null || {
            warn "SSH command failed on $1, retrying..."
            sleep 2
            ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
                "$SSH_USER@$1" "${@:2}"
        }
    }

    # Install Docker if needed
    if run_ssh "$APP_IP" "docker --version" &>/dev/null; then
        info "✓ Docker already installed"
    else
        log "Installing Docker..."
        run_ssh "$APP_IP" 'curl -fsSL https://get.docker.com | sudo sh'
        run_ssh "$APP_IP" 'sudo usermod -aG docker $USER'
        run_ssh "$APP_IP" 'sudo systemctl enable docker && sudo systemctl start docker'
        info "✓ Docker installed"
    fi

    # Install Docker Compose
    log "Installing Docker Compose..."
    run_ssh "$APP_IP" 'if ! command -v docker-compose &>/dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
    fi'
    info "✓ Docker Compose ready"

    # Install Node.js if needed
    if run_ssh "$APP_IP" "node --version" &>/dev/null; then
        info "✓ Node.js already installed"
    else
        log "Installing Node.js..."
        run_ssh "$APP_IP" 'curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -'
        run_ssh "$APP_IP" 'sudo apt-get install -y nodejs'
        info "✓ Node.js installed"
    fi

    # Create application directories
    log "Creating application structure..."
    run_ssh "$APP_IP" 'sudo mkdir -p /opt/clarity/{app,data,backups}'
    run_ssh "$APP_IP" "sudo chown -R $SSH_USER:$SSH_USER /opt/clarity"
    info "✓ Application directories created"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: Deploy Application
# ═══════════════════════════════════════════════════════════════════

phase3_deploy_application() {
    log "Phase 3: Deploying Application"
    echo "──────────────────────────────────"

    # Create Docker Compose configuration
    log "Creating Docker Compose configuration..."
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

    # Copy configuration to server
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
        /tmp/docker-compose.yml "$SSH_USER@$APP_IP:/opt/clarity/"

    # Check for existing application code
    if [ -d "../app" ] && [ -f "../app/package.json" ]; then
        log "Deploying existing application code..."
        scp -r -i "$SSH_KEY" -o StrictHostKeyChecking=no \
            ../app "$SSH_USER@$APP_IP:/opt/clarity/"
    elif ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no \
         "$SSH_USER@$APP_IP" "[ -f /opt/clarity/app/package.json ]"; then
        info "✓ Application already deployed"
    else
        log "Creating new Next.js application..."
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$APP_IP" bash << 'ENDSSH'
cd /opt/clarity
mkdir -p app/pages app/public

# Create package.json
cat > app/package.json << 'EOF'
{
  "name": "clarityclear",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "typescript": "^5"
  }
}
EOF

# Create main page
cat > app/pages/index.js << 'EOF'
import { useState, useEffect } from 'react'

export default function Home() {
  const [services, setServices] = useState({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const checkServices = async () => {
      const status = {
        app: true,
        pocketbase: false,
        redis: false
      }

      try {
        const pbRes = await fetch(`http://${window.location.hostname}:8090/_/`)
        status.pocketbase = pbRes.ok
      } catch {}

      setServices(status)
      setLoading(false)
    }

    checkServices()
    const interval = setInterval(checkServices, 5000)
    return () => clearInterval(interval)
  }, [])

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      color: 'white',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <div style={{
        background: 'rgba(255, 255, 255, 0.95)',
        color: '#333',
        padding: '3rem',
        borderRadius: '20px',
        boxShadow: '0 25px 50px rgba(0, 0, 0, 0.2)',
        maxWidth: '600px',
        width: '90%'
      }}>
        <h1 style={{ fontSize: '2.5rem', marginBottom: '1rem' }}>
          🚀 ClarityClear
        </h1>
        <p style={{ fontSize: '1.2rem', color: '#666' }}>
          Your application is successfully deployed!
        </p>

        <div style={{
          background: '#f8f9fa',
          padding: '1.5rem',
          borderRadius: '10px',
          marginTop: '2rem'
        }}>
          <h2 style={{ fontSize: '1.5rem', marginBottom: '1rem' }}>
            Service Status
          </h2>
          {loading ? (
            <p>Checking services...</p>
          ) : (
            <ul style={{ listStyle: 'none', padding: 0 }}>
              <li style={{ padding: '0.5rem 0' }}>
                {services.app ? '✅' : '❌'} Next.js Application
              </li>
              <li style={{ padding: '0.5rem 0' }}>
                {services.pocketbase ? '✅' : '⏳'} PocketBase Database
              </li>
              <li style={{ padding: '0.5rem 0' }}>
                {services.redis ? '✅' : '⏳'} Redis Cache
              </li>
            </ul>
          )}
        </div>

        <div style={{ marginTop: '2rem' }}>
          <a href={`http://${window.location.hostname}:8090/_/`}
             target="_blank"
             style={{
               display: 'inline-block',
               background: '#667eea',
               color: 'white',
               padding: '1rem 2rem',
               borderRadius: '10px',
               textDecoration: 'none',
               marginRight: '1rem'
             }}>
            Open PocketBase Admin
          </a>
        </div>
      </div>
    </div>
  )
}
EOF

# Install dependencies and build
cd app
npm install
npm run build
ENDSSH
        info "✓ Next.js application created"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 4: Start Services
# ═══════════════════════════════════════════════════════════════════

phase4_start_services() {
    log "Phase 4: Starting Services"
    echo "──────────────────────────────"

    # Start Docker services
    log "Starting Docker services..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$APP_IP" \
        "cd /opt/clarity && docker-compose down 2>/dev/null || true"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$APP_IP" \
        "cd /opt/clarity && docker-compose up -d"
    info "✓ Docker services started"

    # Create systemd service for Next.js
    log "Creating Next.js systemd service..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$APP_IP" bash << 'ENDSSH'
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
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=append:/var/log/clarity-app.log
StandardError=append:/var/log/clarity-app-error.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable clarity-app
sudo systemctl restart clarity-app
ENDSSH
    info "✓ Next.js service configured"

    # Setup firewall rules
    log "Configuring firewall..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$APP_IP" bash << 'ENDSSH'
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 3000/tcp # Next.js
sudo ufw allow 8090/tcp # PocketBase
sudo ufw allow from 192.168.0.0/24 to any port 6379 # Redis from LAN only
sudo ufw --force enable 2>/dev/null || true
ENDSSH
    info "✓ Firewall configured"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 5: Health Checks
# ═══════════════════════════════════════════════════════════════════

phase5_health_checks() {
    log "Phase 5: Running Health Checks"
    echo "──────────────────────────────"

    # Wait for services to start
    log "Waiting for services to start..."
    sleep 10

    # Check each service
    local all_ok=true

    if curl -s -o /dev/null -w "%{http_code}" "http://$APP_IP:3000" | grep -q "200"; then
        info "✓ Next.js application is running"
    else
        warn "⚠ Next.js application not responding"
        all_ok=false
    fi

    if curl -s -o /dev/null -w "%{http_code}" "http://$APP_IP:8090/_/" | grep -q "200"; then
        info "✓ PocketBase is running"
    else
        warn "⚠ PocketBase not responding"
        all_ok=false
    fi

    if nc -zv -w2 "$APP_IP" 6379 &>/dev/null; then
        info "✓ Redis is running"
    else
        warn "⚠ Redis not responding"
        all_ok=false
    fi

    return $([ "$all_ok" = true ] && echo 0 || echo 1)
}

# ═══════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════

main() {
    # Run all phases
    phase1_verify_infrastructure
    phase2_install_prerequisites
    phase3_deploy_application
    phase4_start_services
    phase5_health_checks

    # Display results
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    Deployment Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

    echo -e "\n${BLUE}Local Access:${NC}"
    echo "  Application:    http://$APP_IP:3000"
    echo "  PocketBase:     http://$APP_IP:8090/_/"
    echo "  Redis:          redis://$APP_IP:6379"

    echo -e "\n${BLUE}Public Access Configuration:${NC}"
    echo "  1. Router Port Forwarding:"
    echo "     - 80 → 192.168.0.50 (Edge Load Balancer)"
    echo "     - 443 → 192.168.0.50 (Edge Load Balancer)"
    echo "     - 51820 → 192.168.0.50 (VPN)"

    echo -e "\n  2. DNS Configuration for ${DOMAIN_BASE}:"
    echo "     - A record: ${DOMAIN_BASE} → ${PUBLIC_IP}"
    echo "     - CNAME: www.${DOMAIN_BASE} → ${DOMAIN_BASE}"

    echo -e "\n${BLUE}Service Management:${NC}"
    echo "  View logs:      ssh $SSH_USER@$APP_IP 'journalctl -u clarity-app -f'"
    echo "  Docker logs:    ssh $SSH_USER@$APP_IP 'docker-compose -f /opt/clarity/docker-compose.yml logs -f'"
    echo "  Restart app:    ssh $SSH_USER@$APP_IP 'sudo systemctl restart clarity-app'"
    echo "  Check status:   ssh $SSH_USER@$APP_IP 'systemctl status clarity-app'"

    echo -e "\n${GREEN}Your ClarityClear application is online at http://$APP_IP:3000${NC}"
}

# Handle script arguments
case "${1:-}" in
    verify)
        phase1_verify_infrastructure
        ;;
    install)
        phase2_install_prerequisites
        ;;
    deploy)
        phase3_deploy_application
        ;;
    start)
        phase4_start_services
        ;;
    check)
        phase5_health_checks
        ;;
    *)
        main
        ;;
esac