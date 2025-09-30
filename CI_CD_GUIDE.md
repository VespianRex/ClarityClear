# BestClear CI/CD Pipeline - Complete Guide

## Overview

Your website now has **automatic deployment** - push to GitHub and your live site updates within 5 minutes!

### How It Works

```
1. You push code to GitHub
   ↓
2. GitHub Actions runs tests (cloud)
   ↓
3. If tests pass ✅
   ↓
4. Server checks for updates every 5 minutes (cron)
   ↓
5. Server pulls latest code
   ↓
6. Auto-build, restart, health check
   ↓
7. Live site updated! 🎉
   (or auto-rollback if fails ❌)
```

---

## What's Automated

### ✅ Testing (GitHub Actions)

**Runs on every push/PR**:
- TypeScript compilation check
- ESLint code quality
- Prettier format validation
- Jest unit tests with coverage
- Next.js build validation
- Playwright E2E tests (master branch only)

**Where**: GitHub cloud runners (fast, free)
**Time**: ~3-5 minutes
**Result**: Pull request status checks

### ✅ Deployment (Server-Side)

**Runs every 5 minutes via cron**:
- Check for new commits
- Pull latest code
- Smart change detection:
  - `package.json` changed? → `npm ci`
  - `src/` changed? → `npm run build`
  - `pb_migrations/` changed? → Copy migrations
- Restart services
- Health check validation
- Auto-rollback on failure

**Where**: App VM (192.168.0.180)
**Time**: ~2-5 minutes depending on changes
**Logs**: `/var/log/clarity-deploy/`

---

## Deployment Script Intelligence

### Smart Change Detection

The deployment script analyzes Git changes and runs only what's needed:

**Scenario 1: Content update (blog post, copy changes)**
```bash
# Changed: src/app/blog/post.tsx
$ git diff --name-only
src/app/blog/post.tsx

# Script runs:
✓ Git pull
✓ npm run build (rebuild needed)
✗ npm install (skipped - deps unchanged)
✓ Restart service
```

**Scenario 2: Dependency update**
```bash
# Changed: package.json
$ git diff --name-only
package.json
package-lock.json

# Script runs:
✓ Git pull
✓ npm ci (clean install)
✓ npm run build (always after install)
✓ Restart service
```

**Scenario 3: Database migration**
```bash
# Changed: pb_migrations/new_migration.js
$ git diff --name-only
pb_migrations/1727711234_add_field.js

# Script runs:
✓ Git pull
✓ Copy migrations to ../pb_migrations/
✓ Restart PocketBase (auto-migrates)
✓ Restart Next.js
✗ No rebuild needed (unless src/ also changed)
```

**Scenario 4: Config only**
```bash
# Changed: README.md, .github/workflows/
$ git diff --name-only
README.md
.github/workflows/ci.yml

# Script runs:
✓ Git pull
✗ npm install (skipped)
✗ npm build (skipped)
✗ Restart (skipped - no app changes)
✓ "No deployment needed"
```

### Automatic Rollback

**If deployment fails**:
```bash
1. Build fails
   ↓
2. Git reset --hard <previous-commit>
   ↓
3. Restore previous build
   ↓
4. Restart with old version
   ↓
5. Your site stays online!
```

**Health check validates**:
- Service started successfully
- HTTP endpoint responding (200 OK)
- API health endpoint returns valid JSON
- PocketBase database accessible

**Rollback triggers**:
- Build failure
- npm install error
- Health check timeout (30s)
- Service won't start

---

## GitHub Actions Workflow Explained

### File: `.github/workflows/ci.yml`

**5 Jobs run in parallel** (where possible):

#### Job 1: Code Quality (`quality`)
```yaml
TypeScript → Lint → Format Check
```
- Fastest job (~1 minute)
- Catches syntax errors
- Enforces code standards

