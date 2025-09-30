# Build Security: On-Premise vs Cloud

## Your Choice: Server-Side Building

### What This Means

**GitHub Actions (Cloud)**: Only runs tests
- ✅ TypeScript checks
- ✅ Lint validation
- ✅ Unit tests
- ❌ NO `npm run build`
- ❌ NO artifact creation
- ❌ NO build directory upload

**Your Server**: Does ALL building
- ✅ `npm ci` (install dependencies)
- ✅ `npm run build` (create production build)
- ✅ Build stays on your infrastructure
- ✅ `.next/` directory never leaves your server

---

## Security Comparison

### Cloud Build Approach (What We're NOT Doing)

```yaml
# GitHub Actions would:
- uses: actions/checkout@v4        # Downloads your code
- run: npm ci                      # Downloads dependencies
- run: npm run build               # Builds on GitHub's servers
- uses: actions/upload-artifact@v4 # Stores build
```

**Security concerns**:
- ❌ Source code on GitHub's build servers
- ❌ Build artifacts stored in GitHub
- ❌ Environment variables visible in logs
- ❌ Dependencies downloaded by GitHub
- ❌ Build cache on GitHub infrastructure
- ❌ Potential exposure of:
  - API keys (if accidentally committed)
  - Business logic
  - Proprietary algorithms
  - Database schemas

### Server Build Approach (What We ARE Doing)

```bash
# On your server:
cd /opt/clarity/app
git pull                  # Only pulls code
npm ci                    # Installs locally
npm run build             # Builds locally
```

**Security benefits**:
- ✅ Code never leaves your network
- ✅ Build process entirely private
- ✅ Environment variables stay local
- ✅ Dependencies downloaded by your server
- ✅ Build artifacts on your disk only
- ✅ Full control over build environment

---

## What GitHub Actions Sees

### With Server-Side Building (Current)

