# BestClear Deployment Automation Plan

Generated September 24, 2025 after reviewing the working Alpine edge VM build pipeline and supporting scripts. Captures actionable phases to fully automate, validate, and harden the infra deployment flow.

## Phase 0 – Baseline Snapshot
- [x] Record current build artefacts: `/tmp/alpine-build.log`, `/tmp/alpine-rc-*.log`, `/tmp/alpine-network.log`, `/tmp/alpine-build-summary.txt`.
- [x] Confirm VM `9008` (alpine-ssh-final) status via `qm status 9008`, `qm agent 9008 network-get-interfaces`, and `ALPINE_IPS=... ./infra/scripts/test-alpine-connectivity.sh` (expect 192.168.0.220 reachable with SSH + guest agent running).
- [x] Capture Proxmox configuration (`qm config 9008`) to ensure `boot: order=scsi0`, virtio NIC, agent enabled.

## Phase 1 – Image Build Pipeline Reliability
1. [x] Re-run `./infra/build-alpine-image-corrected.sh --follow` (or set `FOLLOW=1`) to stream live progress and verify logging/states files are rotated.
2. [x] After completion, archive the resulting `/tmp/alpine-build.log` and summary files to `infra/logs/YYYYMMDD/` for traceability.
3. [x] Document any manual clean-up commands (e.g., removing old qcow2, resetting VM) so the script remains idempotent.
4. [x] Optional: convert the completed VM into a Proxmox template or cloud-init–ready base to accelerate additional edge nodes.

## Phase 2 – Post-Boot Validation Workflow
1. [x] Use `infra/scripts/test-alpine-connectivity.sh` (with `VM_IDS` or discovered IP) to assert:
   - Ping succeeds from Proxmox host and operator machine.
   - SSH login works for `VespianRex`, `rc-service sshd status`, `rc-service qemu-guest-agent status` report `started`.
2. [x] Pull guest diagnostics written during build (`/tmp/alpine-rc-status.log`, `/tmp/alpine-network.log`) and store alongside build logs.
3. [x] From the Proxmox host, confirm DHCP lease (`ip neigh`, `qm agent ... network-get-interfaces`) and capture MAC/IP mapping in inventory notes.

## Phase 3 – Ansible Edge Role Integration
1. [x] Update Ansible inventory to include the Alpine edge VM (currently 192.168.0.192) under the `edge` group, add shared variables, and disable host-key checking for automation.
2. [x] Run `ansible-playbook infra/ansible/playbooks/site.yml -l edge-primary --tags edge --check --diff` (executed via background `nohup`, log stored at `infra/logs/2025-09-24/ansible-edge-check.log`).
3. [ ] Execute the playbook for real (`ansible-playbook ... --tags edge`), or apply equivalent tasks manually, ensuring Docker, Traefik, Amnezia, iptables, keepalived, and fail2ban configure cleanly on Alpine. Current run blocked by NFS export permissions (`mount.nfs: access denied`); resolve NAS configuration before reattempt.
4. [x] Capture Ansible-related logs and connectivity outputs in `infra/logs/2025-09-24/` (check/apply logs, connectivity test).
5. [x] After configuration attempts rerun Phase 2 connectivity checks (`infra/scripts/test-alpine-connectivity.sh` against 192.168.0.192) to verify no regression.

## Phase 4 – Service-Level Validation
1. Confirm containers running: `docker ps` for Traefik/Amnezia; validate volumes/mounts on `/opt/edge-shared/*`.
2. Hit Traefik health endpoints (HTTP & HTTPS) from LAN; confirm certificates and routing.
3. Validate keepalived VRRP state (master/backup) on both edge nodes once both are present; log failover test results.
4. Run VPN smoke test on Amnezia port (`udp {{ vpn_port }}`) from test client.
5. Verify iptables rules applied: `iptables-save` should match template; ensure fail2ban jail active.

## Phase 5 – Automation & CI/CD
1. Create orchestrating Make targets or npm scripts and clearly mark which steps run locally vs. automatically in CI:
   - `make edge-build` → run build script with logging (manual/local by operator).
   - `make edge-validate` → connectivity + guest-agent checks (can be automated).
   - `make edge-deploy` → Ansible + service smoke tests (manual today, future CI job).