#### Job 2: Unit Tests (`test`)
```yaml
Jest tests + coverage
```
- Runs all `*.test.ts` files
- Uploads coverage to Codecov
- ~2-3 minutes

#### Job 3: Build Validation (`build`)
```yaml
npm run build → Verify .next/ exists
```
- Ensures production build works
- Uploads build artifact (optional)
- ~3-4 minutes

#### Job 4: E2E Tests (`e2e`)
```yaml
Playwright tests (master branch only)
```
- Only runs on main branch
- Slower (~5-10 minutes)
- Tests user flows (booking, gallery, etc.)
- Needs: quality + test + build to pass first

#### Job 5: Deploy Trigger (`deploy-trigger`)
```yaml
Runs if: master branch + all tests pass
```
- Just logs "deployment ready"
- Server's cron job handles actual deploy
- (Webhook option commented out for future)

### Workflow Triggers

**Runs on**:
```yaml
on:
  push:
    branches: [master, main, develop]
  pull_request:
    branches: [master, main]
```

**Behavior**:
- **Push to master**: Full test suite → Auto-deploy
- **Push to develop**: Full test suite → No deploy
- **Pull request**: Full test suite → No deploy
- **Push to feature branch**: Basic tests only

---

## Cron Job Configuration

### Schedule

```bash
*/5 * * * * cd /opt/clarity/app && ./deploy.sh
```

**Meaning**: Every 5 minutes, check for updates and deploy if found

**Why 5 minutes**:
- ✅ Fast enough (max 5 min delay)
- ✅ Not hammering GitHub API
- ✅ Gives time for tests to finish
- ✅ Low server load

**Alternative schedules**:
```bash
*/1 * * * *   # Every 1 minute (faster but more load)
*/10 * * * *  # Every 10 minutes (slower but lighter)
0 * * * *     # Every hour (for low-change sites)
```

### Log Files

**Deployment logs**:
```
/var/log/clarity-deploy/
├── deploy-20250930-153008.log
├── deploy-20250930-153508.log
├── deploy-20250930-154008.log
└── cron.log
```

**View latest deployment**:
```bash
ssh VespianRex@192.168.0.180 "tail -f /var/log/clarity-deploy/cron.log"
```

**View specific deployment**:
```bash
ssh VespianRex@192.168.0.180 "ls -lt /var/log/clarity-deploy/deploy-*.log | head -1 | xargs cat"
```

### Deployment History

**Tracked in**:
```
/opt/clarity/deployments.log
```

**Format**:
```
2025-09-30 15:30:00 UTC - Deployed abc1234 (from def5678)
  Branch: master
  Install: true
  Build: true
  Migration: false
  Status: SUCCESS
```

---

## How to Use

### Normal Development Flow

```bash
# 1. Make changes locally
vim src/app/page.tsx

# 2. Test locally
npm run dev

# 3. Run checks
npm run check-all

# 4. Commit and push
git add .
git commit -m "feat: update homepage"
git push origin master

# 5. Wait for GitHub Actions
# Check: https://github.com/VespianRex/BestClear/actions

# 6. If tests pass ✅
# Server auto-deploys within 5 minutes

# 7. Verify live site
# https://andub.go.ro
```

### Emergency Rollback

**If you need to rollback manually**:

```bash
# Find last good commit
git log --oneline -10

# SSH to server
ssh VespianRex@192.168.0.180

# Rollback
cd /opt/clarity/app
git reset --hard <LAST_GOOD_COMMIT>
npm run build
sudo systemctl restart clarity-app

# Verify
curl http://localhost:3000/api/health
```

### Force Deployment

**If cron isn't working or you need immediate deploy**:

```bash
ssh VespianRex@192.168.0.180 "cd /opt/clarity/app && ./deploy.sh"
```

### Skip CI (Emergency Only)

```bash
# Push without triggering full CI
git push origin master [ci skip]

# Or push to a non-master branch first
git push origin feature-branch
# Then merge via PR
```

---

## Monitoring Deployments

