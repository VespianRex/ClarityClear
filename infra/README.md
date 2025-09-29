# 🚀 Production-Ready HA Infrastructure for ClarityClear

Enterprise-grade infrastructure with **High Availability**, **automated backups**, **comprehensive monitoring**, and **zero-downtime deployments** on Proxmox.

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                      Internet                           │
│                          │                              │
│                    DNS (*.andub.go.ro)                  │
│                          │                              │
│                   NAT Router (80/443/VPN)               │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │   VIP: 192.168.0.50     │ ← Keepalived VRRP
        └────────┬───────┬────────┘
                 │       │
    ┌────────────▼───┐ ┌─▼────────────┐
    │   Edge-A VM    │ │   Edge-B VM   │  ← Alpine Linux (HA Pair)
    │  - Traefik     │ │  - Traefik    │     NFS Shared State
    │  - AmneziaVPN  │ │  - AmneziaVPN │
    └────────┬───────┘ └───────┬──────┘
             │                 │
    ┌────────▼─────────────────▼──────┐
    │         Application VM           │  ← Debian 12
    │    - Next.js App (port 3000)     │
    │    - PocketBase  (port 8090)     │
    │    - Redis Cache                 │
    └──────────────────────────────────┘

    ┌──────────────────────────────────┐
    │        Monitoring VM              │  ← Debian 12
    │    - Prometheus & Grafana         │
    │    - Loki & Promtail              │
    │    - Uptime Kuma                  │
    └──────────────────────────────────┘

    ┌──────────────────────────────────┐
    │    Proxmox Backup Server VM       │  ← Debian 12
    │    - Automated VM snapshots       │
    │    - Incremental backups           │
    └──────────────────────────────────┘
```

## 🎯 Key Features

### High Availability
- **Dual Edge VMs** with Keepalived VRRP failover (< 3 second switchover)
- **Virtual IP (VIP)** ensures zero-downtime during maintenance
- **Hot standby** configuration - both edges run simultaneously
- **Shared state** via NFS for Traefik certificates & Amnezia configs

### Security
- **AmneziaVPN** for secure remote access
- **UFW firewall** with deny-all baseline
- **Fail2ban** for brute-force protection
- **TLS 1.2+** only with modern cipher suites
- **Rate limiting** on all public endpoints
- **Network segmentation** - apps only accessible from Edge VMs

### Monitoring & Observability
- **Prometheus** for metrics collection
- **Grafana** dashboards for visualization
- **Loki** for centralized logging
- **Uptime Kuma** for service monitoring
- **Custom alerts** for disk, CPU, memory, certificates

### Backup Strategy
- **Proxmox Backup Server** for VM-level backups
- **Restic** for application data backups
- **Automated schedules** with retention policies
- **7 daily, 4 weekly, 6 monthly** snapshots

## 🛠️ Quick Start

### Prerequisites

1. **Proxmox Cluster** (2+ nodes recommended)
2. **NFS Server** (NAS or dedicated VM)
3. **Domain** with DNS control
4. **Control Machine** with:
   ```bash
   brew install opentofu ansible
   ```

### Alpine Edge Build Workflow (September 2025)

1. **Build the image**
   ```bash
   ./infra/build-alpine-image-corrected.sh --follow
   ```
   Uploads the remote runner to Proxmox, streams progress to `/tmp/alpine-build.log`, and provisions VM `9008` from scratch.

2. **Monitor progress**
   ```bash
   ./infra/scripts/watch-alpine-build.sh
   ```
   Prints remote status, exit code, PID state, optional summary, and the tail of the remote log.

3. **Validate connectivity**
   ```bash
   ALPINE_IPS="192.168.0.220" ./infra/scripts/test-alpine-connectivity.sh
   ```
   Runs ping + SSH checks and reports OpenRC status for `sshd` and `qemu-guest-agent`.

4. **Archive artefacts**
   Follow `infra/logs/README.md` to copy `/tmp/alpine-*` logs and `qm` outputs into a dated folder for traceability.

Refer to `CIplan.md` for the phased automation roadmap and completion tracker.

### Setup Instructions

1. **Clone and configure:**
   ```bash
   cd infra
   cp .env.example .env
   # Edit .env with your settings
   ```

2. **Key variables to configure:**
   ```bash
   PM_API_URL=https://192.168.0.33:8006/api2/json
   PM_USER=root@pam
   PM_PASSWORD=your-password
   VIP=192.168.0.50              # Virtual IP for HA
   NFS_SERVER=192.168.0.55       # Your NFS server
   DOMAIN_BASE=andub.go.ro       # Your domain
   ```

3. **Deploy infrastructure:**
   ```bash
   ./run.sh
   ```

4. **Test failover:**
   ```bash
   ./scripts/test-failover.sh
   ```

## 📁 Directory Structure

```
infra/
├── .env.example           # Configuration template
├── run.sh                 # Main deployment script
├── tofu/                  # OpenTofu (Terraform)
│   ├── provider.tf       # Proxmox provider config
│   ├── variables.tf      # Input variables
│   ├── main.tf          # VM definitions
│   └── outputs.tf       # Output values
├── ansible/              # Configuration management
│   ├── playbooks/       # Main playbooks
│   ├── roles/           # Component roles
│   │   ├── edge/       # HA Edge configuration
│   │   ├── app/        # Application stack
│   │   ├── monitoring/ # Observability stack
│   │   └── pbs/        # Backup server
│   └── inventories/     # Dynamic inventory
└── scripts/             # Utility scripts
    ├── test-failover.sh # HA testing
    └── health-check.sh  # System health