**GitHub can access**:
- ✅ Source code (it's in the repo anyway)
- ✅ Test files
- ✅ Package.json (dependency list)
- ❌ NOT: Build output
- ❌ NOT: Environment variables
- ❌ NOT: Compiled assets
- ❌ NOT: Production configurations

**GitHub Actions logs show**:
```
✓ TypeScript compilation check
✓ Lint passed
✓ 42 unit tests passed
✅ All checks passed
```

**GitHub Actions NEVER sees**:
- Your production .env file
- Built JavaScript bundles
- Optimized images
- Server-side code after build
- Database connection strings
- API endpoints implementation

### With Cloud Building (Alternative We Rejected)

**GitHub would see**:
- Source code
- Test files
- Dependencies installed
- **Build output** (.next/ directory)
- **Compiled bundles**
- **All optimizations**
- **Environment variable names** (from build logs)

---

## Attack Surface Analysis

### Cloud Build Attack Vectors

**Potential risks**:

1. **Compromised GitHub Actions runner**:
   - Attacker gains access to GitHub's build infrastructure
   - Could exfiltrate your build artifacts
   - Could inject malicious code during build

2. **Artifact exposure**:
   - Build artifacts stored on GitHub
   - Accessible to GitHub employees
   - Could be subpoenaed
   - Retention period = data exposure window

3. **Dependency confusion attack**:
   - npm install runs on GitHub
   - Attacker could poison npm cache
   - Malicious dependency could be injected

4. **Log exposure**:
   - Build logs are public (for public repos)
   - Could leak API endpoints, structure, logic
   - Even private repo logs accessible to GitHub

### Server Build Security

**Your setup**:

1. **Isolated build environment**:
   - Builds on your VM
   - Controlled network access
   - Your firewall rules apply

2. **No artifact exposure**:
   - .next/ directory never uploaded anywhere
   - Only exists on your server
   - Deleted on next deployment

3. **Dependency verification**:
   - npm packages downloaded to your server
   - Can run malware scanning
   - Can use private npm registry if needed

4. **Private logs**:
   - Build logs in `/var/log/clarity-deploy/`
   - Only accessible via SSH
   - Never public

---

## Performance Comparison

### Cloud Build (GitHub Actions)

**Pros**:
- Free (2,000 minutes/month for private repos)
- Fast runners (2-core, 7GB RAM)
- Parallel jobs
- Pre-cached node_modules

**Cons**:
- Network latency (download/upload artifacts)
- Limited to 6 hours max
- Shared infrastructure (variable performance)

**Build time**: ~3-5 minutes

### Server Build (Your VM)

**Pros**:
- Your hardware (4 CPU, 8GB RAM)
- Local disk (fast I/O)
- No network transfer
- Can cache aggressively
- No time limits

**Cons**:
- Uses your server resources
- No parallel builds (unless you set up)
- You manage the infrastructure

**Build time**: ~2-4 minutes (faster on your hardware)

---

## What Gets Tested Where

### GitHub Actions Tests (Cloud)

```bash
✓ npm run typecheck    # TypeScript compilation
✓ npm run lint:strict  # Code quality
✓ npm run format:check # Code style
✓ npm run test:ci      # Unit tests (Jest)
✓ npm run test:e2e     # E2E tests (Playwright)
```

**Why these are safe in cloud**:
- No secrets needed
- No production data
- No environment variables required
- Just code quality validation

### Server-Side Operations (Private)

```bash
✓ npm ci               # Install production deps
✓ npm run build        # Build optimized bundles
✓ systemctl restart    # Deploy to production
✓ Health validation    # Verify it works
```

**Why these must be private**:
- Uses production environment variables
- Creates production-ready artifacts
- May contain sensitive configurations
- Direct access to production services

---

## Environment Variable Security

### Safe Pattern (What We Use)

**GitHub Actions** (public):
```yaml
# No environment variables in CI
# Tests use mock data
env:
  NODE_ENV: test  # Safe
```

**Server** (private):
```bash
# .env file on server only
NODE_ENV=production
NEXT_PUBLIC_POCKETBASE_URL=http://localhost:8090
DATABASE_URL=file:/opt/clarity/pb_data/data.db
SECRET_KEY=<actual-secret>
```

**Build uses server .env**:
- Environment variables only on your server
- Never in GitHub
- Never in logs
- Never in artifacts

### Unsafe Pattern (What We Avoid)

```yaml
# GitHub Actions
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}  # ❌ Bad!
  API_KEY: ${{ secrets.API_KEY }}            # ❌ Bad!

steps:
  - run: npm run build
    # Build now contains your secrets!
    # Logs might leak them!
```

---

## Supply Chain Security

### Dependency Management

**Your setup**:
```bash
# Server downloads dependencies
npm ci

# You can:
1. Run malware scans
2. Use private npm registry
3. Audit packages before install
4. Lock to specific versions
```

**Additional hardening** (optional):
```bash
# Before npm ci
npm audit --audit-level=high

# Or use Socket.dev/Snyk
npx socket-npm ci
```

### Build Reproducibility

**Ensures same build every time**:
```bash
# package-lock.json locks versions
npm ci  # Not npm install

# Node version locked
node --version  # v20.19.5

# Same build environment every time
```

**Verify builds match**:
```bash
# Build locally
npm run build
sha256sum .next/static/chunks/*.js

# Build on server
# Should produce SAME hashes
```

---

## Compliance & Audit

### Build Audit Trail

**Every build logged**:
```
/var/log/clarity-deploy/deploy-20250930-153008.log:
  [2025-09-30 15:30:05] Installing dependencies...
  [2025-09-30 15:30:15] Building application...
  [2025-09-30 15:30:45] ✓ Build completed
```

**Deployment history**:
```
/opt/clarity/deployments.log:
  2025-09-30 15:30:54 - Deployed abc1234
    Build: true
    Status: SUCCESS
```

**Who can access**:
- You (SSH access)
- Nobody else

### GDPR/Privacy Compliance

**With server builds**:
- ✅ Data stays in EU (your server location)
- ✅ No third-party processing
- ✅ Full data sovereignty
- ✅ Audit trail under your control

**With cloud builds**:
- ❌ Data processed in GitHub data centers (US)
- ❌ Subject to US laws (CLOUD Act)
- ❌ GitHub's data retention policies apply
- ❌ Less control over data

---

## Future: Even More Security

### 1. Signed Commits

**Verify code authenticity**:
```bash
# Setup GPG
gpg --gen-key

# Configure Git
git config --global user.signingkey <KEY>
git config --global commit.gpgsign true

# All commits now signed
# Server can verify: git verify-commit HEAD
```

### 2. Build Integrity Checks

**Ensure build wasn't tampered with**:
```bash
# After build, create checksum
sha256sum .next/**/*.js > build.sha256

# On next deploy, verify
sha256sum -c build.sha256
```

### 3. Dependency Pinning

**Lock ALL transitive dependencies**:
```bash
# Current: package-lock.json (good)

# Even stricter:
npm shrinkwrap
# Creates npm-shrinkwrap.json (overrides package-lock)
```

### 4. Private npm Registry

**For maximum control**:
```bash
# Run Verdaccio (npm registry proxy)
# All packages cached locally
# Scan before allowing
# Block malicious packages
```

---

## Comparison Table

| Feature | Cloud Build | Server Build |
|---------|-------------|--------------|
| **Build Speed** | 3-5 min | 2-4 min ✅ |
| **Source Privacy** | Code on GitHub | Code stays private ✅ |
| **Artifact Privacy** | Stored on GitHub | Never uploaded ✅ |
| **Environment Vars** | Exposed to GitHub | Private ✅ |
| **Build Control** | GitHub's env | Your env ✅ |
| **Cost** | Free tier limits | Your electricity |
| **Complexity** | Low | Medium |
| **Compliance** | US jurisdiction | Your jurisdiction ✅ |
| **Audit Trail** | GitHub logs | Your logs ✅ |
| **Network Transfer** | Upload artifacts | None ✅ |

---

## Summary

### Your Current CI/CD: Maximum Privacy

```
┌─────────────────────────────────────────────┐
│         GitHub Actions (Cloud)              │
│  - Runs tests only                         │
│  - No building                             │
│  - No artifacts                            │
│  - Your code stays private                 │
└─────────────────────┬───────────────────────┘
                      │
                      │ Tests pass ✅
                      ↓
┌─────────────────────────────────────────────┐
│         Your Server (Private)               │
│  - Pulls code                              │
│  - npm ci (installs deps)                  │
│  - npm run build (YOUR hardware)           │
│  - Deploys to production                   │
│  - Build artifacts NEVER leave server      │
└─────────────────────────────────────────────┘
```

**Result**:
- ✅ Automated deployment
- ✅ Full code privacy
- ✅ Build security
- ✅ Complete control

**This is the most secure CI/CD setup for self-hosted infrastructure!** 🔒