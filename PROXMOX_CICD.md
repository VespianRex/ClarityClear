# Proxmox-Enhanced CI/CD Pipeline

## Overview

Your CI/CD now has **VM-level snapshots** - Proxmox automatically snapshots the entire VM before each deployment!

## Architecture

### Three-Layer Backup Strategy

```
Layer 1: Proxmox VM Snapshot (Hypervisor level)
  ├─ Entire VM state saved
  ├─ Disk, memory, config
  ├─ Instant rollback to exact state
  └─ Created BEFORE deployment starts

Layer 2: File-Level Backups (Application level)
  ├─ .next/ build directory
  ├─ pb_data/data.db (database)
  └─ Fast in-process rollback

Layer 3: Git History (Code level)
  ├─ git reset --hard <commit>
  └─ Restore to any previous version
```

---

## How It Works

### Deployment Flow with Proxmox Snapshots

```
1. Cron triggers deployment
   ↓
2. deploy.sh runs on App VM (192.168.0.180)
   ↓
3. SSH to Proxmox (192.168.0.33)
   ↓
4. Proxmox creates VM snapshot
   ↓
5. VM continues deployment
   ├─ Git pull
   ├─ Build
   ├─ Restart
   └─ Health check
   ↓
6. If success ✅
   └─ Snapshot kept for 10 deployments
   ↓
7. If catastrophic failure ❌
   └─ Can restore entire VM from snapshot
```

### Snapshot Naming Convention

```
auto-deploy-1759246999
      ↑         ↑
   prefix   unix timestamp

Description: "Pre-deploy: abc1234 from def5678"
```

---

## Rollback Strategies

### Level 1: Code Rollback (Automatic)

**When**: Build fails, health check fails
**How**: deploy.sh automatically runs
```bash
git reset --hard <previous-commit>
npm run build
systemctl restart
```
**Time**: ~2 minutes
**Scope**: Application code only

### Level 2: File Restore (Manual)

**When**: Database corruption, missing files
**How**: Restore from file backups
```bash
# Restore database
cp /opt/clarity/pb_data/data.db.backup-* /opt/clarity/pb_data/data.db

# Restore build
cp -r /opt/clarity/backups/deploy-*/. next/ /opt/clarity/app/.next/
```
**Time**: ~1 minute
**Scope**: Specific files

### Level 3: VM Snapshot Rollback (Emergency)

**When**: Complete system failure, filesystem corruption, catastrophic error
**How**: Restore entire VM from Proxmox snapshot
```bash
./infra/emergency-rollback.sh
```
**Time**: ~5 minutes (VM stop, restore, start)
**Scope**: Entire VM state

---

## Proxmox Integration Commands

### On Proxmox Host (192.168.0.33)

**Create snapshot**:
```bash
/usr/local/bin/proxmox-snapshot.sh create "Description here"
```

**List snapshots**:
```bash
/usr/local/bin/proxmox-snapshot.sh list
```

**Get latest snapshot**:
```bash
/usr/local/bin/proxmox-snapshot.sh latest
```

**Cleanup old snapshots** (keep last 10):
```bash
/usr/local/bin/proxmox-snapshot.sh cleanup
```

**Rollback to latest**:
```bash
/usr/local/bin/proxmox-snapshot.sh rollback
```

**Rollback to specific snapshot**:
```bash
/usr/local/bin/proxmox-snapshot.sh rollback auto-deploy-1759246999
```

### From Your Local Machine

**Emergency rollback** (interactive):
```bash
./infra/emergency-rollback.sh
# Prompts for confirmation
# Shows available snapshots
# Executes rollback
```