### Check Deployment Status

```bash
# View recent deployments
ssh VespianRex@192.168.0.180 "tail -20 /opt/clarity/deployments.log"

# Check if deployment is running now
ssh VespianRex@192.168.0.180 "ps aux | grep deploy.sh"

# View live deployment log
ssh VespianRex@192.168.0.180 "tail -f /var/log/clarity-deploy/cron.log"
```

### Deployment Metrics

**Track in Prometheus** (future enhancement):
```
deployment_total{status="success"}
deployment_total{status="failure"}
deployment_duration_seconds
deployment_last_timestamp
```

**View in Grafana**: https://andub.go.ro/metrics

---

## Failure Scenarios & Recovery

### Scenario 1: Build Failure

**What happens**:
```
1. Git pull succeeds
2. npm run build FAILS
3. Script detects failure
4. Git reset to previous commit
5. Restores previous build
6. Service stays on old version
```

**You see**:
```
[ERROR] Build failed
Initiating rollback...
Rolled back to abc1234
```

**Action required**: Fix build issue locally, push again

### Scenario 2: Health Check Failure

**What happens**:
```
1. Git pull → install → build: All succeed
2. Service restarts
3. Health check fails (service won't respond)
4. Script detects failure
5. Automatic rollback initiated
```

**You see**:
```
[ERROR] Health check failed after 30 seconds
Last 20 lines of service logs:
  [logs showing error]
Initiating rollback...
```

**Action required**: Check logs, fix issue

### Scenario 3: Database Migration Failure

**What happens**:
```
1. Migrations copied
2. PocketBase restarts
3. Migration fails (schema conflict)
4. PocketBase won't start
```

**Mitigation**:
- Always test migrations locally first
- Database is backed up before each deploy
- Can restore: `cp pb_data/data.db.backup-* pb_data/data.db`

**Prevention**:
```bash
# Before pushing migration:
# 1. Test locally
npm run pocketbase
# Apply migration in local PocketBase

# 2. Verify no errors

# 3. Then push to production
```

### Scenario 4: Dependency Conflict

**What happens**:
```
1. package.json updated with new dependency
2. npm ci fails (version conflict)
3. Deployment aborts before restart
4. Old version keeps running
```

**You see**:
```
[ERROR] npm install failed
Rollback initiated...
```

**Prevention**:
- Always test `npm ci` locally
- Check for peer dependency warnings
- Review package-lock.json changes

---

## Advanced Configuration

### Customize Deployment Behavior

**Edit** `/opt/clarity/app/deploy.sh` on server:

**Change health check timeout**:
```bash
HEALTH_CHECK_TIMEOUT=30  # Increase to 60 for slow builds
```

**Disable automatic rollback**:
```bash
ROLLBACK_ENABLED=false   # Manual recovery only
```

**Add custom validation**:
```bash
# After health check, add:
if ! npm run test:smoke; then
  error "Smoke tests failed"
  exit 1
fi
```

### Add Deployment Notifications

**Option 1: Slack/Discord**
```bash
# At end of deploy.sh:
if [ $? -eq 0 ]; then
  curl -X POST $SLACK_WEBHOOK \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"✅ Deployment successful: $NEW_SHA\"}"
else
  curl -X POST $SLACK_WEBHOOK \
    -H 'Content-Type: application/json' \
    -d "{\"text\":\"❌ Deployment failed: $NEW_SHA\"}"
fi
```

**Option 2: Email** (exim4 already installed):
```bash
echo "Deployment completed: $NEW_SHA" | mail -s "BestClear Deploy" admin@example.com
```

**Option 3: Prometheus Metrics**:
```bash
# Push to Prometheus Pushgateway
echo "deployment_success 1" | curl --data-binary @- \
  http://192.168.0.207:9091/metrics/job/deploy/instance/app
```

### Webhook for Instant Deployment

**Instead of waiting 5 minutes**, trigger immediately:

