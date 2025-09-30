#!/bin/bash
set -euo pipefail

# ════════════════════════════════════════════════════════════════════
#  BestClear Smart Deployment Script
#  Runs on server, triggered by cron or webhook
# ════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
info() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"; }

# Configuration
APP_DIR="/opt/clarity/app"
LOG_DIR="/var/log/clarity-deploy"
DEPLOY_LOG="$LOG_DIR/deploy-$(date +%Y%m%d-%H%M%S).log"
HEALTH_CHECK_URL="http://localhost:3000/api/health"
HEALTH_CHECK_TIMEOUT=30
ROLLBACK_ENABLED=true

# Create log directory
sudo mkdir -p "$LOG_DIR"
sudo chown VespianRex:VespianRex "$LOG_DIR"

# Redirect all output to log file and console
exec > >(tee -a "$DEPLOY_LOG") 2>&1

log "════════════════════════════════════════════════════════"
log "  BestClear Deployment Started"
log "════════════════════════════════════════════════════════"

# Change to app directory
cd "$APP_DIR" || { error "Failed to cd to $APP_DIR"; exit 1; }

# ═══════════════════════════════════════════════════════════════════
# PHASE 1: Pre-deployment Checks
# ═══════════════════════════════════════════════════════════════════

log "Phase 1: Pre-deployment Checks"
echo "──────────────────────────────────"

# Store current state for rollback
CURRENT_SHA=$(git rev-parse HEAD)
CURRENT_BRANCH=$(git branch --show-current)
log "Current commit: $CURRENT_SHA"
log "Current branch: $CURRENT_BRANCH"

# Check if service is running
if ! systemctl is-active --quiet clarity-app; then
    error "clarity-app service is not running!"
    exit 1
fi
info "✓ Service is running"

# Check current health
if ! curl -sf --max-time 5 "$HEALTH_CHECK_URL" > /dev/null; then
    warn "⚠ Health check failing before deployment"
    warn "Proceeding anyway, but deployment might fail"
fi

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: Fetch Latest Changes
# ═══════════════════════════════════════════════════════════════════

log "Phase 2: Fetching Latest Changes"
echo "──────────────────────────────────"

# Fetch from remote
if ! git fetch origin $CURRENT_BRANCH; then
    error "Failed to fetch from remote"
    exit 1
fi

# Check if there are new commits
LATEST_SHA=$(git rev-parse origin/$CURRENT_BRANCH)

if [ "$CURRENT_SHA" = "$LATEST_SHA" ]; then
    info "✓ Already up to date (commit: $CURRENT_SHA)"
    log "No deployment needed"
    exit 0
fi

log "New commits available:"
git log --oneline $CURRENT_SHA..$LATEST_SHA

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: Analyze Changes
# ═══════════════════════════════════════════════════════════════════

log "Phase 3: Analyzing Changes"
echo "──────────────────────────────────"

# Detect what changed
NEEDS_INSTALL=false
NEEDS_BUILD=false
NEEDS_MIGRATION=false

if git diff $CURRENT_SHA $LATEST_SHA --name-only | grep -q "package.json\|package-lock.json"; then
    warn "Dependencies changed - will reinstall"
    NEEDS_INSTALL=true
    NEEDS_BUILD=true
fi

if git diff $CURRENT_SHA $LATEST_SHA --name-only | grep -qE "^src/|^public/|next.config"; then
    info "Source code changed - will rebuild"
    NEEDS_BUILD=true
fi

if git diff $CURRENT_SHA $LATEST_SHA --name-only | grep -q "pb_migrations/"; then
    warn "Database migrations detected"
    NEEDS_MIGRATION=true
fi

# Show what will happen
log "Deployment plan:"
echo "  - Git pull: YES"
[ "$NEEDS_INSTALL" = true ] && echo "  - npm install: YES" || echo "  - npm install: NO (cached)"
[ "$NEEDS_BUILD" = true ] && echo "  - npm build: YES" || echo "  - npm build: NO (cached)"
[ "$NEEDS_MIGRATION" = true ] && echo "  - DB migration: YES" || echo "  - DB migration: NO"
echo "  - Service restart: YES"

