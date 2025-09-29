#!/usr/bin/env bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════════
#  ClarityClear Intelligent Deployment Script
#  Only runs what's needed based on thorough checks
# ════════════════════════════════════════════════════════════════════

cd "$(dirname "$0")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }
info() { echo -e "${BLUE}INFO:${NC} $1"; }
skip() { echo -e "${CYAN}SKIP:${NC} $1"; }
check() { echo -e "${YELLOW}CHECK:${NC} $1"; }

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    ClarityClear Smart Deployment System${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Configuration
APP_IP="${APP_IP:-192.168.0.180}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_clarity}"
SSH_USER="${SSH_USER:-VespianRex}"
APP_DIR="/opt/clarity"
PROJECT_ROOT="$(dirname "$(pwd)")"  # Parent directory of infra/

# Global variables for tracking what needs to be done
NEEDS_DOCKER=false
NEEDS_NODE=false
NEEDS_POCKETBASE=false
NEEDS_APP_DEPLOY=false
NEEDS_SYSTEMD=false
NEEDS_FIREWALL=false
NEEDS_PM2=false

# SSH helper with proper error handling
run_ssh() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        -o BatchMode=yes "$SSH_USER@$1" "${@:2}" 2>/dev/null
}

# Silent SSH check (returns exit code only)
ssh_check() {
    run_ssh "$1" "${@:2}" >/dev/null 2>&1
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 1: Deep System Analysis
# ═══════════════════════════════════════════════════════════════════

analyze_system() {
    log "Phase 1: Deep System Analysis"
    echo "──────────────────────────────────"

    # Check VM connectivity
    check "Testing VM connectivity..."
    if ! ping -c 1 -W 1 "$APP_IP" &>/dev/null; then
        error "Cannot reach App VM at $APP_IP"
        exit 1
    fi
    info "✓ VM is reachable at $APP_IP"

    # Check SSH access
    check "Testing SSH access..."
    if ! ssh_check "$APP_IP" "echo 'SSH OK'"; then
        error "Cannot SSH to $APP_IP with key $SSH_KEY"
        exit 1
    fi
    info "✓ SSH access confirmed"

    # Check Docker installation and version
    check "Checking Docker installation..."
    DOCKER_VERSION=$(run_ssh "$APP_IP" "docker --version 2>/dev/null | grep -oP 'Docker version \K[0-9.]+'" || echo "")

    if [[ -z "$DOCKER_VERSION" ]]; then
        warn "Docker not installed"
        NEEDS_DOCKER=true
    else
        # Check if Docker is actually running
        if ! ssh_check "$APP_IP" "docker ps"; then
            warn "Docker installed (v$DOCKER_VERSION) but not running properly"
            NEEDS_DOCKER=true
        else
            # Check Docker Compose
            if ! ssh_check "$APP_IP" "docker-compose --version"; then
                warn "Docker Compose not found"
                NEEDS_DOCKER=true
            else
                skip "Docker v$DOCKER_VERSION already installed and running"
            fi
        fi
    fi

    # Check Node.js installation and version
    check "Checking Node.js installation..."
    NODE_VERSION=$(run_ssh "$APP_IP" "node --version 2>/dev/null | grep -oP 'v\K[0-9.]+'" || echo "")

    if [[ -z "$NODE_VERSION" ]]; then
        warn "Node.js not installed"
        NEEDS_NODE=true
    else
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
        if [[ "$NODE_MAJOR" -lt 18 ]]; then
            warn "Node.js v$NODE_VERSION is too old (need v18+)"
            NEEDS_NODE=true
        else
            # Check npm
            NPM_VERSION=$(run_ssh "$APP_IP" "npm --version 2>/dev/null" || echo "")
            if [[ -z "$NPM_VERSION" ]]; then
                warn "npm not found"
                NEEDS_NODE=true
            else
                skip "Node.js v$NODE_VERSION with npm v$NPM_VERSION already installed"
            fi
        fi
    fi

    # Check PocketBase binary
    check "Checking PocketBase installation..."
    if ssh_check "$APP_IP" "test -f $APP_DIR/pocketbase"; then
        # Check if it's executable and correct version
        PB_VERSION=$(run_ssh "$APP_IP" "$APP_DIR/pocketbase --version 2>/dev/null | grep -oP 'pocketbase version \K[0-9.]+'" || echo "")
        if [[ -z "$PB_VERSION" ]]; then
            warn "PocketBase binary exists but not working"
            NEEDS_POCKETBASE=true
        else
            skip "PocketBase v$PB_VERSION already installed"
        fi
    else
        warn "PocketBase not found"
        NEEDS_POCKETBASE=true
    fi

    # Check if application is deployed
    check "Checking application deployment..."
    if ssh_check "$APP_IP" "test -f $APP_DIR/app/package.json"; then
        # Check if it's the correct app by looking for specific dependencies
        if ssh_check "$APP_IP" "grep -q 'next' $APP_DIR/app/package.json && grep -q 'pocketbase' $APP_DIR/app/package.json"; then
            # Check if node_modules exists and is recent
            if ssh_check "$APP_IP" "test -d $APP_DIR/app/node_modules"; then
                # Check if build exists
                if ssh_check "$APP_IP" "test -d $APP_DIR/app/.next"; then
                    skip "Application already deployed with build"
                else
                    warn "Application deployed but not built"
                    NEEDS_APP_DEPLOY=true
                fi
            else
                warn "Application code exists but dependencies not installed"
                NEEDS_APP_DEPLOY=true
            fi
        else
            warn "Wrong application deployed (placeholder app found)"
            NEEDS_APP_DEPLOY=true
        fi
    else
        warn "Application not deployed"
        NEEDS_APP_DEPLOY=true
    fi

    # Check systemd services
    check "Checking systemd services..."
    SYSTEMD_SERVICES=()

    # Check Next.js service
    if ssh_check "$APP_IP" "systemctl is-enabled clarity-app 2>/dev/null"; then
        if ssh_check "$APP_IP" "systemctl is-active clarity-app"; then
            skip "clarity-app service is running"
        else
            warn "clarity-app service exists but not running"
            NEEDS_SYSTEMD=true
        fi
    else
        warn "clarity-app service not configured"
        NEEDS_SYSTEMD=true
    fi

    # Check PocketBase service
    if ssh_check "$APP_IP" "systemctl is-enabled pocketbase 2>/dev/null"; then
        if ssh_check "$APP_IP" "systemctl is-active pocketbase"; then
            skip "pocketbase service is running"
        else
            warn "pocketbase service exists but not running"
            NEEDS_SYSTEMD=true
        fi
    else
        warn "pocketbase service not configured"
        NEEDS_SYSTEMD=true
    fi

    # Check PM2 (alternative to systemd)
    check "Checking PM2 process manager..."
    if ssh_check "$APP_IP" "pm2 --version"; then
        PM2_APPS=$(run_ssh "$APP_IP" "pm2 list --silent | grep -c 'clarity' || echo 0")
        if [[ "$PM2_APPS" -gt 0 ]]; then
            skip "PM2 managing $PM2_APPS clarity processes"
        else
            warn "PM2 installed but not managing apps"
            NEEDS_PM2=true
        fi
    else
        info "PM2 not installed (using systemd instead)"
    fi

    # Check firewall configuration
    check "Checking firewall rules..."
    UFW_STATUS=$(run_ssh "$APP_IP" "sudo ufw status 2>/dev/null | head -1" || echo "inactive")

    if [[ "$UFW_STATUS" == *"active"* ]]; then
        # Check specific ports
        PORTS_OK=true
        for port in 22 3000 8090; do
            if ! run_ssh "$APP_IP" "sudo ufw status | grep -q '$port'" 2>/dev/null; then
                warn "Port $port not allowed in firewall"
                PORTS_OK=false
            fi
        done

        if $PORTS_OK; then
            skip "Firewall properly configured"
        else
            NEEDS_FIREWALL=true
        fi
    else
        warn "Firewall not active"
        NEEDS_FIREWALL=true
    fi

    # Check running services on ports
    check "Checking service availability..."
    SERVICES_STATUS=""

    if nc -zv -w1 "$APP_IP" 3000 &>/dev/null; then
        SERVICES_STATUS="$SERVICES_STATUS\n  ✓ Port 3000 (Next.js) is open"
    else
        SERVICES_STATUS="$SERVICES_STATUS\n  ✗ Port 3000 (Next.js) not accessible"
    fi

    if nc -zv -w1 "$APP_IP" 8090 &>/dev/null; then
        SERVICES_STATUS="$SERVICES_STATUS\n  ✓ Port 8090 (PocketBase) is open"
    else
        SERVICES_STATUS="$SERVICES_STATUS\n  ✗ Port 8090 (PocketBase) not accessible"
    fi

    echo -e "$SERVICES_STATUS"

    # Summary of what needs to be done
    echo ""
    log "Analysis Complete - Actions Required:"
    echo "──────────────────────────────────────"

    local needs_work=false
    [[ "$NEEDS_DOCKER" == true ]] && { echo "  • Install/Fix Docker"; needs_work=true; }
    [[ "$NEEDS_NODE" == true ]] && { echo "  • Install/Update Node.js"; needs_work=true; }
    [[ "$NEEDS_POCKETBASE" == true ]] && { echo "  • Install PocketBase"; needs_work=true; }
    [[ "$NEEDS_APP_DEPLOY" == true ]] && { echo "  • Deploy Application"; needs_work=true; }
    [[ "$NEEDS_SYSTEMD" == true ]] && { echo "  • Configure Services"; needs_work=true; }
    [[ "$NEEDS_FIREWALL" == true ]] && { echo "  • Configure Firewall"; needs_work=true; }

    if ! $needs_work; then
        echo -e "${GREEN}  ✓ Everything is already properly configured!${NC}"
        return 1  # Signal that nothing needs to be done
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: Install Only What's Needed
# ═══════════════════════════════════════════════════════════════════

install_prerequisites() {
    log "Phase 2: Installing Prerequisites"
    echo "──────────────────────────────────"

    # Install Docker if needed
    if [[ "$NEEDS_DOCKER" == true ]]; then
        log "Installing Docker..."
        run_ssh "$APP_IP" << 'ENDSSH'
# Remove old Docker installations
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install Docker
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Clean up
rm /tmp/get-docker.sh
ENDSSH
        info "✓ Docker installed and configured"
    else
        skip "Docker installation not needed"
    fi

    # Install Node.js if needed
    if [[ "$NEEDS_NODE" == true ]]; then
        log "Installing Node.js v20..."
        run_ssh "$APP_IP" << 'ENDSSH'
# Remove old Node.js
sudo apt-get remove -y nodejs npm 2>/dev/null || true

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally for process management
sudo npm install -g pm2

# Verify installation
node --version
npm --version
ENDSSH
        info "✓ Node.js v20 installed"
    else
        skip "Node.js installation not needed"
    fi

    # Install PocketBase if needed
    if [[ "$NEEDS_POCKETBASE" == true ]]; then
        log "Installing PocketBase..."
        run_ssh "$APP_IP" << 'ENDSSH'
# Create directory
sudo mkdir -p /opt/clarity
sudo chown -R $USER:$USER /opt/clarity

# Download PocketBase
cd /opt/clarity
curl -L -o pocketbase.zip \
    https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase_0.25.0_linux_amd64.zip

# Extract
unzip -o pocketbase.zip
rm pocketbase.zip

# Make executable
chmod +x pocketbase

# Verify
./pocketbase --version
ENDSSH
        info "✓ PocketBase installed"
    else
        skip "PocketBase installation not needed"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: Deploy Application
# ═══════════════════════════════════════════════════════════════════

deploy_application() {
    log "Phase 3: Deploying Application"
    echo "──────────────────────────────────"

    if [[ "$NEEDS_APP_DEPLOY" == false ]]; then
        skip "Application deployment not needed"
        return
    fi

    # Check if we have the actual application code
    if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
        error "Cannot find application code at $PROJECT_ROOT"
        exit 1
    fi

    log "Preparing application for deployment..."

    # Create temporary deployment package
    DEPLOY_DIR="/tmp/clarity-deploy-$$"
    mkdir -p "$DEPLOY_DIR"

    # Copy only necessary files (exclude node_modules, .next, etc.)
    info "Creating deployment package..."
    rsync -av --exclude=node_modules --exclude=.next --exclude=.git \
        --exclude=pb_data --exclude=pocketbase \
        "$PROJECT_ROOT/" "$DEPLOY_DIR/"

    # Create deployment info file
    cat > "$DEPLOY_DIR/deploy-info.json" << EOF
{
  "deployedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "version": "$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'unknown')",
  "branch": "$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo 'unknown')"
}
EOF

    # Upload to server
    log "Uploading application code..."
    run_ssh "$APP_IP" "mkdir -p $APP_DIR/app"
    rsync -avz --delete \
        -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
        "$DEPLOY_DIR/" "$SSH_USER@$APP_IP:$APP_DIR/app/"

    # Clean up temp directory
    rm -rf "$DEPLOY_DIR"

    # Install dependencies and build on server
    log "Installing dependencies and building..."
    run_ssh "$APP_IP" << 'ENDSSH'
cd /opt/clarity/app

# Install dependencies
echo "Installing npm dependencies..."
npm ci --prefer-offline --no-audit || npm install

# Build the application
echo "Building Next.js application..."
npm run build

# Verify build
if [ -d ".next" ]; then
    echo "✓ Build successful"
else
    echo "✗ Build failed"
    exit 1
fi
ENDSSH

    # Copy PocketBase migrations if they exist
    if [[ -d "$PROJECT_ROOT/pb_migrations" ]]; then
        log "Copying PocketBase migrations..."
        scp -r -i "$SSH_KEY" -o StrictHostKeyChecking=no \
            "$PROJECT_ROOT/pb_migrations" "$SSH_USER@$APP_IP:$APP_DIR/"
    fi

    info "✓ Application deployed successfully"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 4: Configure Services
# ═══════════════════════════════════════════════════════════════════

configure_services() {
    log "Phase 4: Configuring Services"
    echo "──────────────────────────────────"

    if [[ "$NEEDS_SYSTEMD" == false ]]; then
        skip "Service configuration not needed"
    else
        # Configure PocketBase service
        log "Configuring PocketBase service..."
        run_ssh "$APP_IP" << 'ENDSSH'
sudo tee /etc/systemd/system/pocketbase.service > /dev/null << 'EOF'
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=VespianRex
Group=VespianRex
WorkingDirectory=/opt/clarity
ExecStart=/opt/clarity/pocketbase serve --http=0.0.0.0:8090
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pocketbase
sudo systemctl restart pocketbase
ENDSSH

        # Configure Next.js service
        log "Configuring Next.js service..."
        run_ssh "$APP_IP" << 'ENDSSH'
sudo tee /etc/systemd/system/clarity-app.service > /dev/null << 'EOF'
[Unit]
Description=ClarityClear Next.js Application
After=network.target pocketbase.service
Wants=pocketbase.service

[Service]
Type=simple
User=VespianRex
Group=VespianRex
WorkingDirectory=/opt/clarity/app
Environment="NODE_ENV=production"
Environment="PORT=3000"
Environment="NEXT_PUBLIC_POCKETBASE_URL=http://localhost:8090"
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable clarity-app
sudo systemctl restart clarity-app
ENDSSH

        info "✓ Services configured and started"
    fi

    # Configure firewall if needed
    if [[ "$NEEDS_FIREWALL" == true ]]; then
        log "Configuring firewall..."
        run_ssh "$APP_IP" << 'ENDSSH'
# Reset firewall rules
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow web services
sudo ufw allow 3000/tcp comment 'Next.js'
sudo ufw allow 8090/tcp comment 'PocketBase'

# Enable firewall
sudo ufw --force enable

# Show status
sudo ufw status verbose
ENDSSH
        info "✓ Firewall configured"
    else
        skip "Firewall configuration not needed"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 5: Health Verification
# ═══════════════════════════════════════════════════════════════════

verify_deployment() {
    log "Phase 5: Verifying Deployment"
    echo "──────────────────────────────────"

    local all_good=true

    # Wait for services to stabilize
    log "Waiting for services to start..."
    sleep 5

    # Check systemd services
    check "Checking service status..."

    if ssh_check "$APP_IP" "systemctl is-active pocketbase"; then
        info "✓ PocketBase service is running"
    else
        error "✗ PocketBase service is not running"
        run_ssh "$APP_IP" "journalctl -u pocketbase -n 20 --no-pager"
        all_good=false
    fi

    if ssh_check "$APP_IP" "systemctl is-active clarity-app"; then
        info "✓ Next.js service is running"
    else
        error "✗ Next.js service is not running"
        run_ssh "$APP_IP" "journalctl -u clarity-app -n 20 --no-pager"
        all_good=false
    fi

    # Check HTTP endpoints
    check "Testing HTTP endpoints..."

    # Test Next.js
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$APP_IP:3000" || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        info "✓ Next.js responding (HTTP $HTTP_CODE)"
    else
        error "✗ Next.js not responding properly (HTTP $HTTP_CODE)"
        all_good=false
    fi

    # Test PocketBase
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$APP_IP:8090/api/health" || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        info "✓ PocketBase API responding (HTTP $HTTP_CODE)"
    else
        error "✗ PocketBase API not responding properly (HTTP $HTTP_CODE)"
        all_good=false
    fi

    # Check disk usage
    check "Checking disk space..."
    DISK_USAGE=$(run_ssh "$APP_IP" "df -h /opt/clarity | tail -1 | awk '{print \$5}' | sed 's/%//'")
    if [[ "$DISK_USAGE" -gt 80 ]]; then
        warn "Disk usage is high: ${DISK_USAGE}%"
    else
        info "✓ Disk usage is ${DISK_USAGE}%"
    fi

    # Check memory usage
    MEM_USAGE=$(run_ssh "$APP_IP" "free -m | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100}'")
    info "Memory usage: ${MEM_USAGE}%"

    return $([ "$all_good" = true ] && echo 0 || echo 1)
}

# ═══════════════════════════════════════════════════════════════════
# Main Execution
# ═══════════════════════════════════════════════════════════════════

main() {
    # Run analysis
    if ! analyze_system; then
        echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}Everything is already properly deployed and running!${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

        echo -e "\n${BLUE}Access your application:${NC}"
        echo "  • Next.js App: http://$APP_IP:3000"
        echo "  • PocketBase Admin: http://$APP_IP:8090/_/"

        exit 0
    fi

    # Ask for confirmation
    echo ""
    read -p "Proceed with deployment? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Deployment cancelled"
        exit 0
    fi

    # Execute only what's needed
    install_prerequisites
    deploy_application
    configure_services

    # Verify everything is working
    if verify_deployment; then
        echo -e "\n${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}    Deployment Successful!${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    else
        echo -e "\n${YELLOW}════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}    Deployment completed with warnings${NC}"
        echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    fi

    echo -e "\n${BLUE}Access Information:${NC}"
    echo "──────────────────────────────────"
    echo "  Local Access:"
    echo "    • Next.js App: http://$APP_IP:3000"
    echo "    • PocketBase Admin: http://$APP_IP:8090/_/"

    echo -e "\n  Service Management:"
    echo "    • View Next.js logs: ssh $SSH_USER@$APP_IP 'journalctl -u clarity-app -f'"
    echo "    • View PocketBase logs: ssh $SSH_USER@$APP_IP 'journalctl -u pocketbase -f'"
    echo "    • Restart services: ssh $SSH_USER@$APP_IP 'sudo systemctl restart clarity-app pocketbase'"

    echo -e "\n  Public Access (configure router):"
    echo "    • Forward ports 80,443 → 192.168.0.50 (Edge LB)"
    echo "    • Update DNS: andub.go.ro → 86.121.4.16"
}

# Command line interface
case "${1:-}" in
    check|analyze)
        analyze_system
        ;;
    install)
        analyze_system && install_prerequisites
        ;;
    deploy)
        analyze_system && deploy_application
        ;;
    services)
        analyze_system && configure_services
        ;;
    verify)
        verify_deployment
        ;;
    force)
        # Force all steps regardless of checks
        NEEDS_DOCKER=true
        NEEDS_NODE=true
        NEEDS_POCKETBASE=true
        NEEDS_APP_DEPLOY=true
        NEEDS_SYSTEMD=true
        NEEDS_FIREWALL=true
        install_prerequisites
        deploy_application
        configure_services
        verify_deployment
        ;;
    *)
        main
        ;;
esac