**1. Create webhook endpoint on edge VM**:
```bash
# Add to Traefik routes
deploy-webhook:
  rule: "Host(`andub.go.ro`) && Path(`/deploy`)"
  middlewares:
    - webhook-auth
  service: deploy-service
```

**2. Create webhook handler**:
```bash
# Simple Node.js webhook receiver
# Validates secret, triggers deploy.sh
```

**3. Configure GitHub webhook**:
```
Settings → Webhooks → Add webhook
URL: https://andub.go.ro/deploy
Secret: <random-secret>
Events: Push events
```

**4. Deployment is instant** (within seconds)

---

## CI/CD Best Practices Implemented

### ✅ 1. Tests Before Deploy

```
No deployment without passing tests
- TypeScript errors = Block
- Lint errors = Block
- Test failures = Block
- Build failures = Block
```

### ✅ 2. Immutable Deployments

```bash
# Uses package-lock.json
npm ci  # Not npm install
# Ensures same versions every time
```

### ✅ 3. Health Validation

```bash
# After restart:
curl http://localhost:3000/api/health
# Must return 200 OK with valid JSON
```

### ✅ 4. Automatic Rollback

```
Failure detected → Rollback → Service stays up
```

### ✅ 5. Deployment Logging

```
Every deployment logged with:
- Timestamp
- Commit SHA
- What changed
- Result (success/failure)
```

### ✅ 6. Backup Before Deploy

```
- Previous build backed up
- Database backed up
- Can restore if needed
```

### ✅ 7. Zero Manual Steps

```
Push → Automated testing → Automated deployment
No SSH needed, no manual builds
```

---

## Workflow Diagrams

### Testing Workflow

```
Developer pushes to GitHub
         ↓
    ┌────────────────────────────┐
    │   GitHub Actions Starts    │
    └────────────┬───────────────┘
                 ↓
    ┌────────────────────────────┐
    │  Job 1: Quality (parallel) │
    │  - TypeScript              │
    │  - Lint                    │
    │  - Format                  │
    └────────────┬───────────────┘
                 │
    ┌────────────────────────────┐
    │  Job 2: Test (parallel)    │
    │  - Unit tests              │
    │  - Coverage                │
    └────────────┬───────────────┘
                 │
    ┌────────────────────────────┐
    │  Job 3: Build (parallel)   │
    │  - npm run build           │
    │  - Validate output         │
    └────────────┬───────────────┘
                 │
         All jobs pass? ─────── NO → ❌ Block PR/deployment
                 │
                YES
                 ↓
    ┌────────────────────────────┐
    │  Job 4: E2E (master only)  │
    │  - Playwright tests        │
    └────────────┬───────────────┘
                 │
         Master branch? ────────  NO → Stop here
                 │
                YES
                 ↓
    ┌────────────────────────────┐
    │  Job 5: Deploy Trigger     │
    │  - Log "ready to deploy"   │
    └────────────────────────────┘
```

### Deployment Workflow

```
Cron runs every 5 minutes
         ↓
Check for new commits
         │
    No changes? ──── YES → Exit (no deployment)
         │
        NO
         ↓
Fetch latest commit
         ↓
Analyze what changed
         ↓
Create backup
         ↓
Git pull
         ↓
    ┌─────────────────────┐
    │  Dependencies       │
    │  changed?           │
    └──┬───────────────┬──┘
      YES             NO
       │               │
    npm ci          Skip
       │               │
       └───────┬───────┘
               ↓
    ┌─────────────────────┐
    │  Source changed?    │
    └──┬───────────────┬──┘
      YES             NO
       │               │
   npm build        Skip
       │               │
       └───────┬───────┘
               ↓
    Copy migrations (if any)
               ↓
    Restart services
               ↓
    Wait 5 seconds
               ↓
    ┌─────────────────────┐
    │  Health check       │
    └──┬───────────────┬──┘
    PASS            FAIL
      │               │
   SUCCESS      ROLLBACK
      │               │
      ↓               ↓
   Log it      Restore previous
               Restart service
                     ↓
                  Log failure
```