2. Draft GitHub Actions/GitLab CI workflow (manual trigger) noting required secrets/VPN context to:
   - Lint scripts (`shellcheck`, `ansible-lint` dry-run).
   - SSH to Proxmox via stored credentials, execute build with `FOLLOW=0`.
   - Retrieve `/tmp/alpine-build.log` artifact.
   - Run connectivity script against target IP (requires runner access to LAN).
3. Integrate Terraform/OpenTofu steps if automated VM provisioning is desired (apply on staging environment first).

## Phase 6 – Documentation & Knowledge Base
1. Update `infra/deployment.md` with the new automated flow, explaining scripts, environment variables, and troubleshooting tips (timeouts, DHCP issues, guest agent failures).
2. Add quick-start guide for operators: step-by-step from build to service validation.
3. Maintain change log in `docs/infra-changelog.md` capturing each successful Alpine build.
4. Include command cheat sheet (watch, test, ansible run) plus known-good outputs.

## Phase 7 – Monitoring & Alerting Enhancements
1. Implement a lightweight notification immediately: parse `/tmp/alpine-build.status` (or watcher output) and alert on `failed` via Slack/email.
2. Add Alpine edge VM to Prometheus/Uptime-Kuma for availability, guest agent heartbeat, Traefik response time.
3. Schedule periodic runs of `test-alpine-connectivity.sh` (cron or CI) to detect regressions early.

## Phase 8 – Future Improvements
1. Parameterize build script for multiple edge nodes (VMID, hostname, IP injection) and loop through inventory; pursue this in parallel with decisions on static vs DHCP reservations so inventory work is aligned.
2. Automate failover/chaos tests (stop primary node, ensure keepalived + Traefik failover).
3. Align backup strategy with Debian nodes: integrate PocketBase/VM backup scripts for Alpine hosts.
4. Investigate GitOps-based rollout (ArgoCD/Flux) for container stack once CI pipeline stabilizes.
5. Expand security posture: CIS hardening, vulnerability scanning, rotating SSH keys through Ansible Vault.

## Outstanding Questions / Follow-ups
- Decide on static vs DHCP reservation for Alpine edge IPs; document final addressing scheme.
- Confirm whether additional edge nodes require different sizing (RAM/CPU); adjust template accordingly.
- Determine owners for ongoing operations (who monitors build logs, responds to alerts).
- Align CI secrets management (Proxmox credentials, SSH keys) with organization’s security policies.

## Completed Deliverables (Phase 1 Items 3-4)

### 📋 Phase 1.3: Pipeline Idempotence Documentation & Automation
- **Created**: `infra/scripts/cleanup-alpine-build.sh` - Automated cleanup script for idempotent builds
- **Created**: `infra/ALPINE_CLEANUP_GUIDE.md` - Comprehensive cleanup and idempotence procedures
- **Features**:
  - Automated remote artifact cleanup (logs, status files, temp scripts)
  - VM and disk image cleanup with optional backup
  - Log archiving with timestamp rotation
  - Dry-run mode for safe testing
  - Integration-ready for CI/CD pipelines

### 🏗️ Phase 1.4: Template Creation Flow
- **Created**: `infra/scripts/create-alpine-template.sh` - Automated template creation from successful builds
- **Created**: `infra/ALPINE_TEMPLATE_GUIDE.md` - Complete template creation and management guide
- **Generated**: `infra/scripts/clone-from-alpine-template.sh` - Convenience script for template cloning
- **Features**:
  - Automated VM preparation and cleanup for template use
  - Template creation with proper configuration and metadata
  - Clone script generation for rapid edge node deployment
  - Comprehensive documentation with troubleshooting guides

### 🔧 Usage Examples

#### Pipeline Idempotence
```bash
# Clean state before build
./infra/scripts/cleanup-alpine-build.sh

# Run idempotent build
./infra/build-alpine-image-corrected.sh --follow

# Validate result
./infra/scripts/test-alpine-connectivity.sh
```

#### Template Operations
```bash
# Create template from successful build
./infra/scripts/create-alpine-template.sh

# Clone template for new edge node
./infra/scripts/clone-from-alpine-template.sh 9009 edge-node-2 --start

# Deploy multiple nodes
for i in {1..3}; do
  ./infra/scripts/clone-from-alpine-template.sh $((9010+i)) edge-node-$i --start
done
```

---

This plan incorporates the detailed recommendations generated by the Claude agent during /plan and reflects the current repository state as of this run. **Phase 1 items 3-4 completed September 24, 2025** with full automation and documentation.