# ═══════════════════════════════════════════════════════════════════
# PHASE 4: Backup Current State (VM-Level Snapshot)
# ═══════════════════════════════════════════════════════════════════

log "Phase 4: Creating Backups"
echo "──────────────────────────────────"

# Create Proxmox VM snapshot (VM-level backup)
log "Creating Proxmox VM snapshot..."
SNAPSHOT_DESC="Pre-deploy: $LATEST_SHA from $CURRENT_SHA"

if ssh -i /home/VespianRex/.ssh/id_proxmox -o StrictHostKeyChecking=no root@192.168.0.33 \
    "/usr/local/bin/proxmox-snapshot.sh create '$SNAPSHOT_DESC'" 2>/dev/null; then
    log "✓ Proxmox VM snapshot created"
    PROXMOX_SNAPSHOT_CREATED=true
else
    warn "⚠ Failed to create Proxmox snapshot (will continue anyway)"
    warn "  Fallback: Using local backups only"
    PROXMOX_SNAPSHOT_CREATED=false
fi

# Backup .next directory (file-level backup)
if [ -d ".next" ]; then
    BACKUP_DIR="/opt/clarity/backups/deploy-$CURRENT_SHA"
    mkdir -p "$BACKUP_DIR"
    cp -r .next "$BACKUP_DIR/" 2>/dev/null || true
    log "✓ Build backup created at $BACKUP_DIR"
fi

# Backup PocketBase database (file-level backup)
if [ -f "../pb_data/data.db" ]; then
    cp "../pb_data/data.db" "../pb_data/data.db.backup-$(date +%Y%m%d-%H%M%S)"
    log "✓ Database backup created"
fi

# ═══════════════════════════════════════════════════════════════════
# PHASE 5: Deploy New Version
# ═══════════════════════════════════════════════════════════════════

log "Phase 5: Deploying New Version"
echo "──────────────────────────────────"

# Pull latest changes
if ! git pull origin $CURRENT_BRANCH; then
    error "Git pull failed"
    exit 1
fi

NEW_SHA=$(git rev-parse HEAD)
log "✓ Pulled to commit: $NEW_SHA"

# Install dependencies if needed
if [ "$NEEDS_INSTALL" = true ]; then
    log "Installing dependencies..."
    if ! npm ci --prefer-offline; then
        error "npm install failed"
        # Rollback
        git reset --hard $CURRENT_SHA
        exit 1
    fi
    log "✓ Dependencies installed"
fi

# Build if needed
if [ "$NEEDS_BUILD" = true ]; then
    log "Building application..."
    if ! npm run build; then
        error "Build failed"
        # Rollback
        git reset --hard $CURRENT_SHA
        [ "$NEEDS_INSTALL" = true ] && npm ci
        exit 1
    fi
    log "✓ Build completed successfully"

    # Verify build output
    if [ ! -d ".next" ]; then
        error "Build succeeded but .next directory missing!"
        git reset --hard $CURRENT_SHA
        exit 1
    fi
fi