---

## Monitoring & Debugging

### Check Deployment Logs

```bash
# Latest deployment log
ssh VespianRex@192.168.0.180 "ls -t /var/log/clarity-deploy/deploy-*.log | head -1 | xargs cat"

# Cron execution log
ssh VespianRex@192.168.0.180 "tail -f /var/log/clarity-deploy/cron.log"

# Deployment history
ssh VespianRex@192.168.0.180 "cat /opt/clarity/deployments.log"
```

### Check Service Status

```bash
# After deployment, verify:
ssh VespianRex@192.168.0.180 << 'EOF'
systemctl status clarity-app --no-pager
echo "---"
journalctl -u clarity-app -n 20 --no-pager
echo "---"
curl http://localhost:3000/api/health
EOF
```

### Debug Failed Deployment

**Step 1: Find the error**
```bash
ssh VespianRex@192.168.0.180 "grep ERROR /var/log/clarity-deploy/deploy-*.log | tail -10"
```

**Step 2: Check what changed**
```bash
ssh VespianRex@192.168.0.180 "cd /opt/clarity/app && git log -1 --stat"
```

**Step 3: Try manual deployment**
```bash
ssh VespianRex@192.168.0.180
cd /opt/clarity/app
./deploy.sh
# Watch output for errors
```

**Step 4: Check service logs**
```bash
journalctl -u clarity-app -f
# Look for crashes, errors
```

---

## Upgrading the Pipeline

### Phase 2: Webhook-Based Deployment (Instant)

**Benefits**:
- Instant deployment (no 5-min wait)
- GitHub push → Live in ~2 minutes

**Steps**:
1. Create webhook receiver on edge VM
2. Add Traefik route with authentication
3. Configure GitHub webhook
4. Comment out cron (or keep as backup)

**Implementation**:
```bash
# infra/webhook-deploy.sh (on edge VM)
#!/bin/bash
# Validate webhook secret
# SSH to app VM and run deploy.sh
```

### Phase 3: Blue-Green Deployment

**Zero-downtime deploys**:

```bash
# Current: Port 3000
# Deploy to: Port 3001

1. Build new version on port 3001
2. Health check port 3001
3. Update Traefik to route to 3001
4. Stop old process on 3000
5. Zero user-facing downtime
```

### Phase 4: Staging Environment

**Add staging VM**:
```
develop branch → Auto-deploy to staging
master branch → Auto-deploy to production

Staging URL: https://andub.go.ro/staging
Production URL: https://andub.go.ro
```

### Phase 5: Deployment Gates

**Manual approval for production**:
```yaml
# GitHub Actions
deploy-prod:
  needs: [quality, test, build]
  environment:
    name: production
    url: https://andub.go.ro
  # Requires manual approval in GitHub UI
```

---

## Testing Your CI/CD

### Test 1: Simple Content Change

```bash
# Make a small change
echo "// Test CI/CD" >> src/app/page.tsx

# Commit and push
git add src/app/page.tsx
git commit -m "test: CI/CD pipeline"
git push origin master

# Watch GitHub Actions
open https://github.com/VespianRex/BestClear/actions

# Wait up to 5 minutes

# Check deployment log
ssh VespianRex@192.168.0.180 "tail -f /var/log/clarity-deploy/cron.log"

# Verify live site updated
curl https://andub.go.ro
```

### Test 2: Dependency Update

```bash
# Update a package
npm install lucide-react@latest

# Commit changes
git add package.json package-lock.json
git commit -m "chore: update lucide-react"
git push

# Deployment should:
# - Run npm ci
# - Rebuild
# - Restart
# - Take ~5 minutes total
```

### Test 3: Intentional Failure