```

## 🔧 Management Commands

### Health Checks
```bash
# Full system health check
./scripts/health-check.sh

# Test HA failover
./scripts/test-failover.sh

# Check VIP status
ssh alex@edge-a "ip addr show | grep 192.168.0.50"
```

### Backup Operations
```bash
# Manual backup
ssh alex@clarity-app "/usr/local/bin/backup-clarity"

# Check backup status
restic -r /opt/clarity/backups snapshots

# Restore from backup
restic -r /opt/clarity/backups restore latest --target /restore
```

### Monitoring Access
- **Grafana**: https://metrics.andub.go.ro (admin/configured-password)
- **Uptime Kuma**: https://status.andub.go.ro
- **Prometheus**: http://monitoring-vm:9090 (internal only)

### VPN Management
```bash
# Add new VPN user
ssh alex@edge-a "docker exec amnezia-vpn amnezia add-user alice"

# Generate QR code for mobile
ssh alex@edge-a "docker exec amnezia-vpn amnezia export-user alice --qr"

# List users
ssh alex@edge-a "docker exec amnezia-vpn amnezia list-users"
```

## 📈 Monitoring Dashboards

### Available Dashboards
- **System Overview**: CPU, memory, disk, network
- **Docker Containers**: Resource usage, health
- **Traefik**: Request rates, response times, errors
- **Application**: Next.js & PocketBase metrics
- **Backup Status**: Last run, size, success rate

### Key Metrics
- Response time (p95 < 2s)
- Error rate (< 1%)
- CPU usage (< 80%)
- Memory usage (< 80%)
- Disk usage (< 85%)
- Certificate expiry (> 7 days)

## 🔐 Security Considerations

1. **Network Security**
   - All VMs behind UFW firewall
   - SSH restricted to LAN only
   - Apps accessible only via Edge VMs
   - VPN for admin access

2. **TLS/SSL**
   - Auto-renewed Let's Encrypt certificates
   - TLS 1.2+ minimum
   - HSTS enabled with preload
   - Modern cipher suites only

3. **Access Control**
   - SSH key-only authentication
   - Fail2ban on all public services
   - Rate limiting on API endpoints
   - Basic auth on admin interfaces

## 🚨 Troubleshooting

### VIP not accessible
```bash
# Check keepalived status
systemctl status keepalived

# Check VRRP communication
tcpdump -i eth0 vrrp

# Force master transition
systemctl restart keepalived
```

### Service unhealthy
```bash
# Check container logs
docker logs traefik
docker logs pocketbase

# Restart service
docker compose -f /opt/traefik/docker-compose.yml restart
```

### Disk space issues
```bash
# Clean Docker
docker system prune -a

# Clean old backups
restic forget --keep-daily 7 --keep-weekly 4 --prune
```

## 📚 Advanced Configuration

### Adding New Services

1. **Update Traefik routing** in `edge/templates/traefik-dynamic.yml.j2`
2. **Add firewall rules** in respective role
3. **Add monitoring targets** in `monitoring/templates/prometheus.yml.j2`
4. **Deploy** with `ansible-playbook -i inventories/production.ini playbooks/site.yml`

### Scaling Considerations

- **Add more Edge VMs**: Update keepalived priority values
- **Add more App VMs**: Use Traefik load balancing
- **Increase monitoring retention**: Adjust `prometheus_retention_days`
- **Add Kubernetes**: K3s ready, just add nodes

## 🔄 Maintenance Procedures

### Rolling Updates
```bash
# Update Edge-A
ssh alex@edge-a "sudo apt update && sudo apt upgrade -y"
ssh alex@edge-a "sudo reboot"
# Wait for Edge-B to take over

# Update Edge-B
ssh alex@edge-b "sudo apt update && sudo apt upgrade -y"
ssh alex@edge-b "sudo reboot"
```

### Certificate Renewal
Automatic via Traefik, but manual check:
```bash
docker exec traefik traefik version
cat /opt/edge-shared/traefik/acme.json | jq '.Certificates[].certificate.NotAfter'
```

### Backup Restoration Test
```bash
# Monthly DR test
./scripts/test-restore.sh
```

## 📞 Support

For issues or questions:
1. Check health: `./scripts/health-check.sh`
2. Review logs: `docker logs <container>`
3. Check metrics: https://metrics.andub.go.ro
4. Review this documentation

## 🚀 Future Enhancements

- [ ] Kubernetes integration (K3s)
- [ ] GitOps with ArgoCD
- [ ] HashiCorp Vault for secrets
- [ ] Distributed tracing with Jaeger
- [ ] Cost optimization dashboards
- [ ] Multi-region DR setup

---

**Built with ❤️ using open-source tools**