# Handle database migrations
if [ "$NEEDS_MIGRATION" = true ]; then
    warn "Database migrations detected"
    log "Copying migrations to PocketBase..."

    # Copy migrations
    if [ -d "pb_migrations" ]; then
        cp -r pb_migrations/* ../pb_migrations/ 2>/dev/null || true
        log "✓ Migrations copied"
    fi

    # PocketBase auto-migrates on restart
    log "Migrations will apply on PocketBase restart"
fi

# ═══════════════════════════════════════════════════════════════════
# PHASE 6: Restart Services
# ═══════════════════════════════════════════════════════════════════

log "Phase 6: Restarting Services"
echo "──────────────────────────────────"

# Restart PocketBase first (if migrations)
if [ "$NEEDS_MIGRATION" = true ]; then
    log "Restarting PocketBase..."
    sudo systemctl restart pocketbase
    sleep 3

    if ! systemctl is-active --quiet pocketbase; then
        error "PocketBase failed to start after migration!"
        error "Manual intervention required"
        exit 1
    fi
    log "✓ PocketBase restarted"
fi

# Restart Next.js app
log "Restarting Next.js application..."
sudo systemctl restart clarity-app

# Wait for service to start
sleep 5

# ═══════════════════════════════════════════════════════════════════
# PHASE 7: Health Checks
# ═══════════════════════════════════════════════════════════════════

log "Phase 7: Running Health Checks"
echo "──────────────────────────────────"

# Check if service started
if ! systemctl is-active --quiet clarity-app; then
    error "Service failed to start!"

    if [ "$ROLLBACK_ENABLED" = true ]; then
        warn "Initiating rollback..."
        git reset --hard $CURRENT_SHA
        [ "$NEEDS_INSTALL" = true ] && npm ci
        [ "$NEEDS_BUILD" = true ] && npm run build
        sudo systemctl restart clarity-app
        error "Rolled back to $CURRENT_SHA"
    fi

    exit 1
fi
info "✓ Service is running"

# HTTP health check
log "Checking application health..."
HEALTH_CHECK_ATTEMPTS=0
HEALTH_OK=false

while [ $HEALTH_CHECK_ATTEMPTS -lt $HEALTH_CHECK_TIMEOUT ]; do
    if curl -sf --max-time 2 "$HEALTH_CHECK_URL" > /dev/null; then
        HEALTH_OK=true
        break
    fi

    sleep 1
    HEALTH_CHECK_ATTEMPTS=$((HEALTH_CHECK_ATTEMPTS + 1))
done

if [ "$HEALTH_OK" = false ]; then
    error "Health check failed after $HEALTH_CHECK_TIMEOUT seconds"

    # Show logs
    warn "Last 20 lines of service logs:"
    journalctl -u clarity-app -n 20 --no-pager

    if [ "$ROLLBACK_ENABLED" = true ]; then
        warn "Initiating rollback..."
        git reset --hard $CURRENT_SHA
        [ "$NEEDS_INSTALL" = true ] && npm ci
        [ "$NEEDS_BUILD" = true ] && npm run build
        sudo systemctl restart clarity-app
        error "Rolled back to $CURRENT_SHA"
    fi

    exit 1
fi

log "✓ Health check passed"

# Test PocketBase connection
if curl -sf --max-time 5 "http://localhost:8090/api/health" > /dev/null; then
    log "✓ PocketBase is healthy"
else
    warn "⚠ PocketBase health check failed (might be starting)"
fi

# ═══════════════════════════════════════════════════════════════════
# PHASE 8: Post-Deployment
# ═══════════════════════════════════════════════════════════════════

log "Phase 8: Post-Deployment Tasks"
echo "──────────────────────────────────"

# Record deployment
DEPLOY_INFO="/opt/clarity/deployments.log"
cat >> "$DEPLOY_INFO" << EOF
$(date -u +"%Y-%m-%d %H:%M:%S UTC") - Deployed $NEW_SHA (from $CURRENT_SHA)
  Branch: $CURRENT_BRANCH
  Install: $NEEDS_INSTALL
  Build: $NEEDS_BUILD
  Migration: $NEEDS_MIGRATION
  Status: SUCCESS
EOF

# Clean old backups (keep last 10)
find /opt/clarity/backups -type d -name "deploy-*" | sort -r | tail -n +11 | xargs rm -rf 2>/dev/null || true

# Clean old logs (keep last 30 days)
find "$LOG_DIR" -name "deploy-*.log" -mtime +30 -delete 2>/dev/null || true

log "✓ Cleanup complete"

# ═══════════════════════════════════════════════════════════════════
# SUCCESS
# ═══════════════════════════════════════════════════════════════════

log "════════════════════════════════════════════════════════"
log "  ✅ Deployment Successful!"
log "════════════════════════════════════════════════════════"
log ""
log "Deployed commit: $NEW_SHA"
log "Previous commit: $CURRENT_SHA"
log "Changes deployed:"
git log --oneline --no-decorate $CURRENT_SHA..$NEW_SHA | sed 's/^/  /'
log ""
log "Service status:"
systemctl status clarity-app --no-pager -l | head -3
log ""
log "Application accessible at:"
log "  - https://andub.go.ro"
log "  - https://andub.go.ro/pb"
log ""
log "Deployment log: $DEPLOY_LOG"

exit 0