```bash
# Break the build
echo "syntax error here {{{}}" >> src/app/page.tsx

# Push
git add .
git commit -m "test: deployment rollback"
git push

# GitHub Actions should FAIL
# Deployment should NOT happen
# Live site should stay on old version
```

### Test 4: Rollback Test

**Manually trigger rollback**:
```bash
ssh VespianRex@192.168.0.180 << 'EOF'
cd /opt/clarity/app

# Simulate failure
export ROLLBACK_ENABLED=true
export HEALTH_CHECK_URL="http://localhost:9999/nonexistent"

./deploy.sh
# Should rollback automatically
EOF
```

---

## Performance Optimization

### Build Caching

**Current**: Builds from scratch each time

**Optimization**: Cache node_modules
```bash
# In deploy.sh, change:
npm ci

# To:
if [ -f "package-lock.json.last" ] && diff package-lock.json package-lock.json.last > /dev/null; then
  echo "Dependencies unchanged, skipping install"
else
  npm ci
  cp package-lock.json package-lock.json.last
fi
```

**Result**: Faster deployments when deps unchanged

### Parallel Builds

**Current**: Sequential (pull → install → build → restart)

**Optimization**: Parallel testing
```bash
# While pulling:
# - Pre-warm cache in background
# - Run health checks
# - Prepare backup
```

### Build Artifact Reuse

**Alternative approach**:
```
1. GitHub Actions builds .next/ directory
2. Upload as artifact
3. Server downloads artifact instead of building
4. Faster (no build on server)
```

**Trade-off**:
- ✅ Faster deployment
- ❌ Larger artifacts
- ❌ More complex
- ❌ Requires artifact download auth

---

## Security Considerations

### Cron Job Security

**Current**:
- Runs as VespianRex user (not root)
- Uses sudo only for systemctl restart
- Git pull doesn't need privileges

**Hardening**:
```bash
# Limit sudo permissions
# /etc/sudoers.d/clarity-deploy
VespianRex ALL=(ALL) NOPASSWD: /bin/systemctl restart clarity-app
VespianRex ALL=(ALL) NOPASSWD: /bin/systemctl restart pocketbase
# No other sudo commands allowed
```

### GitHub Actions Secrets

**If adding webhook deployment**, store securely:

```
GitHub repo → Settings → Secrets → Actions
Add:
- DEPLOY_SECRET: <random-secret-key>
- SSH_PRIVATE_KEY: <server-ssh-key> (if needed)
```

**Never commit**:
- SSH keys
- Webhook secrets
- API tokens
- Passwords

### Deployment Authentication

**Current**: Server-initiated pull (no inbound auth needed)

**If adding webhook**:
```yaml
# Traefik middleware
webhook-auth:
  headers:
    customRequestHeaders:
      X-Deploy-Secret: "validate-this"
```

---

## Troubleshooting Guide

### Deployment Not Running

**Check cron is active**:
```bash
ssh VespianRex@192.168.0.180 "systemctl status cron"
```

**Check cron logs**:
```bash
ssh VespianRex@192.168.0.180 "grep CRON /var/log/syslog | tail -20"
```

**Verify crontab**:
```bash
ssh VespianRex@192.168.0.180 "crontab -l"
```

### GitHub Actions Failing

**Check workflow syntax**:
```bash
# Local validation (requires act)
act -l
```

**View GitHub logs**:
```
https://github.com/VespianRex/BestClear/actions
```

**Common issues**:
- Node version mismatch
- Missing dependencies
- Test timeout
- Flaky E2E tests

### Deployment Stuck

**Kill stuck deployment**:
```bash
ssh VespianRex@192.168.0.180 "pkill -f deploy.sh"
```

**Clear lock files**:
```bash
ssh VespianRex@192.168.0.180 "rm -f /opt/clarity/app/.git/index.lock"
```

---

## Metrics & Analytics

### Track Deployment Success Rate