**Quick rollback** (if you're sure):
```bash
ssh root@192.168.0.33 "/usr/local/bin/proxmox-snapshot.sh rollback" << EOF
yes
EOF
```

---

## Snapshot Storage & Performance

### Storage Impact

**Each snapshot size**:
```bash
# Initial snapshot: ~2-5 GB (full VM disk)
# Subsequent snapshots: Only changed blocks (delta)

# Example:
Snapshot 1: 4.2 GB (full)
Snapshot 2: 156 MB (only changed files since snapshot 1)
Snapshot 3: 89 MB (only changed files since snapshot 2)
```

**10 snapshots**: Approximately 5-8 GB total

**Cleanup policy**: Automatic (keeps last 10)

### Performance Impact

**Snapshot creation**:
- Time: ~2-5 seconds
- I/O impact: Minimal (LVM CoW)
- VM impact: No downtime

**Snapshot rollback**:
- Time: ~3-5 minutes (stop VM + restore + start)
- I/O impact: Moderate
- VM impact: Full service interruption

---

## When to Use Each Rollback Type

### Use Code Rollback When:
- ✅ Build failed
- ✅ Tests failed after deployment
- ✅ Application won't start
- ✅ Health check timeout
- ✅ Bad commit deployed

**Impact**: Minimal (services might restart)
**Recovery**: Automatic

### Use File Restore When:
- ✅ Database file corrupted
- ✅ Specific file missing
- ✅ Build cache issues
- ✅ Config file problems

**Impact**: Low (services restart)
**Recovery**: Manual but fast

### Use VM Snapshot Rollback When:
- 🔴 Filesystem corruption
- 🔴 Multiple services broken
- 🔴 System packages broken
- 🔴 Unknown catastrophic failure
- 🔴 Recovery via code/file fails

**Impact**: High (full VM stop/start)
**Recovery**: Manual, takes ~5 minutes

---

## Automatic Snapshot Management

### Snapshot Lifecycle

```
Deployment triggered
   ↓
New snapshot created
   ↓
Deployment succeeds ✅
   ↓
Snapshot kept
   ↓
After 10 more deployments
   ↓
Oldest snapshot deleted
```

### Retention Policy

**Keeps**:
- Last 10 deployment snapshots
- ~5-8 GB storage
- ~1-2 weeks of history (at 2 deploys/day)

**Why 10**:
- ✅ Enough rollback points
- ✅ Reasonable storage use
- ✅ Fast snapshot list
- ✅ Can rollback to any of last 10 deploys

**Adjust** (in `/usr/local/bin/proxmox-snapshot.sh`):
```bash
MAX_SNAPSHOTS=10  # Change to 5, 20, etc.
```

---

## Security Benefits

### VM Snapshots for Security

**Protection against**:
- Malicious code deployment
- Compromised dependencies
- Filesystem attacks
- Ransomware (if deployed code is infected)

**Recovery**:
```
Malicious deployment detected
   ↓
Rollback to pre-attack snapshot
   ↓
VM restored to clean state
   ↓
Investigate attack in isolated environment
```

### Audit Trail

**Every snapshot tagged with**:
- Timestamp
- Git commit SHA (what was deployed)
- Previous commit SHA (what it replaced)

**Forensics**:
```bash
# What was deployed when?
qm listsnapshot 203 | grep auto-deploy

# Restore to specific time
qm rollback 203 auto-deploy-<timestamp>
```

---

## Disaster Recovery Scenarios

### Scenario 1: Deployment Corrupted Filesystem

**Problem**:
```
Deployment script bug → rm -rf wrong directory
Filesystem partially deleted
Services won't start
```

**Solution**:
```bash
# Emergency rollback
./infra/emergency-rollback.sh

# VM restored to pre-deployment state
# All files intact
# Services working
```

**Time to recovery**: 5 minutes

### Scenario 2: Bad Migration Broke Database

**Problem**:
```
Database migration applied
Migration has bug
Database now corrupted
PocketBase won't start
```

**Solution Option 1** (File-level):
```bash
ssh VespianRex@192.168.0.180
cp /opt/clarity/pb_data/data.db.backup-* /opt/clarity/pb_data/data.db
systemctl restart pocketbase
```

**Solution Option 2** (VM-level):
```bash
./infra/emergency-rollback.sh
# Entire VM (including database) restored
```

### Scenario 3: Multiple Services Broken

**Problem**:
```
Deployment deployed bad systemd configs
Both clarity-app and pocketbase broken
Can't easily identify what's wrong
```

**Solution**:
```bash
# VM snapshot rollback is fastest
./infra/emergency-rollback.sh

# Everything restored to working state
# Can investigate issue from logs
```

---

## Monitoring Snapshots

### Check Snapshot Status

```bash
# From Proxmox host
ssh root@192.168.0.33 "qm listsnapshot 203"

# Via web UI
https://192.168.0.33:8006
→ VM 203
→ Snapshots tab
```

### Snapshot Disk Usage

```bash
# Check LVM usage
ssh root@192.168.0.33 "lvs | grep snap_vm-203"

# Total snapshot size
ssh root@192.168.0.33 "du -sh /dev/pve/snap_vm-203-*"
```

### Alerts (Future Enhancement)

**Add to Prometheus**:
```yaml
# Alert if too many snapshots
- alert: TooManySnapshots
  expr: proxmox_vm_snapshots{vmid="203"} > 15
  annotations:
    summary: "VM 203 has too many snapshots"

# Alert if snapshot fails
- alert: SnapshotCreationFailed
  expr: increase(deployment_snapshot_failures[1h]) > 0
```

---

## Best Practices

### DO:
- ✅ Let automatic snapshots happen (hands-off)
- ✅ Keep 10 snapshots (default is good)
- ✅ Use VM rollback only for emergencies
- ✅ Test rollback procedure occasionally
- ✅ Monitor snapshot storage usage

### DON'T:
- ❌ Create manual snapshots with same prefix
- ❌ Disable automatic cleanup (disk will fill)
- ❌ Use VM rollback for minor issues (use code rollback)
- ❌ Delete snapshots manually (use cleanup script)
- ❌ Snapshot during active deployment

---

## Advanced: Blue-Green with Snapshots

**Future enhancement**:

```bash
# Instead of rolling back, clone VM from snapshot
qm clone 203 204 --snapname auto-deploy-<good>

# New VM 204 has the good version
# Update Traefik to point to VM 204
# Test thoroughly
# Delete old VM 203
```

**Benefits**:
- Zero downtime rollback
- Can compare old vs new
- Safe testing before committing

---

## Snapshot vs Backup

### Snapshots (What We Use)

**Purpose**: Short-term recovery points
**Speed**: Instant create, ~5 min restore
**Storage**: On same storage as VM (local-lvm)
**Retention**: Last 10 deployments
**Use for**: Deployment rollbacks, quick recovery

### Backups (PBS)

**Purpose**: Long-term disaster recovery
**Speed**: Slower create (full copy), ~30 min restore
**Storage**: Separate backup server (VM 205)
**Retention**: Daily/weekly/monthly
**Use for**: Hardware failure, ransomware, data loss

**Both are needed**:
- Snapshots = Fast rollback (deployment issues)
- Backups = Full recovery (hardware failure)

---

## Quick Reference

### Daily Operations

**Check snapshots**:
```bash
ssh root@192.168.0.33 "/usr/local/bin/proxmox-snapshot.sh list"
```

**Manual snapshot** (before risky change):
```bash
ssh root@192.168.0.33 "/usr/local/bin/proxmox-snapshot.sh create 'Before manual config change'"
```

**Emergency rollback**:
```bash
./infra/emergency-rollback.sh
```

### Deployment Logs

**Check if snapshot was created**:
```bash
ssh VespianRex@192.168.0.180 "grep 'Proxmox VM snapshot' /var/log/clarity-deploy/deploy-*.log | tail -5"
```

**Verify snapshots exist**:
```bash
ssh root@192.168.0.33 "qm listsnapshot 203 | grep auto-deploy | wc -l"
# Should show number of snapshots (0-10)
```

---

## Troubleshooting

### Snapshot Creation Fails

**Check**:
```bash
# Enough storage?
ssh root@192.168.0.33 "lvs"

# VM is running?
ssh root@192.168.0.33 "qm status 203"

# Permissions?
ssh root@192.168.0.33 "ls -la /usr/local/bin/proxmox-snapshot.sh"
```

**If snapshots fail**:
- Deployment continues (graceful degradation)
- File-level backups still created
- Warning logged

### Can't SSH to Proxmox from VM

**Check**:
```bash
ssh VespianRex@192.168.0.180 "ssh -i ~/.ssh/id_proxmox root@192.168.0.33 hostname"
```

**Fix**:
```bash
# Re-add SSH key
ssh root@192.168.0.33 "cat >> ~/.ssh/authorized_keys" << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLIrsLCrFWUROU2zH88HYkfgUtZ8Ij1snI3/zAtVtLW app-vm-to-proxmox
EOF
```

---

## Summary

### What You Now Have

**Before each deployment**:
1. ✅ Full VM snapshot created
2. ✅ File-level backups created
3. ✅ Git state recorded

**During deployment**:
1. ✅ Smart change detection
2. ✅ Build on your server (private)
3. ✅ Health validation

**If deployment fails**:
1. ✅ Automatic code rollback (seconds)
2. ✅ Or file restore (1 minute)
3. ✅ Or VM snapshot restore (5 minutes)

**Your deployment is now bulletproof!** 🛡️

### Files Created

```
infra/proxmox-snapshot.sh       - Snapshot management (on Proxmox)
infra/emergency-rollback.sh     - VM rollback tool (run locally)
deploy.sh                       - Enhanced with Proxmox integration
PROXMOX_CICD.md                - This guide
```

### Quick Commands

```bash
# View snapshots
ssh root@192.168.0.33 "/usr/local/bin/proxmox-snapshot.sh list"

# Emergency rollback
./infra/emergency-rollback.sh

# Check deployment logs
ssh VespianRex@192.168.0.180 "tail -f /var/log/clarity-deploy/cron.log"
```

**Now commit and push - your enhanced CI/CD will activate!** 🚀