**Add to deploy.sh**:
```bash
# Count total deployments
TOTAL=$(wc -l < /opt/clarity/deployments.log)

# Count successful
SUCCESS=$(grep "SUCCESS" /opt/clarity/deployments.log | wc -l)

# Calculate rate
RATE=$((SUCCESS * 100 / TOTAL))

echo "Deployment success rate: $RATE%"
```

### Average Deployment Time

```bash
# Parse logs to calculate
grep "Deployment Started" deploy-*.log
grep "Deployment Successful" deploy-*.log
# Calculate difference
```

### Most Common Failures

```bash
grep "ERROR" deploy-*.log | cut -d: -f3 | sort | uniq -c | sort -rn
```

---

## Future Enhancements

### Short Term (Next Month)

1. **Slack notifications** on deploy success/failure
2. **Deployment metrics** in Prometheus
3. **Staging environment** for develop branch
4. **Smoke tests** after deployment

### Medium Term (Next Quarter)

1. **Webhook-based deployment** (instant)
2. **Blue-green deployment** (zero downtime)
3. **Canary releases** (gradual rollout)
4. **A/B testing** integration

### Long Term (Next Year)

1. **GitOps with ArgoCD** (if migrating to K8s)
2. **Multi-region deployment**
3. **Feature flags** (progressive delivery)
4. **Automated performance testing**

---

## Quick Reference

### Common Commands

```bash
# View deployment status
ssh VespianRex@192.168.0.180 "tail /opt/clarity/deployments.log"

# Trigger manual deployment
ssh VespianRex@192.168.0.180 "cd /opt/clarity/app && ./deploy.sh"

# View live deployment
ssh VespianRex@192.168.0.180 "tail -f /var/log/clarity-deploy/cron.log"

# Check cron schedule
ssh VespianRex@192.168.0.180 "crontab -l"

# Disable auto-deployment
ssh VespianRex@192.168.0.180 "crontab -r"

# Re-enable auto-deployment
ssh VespianRex@192.168.0.180 'echo "*/5 * * * * cd /opt/clarity/app && ./deploy.sh >> /var/log/clarity-deploy/cron.log 2>&1" | crontab -'
```

### Useful One-Liners

```bash
# See what will be deployed next
ssh VespianRex@192.168.0.180 "cd /opt/clarity/app && git fetch && git log HEAD..origin/master --oneline"

# Check last deployment time
ssh VespianRex@192.168.0.180 "ls -lt /var/log/clarity-deploy/deploy-*.log | head -1"

# Count deployments today
ssh VespianRex@192.168.0.180 "grep '$(date +%Y-%m-%d)' /opt/clarity/deployments.log | wc -l"

# View deployment errors only
ssh VespianRex@192.168.0.180 "grep -h ERROR /var/log/clarity-deploy/deploy-*.log"
```

---

## Summary

### What You Have Now

✅ **Automated testing** on every push (GitHub Actions)
✅ **Automated deployment** every 5 minutes (cron)
✅ **Smart change detection** (only rebuild what's needed)
✅ **Health validation** (ensure deployment works)
✅ **Automatic rollback** (if deployment fails)
✅ **Deployment logging** (full audit trail)
✅ **Backup strategy** (before each deploy)

### How to Deploy

**Just push to GitHub**:
```bash
git push origin master
```

**That's it!** Tests run, deployment happens, site updates automatically.

### Deployment SLA

**From push to live**:
- Testing: 3-5 minutes (GitHub Actions)
- Deployment window: 0-5 minutes (cron interval)
- Deployment execution: 2-5 minutes (depending on changes)

**Total**: 5-15 minutes from push to live

**For urgent deploys**:
```bash
# Manual trigger (immediate)
ssh VespianRex@192.168.0.180 "cd /opt/clarity/app && ./deploy.sh"
# Live in ~2-5 minutes
```

---

**Document Version**: 1.0
**Last Updated**: September 30, 2025
**Status**: CI/CD Active and Operational