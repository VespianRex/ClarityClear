#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1" >&2; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }

if [[ ! -f .env ]]; then
  error "Missing .env. Copy .env.example to .env and edit."
  exit 1
fi

# Load environment
set -a
source .env
set +a

# Validate required variables
required_vars=(
  PM_API_URL PM_USER PM_PASSWORD PM_NODE PM_STORAGE PM_BRIDGE
  VIP NFS_SERVER NFS_PATH DOMAIN_BASE LE_EMAIL SSH_PUBKEY ADMIN_USER
  DEBIAN_TEMPLATE_ID ALPINE_TEMPLATE_ID KEEPALIVED_PASSWORD
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    error "Missing required variable: $var"
    exit 1
  fi
done

# Extract Proxmox host
PVE_HOST="$(echo "$PM_API_URL" | sed -E 's#https?://([^/:]+).*#\1#')"
pve() { ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no root@"$PVE_HOST" "$@"; }

log "Ensuring Debian 12 cloud template exists (VMID ${DEBIAN_TEMPLATE_ID})"
pve "bash -c '
  set -e
  if ! qm config ${DEBIAN_TEMPLATE_ID} >/dev/null 2>&1; then
    echo \"Creating Debian 12 template...\"
    cd /var/lib/vz/template/iso
    wget -q -N https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
    qm create ${DEBIAN_TEMPLATE_ID} --name debian12-cloud --memory 1024 --cores 1 --net0 virtio,bridge=${PM_BRIDGE}
    qm importdisk ${DEBIAN_TEMPLATE_ID} debian-12-genericcloud-amd64.qcow2 ${PM_STORAGE}
    qm set ${DEBIAN_TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 ${PM_STORAGE}:vm-${DEBIAN_TEMPLATE_ID}-disk-0
    qm set ${DEBIAN_TEMPLATE_ID} --ide2 ${PM_STORAGE}:cloudinit
    qm set ${DEBIAN_TEMPLATE_ID} --boot c --bootdisk scsi0
    qm set ${DEBIAN_TEMPLATE_ID} --serial0 socket --vga serial0
    qm set ${DEBIAN_TEMPLATE_ID} --agent enabled=1
    qm template ${DEBIAN_TEMPLATE_ID}
    echo \"Debian template created.\"
  else
    echo \"Debian template already present.\"
  fi
'"

log "Ensuring Alpine cloud template exists (VMID ${ALPINE_TEMPLATE_ID})"
pve "bash -c '
  set -e
  if ! qm config ${ALPINE_TEMPLATE_ID} >/dev/null 2>&1; then
    echo \"Creating Alpine template...\"
    cd /var/lib/vz/template/iso
    wget -q -N https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/cloud/nocloud_alpine-3.19.0-x86_64-bios-cloudinit-r0.qcow2
    qm create ${ALPINE_TEMPLATE_ID} --name alpine-cloud --memory 512 --cores 1 --net0 virtio,bridge=${PM_BRIDGE}
    qm importdisk ${ALPINE_TEMPLATE_ID} nocloud_alpine-3.19.0-x86_64-bios-cloudinit-r0.qcow2 ${PM_STORAGE}
    qm set ${ALPINE_TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 ${PM_STORAGE}:vm-${ALPINE_TEMPLATE_ID}-disk-0
    qm set ${ALPINE_TEMPLATE_ID} --ide2 ${PM_STORAGE}:cloudinit
    qm set ${ALPINE_TEMPLATE_ID} --boot c --bootdisk scsi0
    qm set ${ALPINE_TEMPLATE_ID} --serial0 socket --vga serial0
    qm set ${ALPINE_TEMPLATE_ID} --agent enabled=1
    qm resize ${ALPINE_TEMPLATE_ID} scsi0 8G
    qm template ${ALPINE_TEMPLATE_ID}
    echo \"Alpine template created.\"
  else
    echo \"Alpine template already present.\"
  fi
'"

log "Running OpenTofu apply"
pushd tofu >/dev/null
tofu init -input=false

# Apply with all variables
tofu apply -auto-approve \
  -var pm_api_url="$PM_API_URL" \
  -var pm_user="$PM_USER" \
  -var pm_password="$PM_PASSWORD" \
  -var node="$PM_NODE" \
  -var node2="${PM_NODE2:-$PM_NODE}" \
  -var storage="$PM_STORAGE" \
  -var bridge="$PM_BRIDGE" \
  -var ssh_pubkey="$SSH_PUBKEY" \
  -var admin_user="$ADMIN_USER" \
  -var letsencrypt_email="$LE_EMAIL" \
  -var domain_base="$DOMAIN_BASE" \
  -var debian_template_id="$DEBIAN_TEMPLATE_ID" \
  -var alpine_template_id="$ALPINE_TEMPLATE_ID" \
  -var edge_a_name="$EDGE_A_NAME" \
  -var edge_b_name="$EDGE_B_NAME" \
  -var app_name="$APP_VM_NAME" \
  -var monitoring_name="$MONITORING_VM_NAME" \
  -var pbs_name="$PBS_VM_NAME" \
  -var vip="$VIP" \
  -var nfs_server="$NFS_SERVER" \
  -var nfs_path="$NFS_PATH"

# Extract IPs
EDGE_A_IP="$(tofu output -raw edge_a_ip 2>/dev/null || echo '')"
EDGE_B_IP="$(tofu output -raw edge_b_ip 2>/dev/null || echo '')"
APP_IP="$(tofu output -raw app_vm_ip 2>/dev/null || echo '')"
MONITORING_IP="$(tofu output -raw monitoring_vm_ip 2>/dev/null || echo '')"
PBS_IP="$(tofu output -raw pbs_vm_ip 2>/dev/null || echo '')"
NFS_IP="$(tofu output -raw nfs_vm_ip 2>/dev/null || echo '')"

popd >/dev/null

# Generate Ansible inventory
log "Generating Ansible inventory"
mkdir -p ansible/inventories ansible/group_vars ansible/host_vars

cat > ansible/inventories/production.ini <<EOF
[nfs]
${NFS_VM_NAME} ansible_host=${NFS_IP} ansible_user=${ADMIN_USER}

[edge]
${EDGE_A_NAME} ansible_host=${EDGE_A_IP} ansible_user=${ADMIN_USER} edge_priority=200
${EDGE_B_NAME} ansible_host=${EDGE_B_IP} ansible_user=${ADMIN_USER} edge_priority=150

[app]
${APP_VM_NAME} ansible_host=${APP_IP} ansible_user=${ADMIN_USER}

[monitoring]
${MONITORING_VM_NAME} ansible_host=${MONITORING_IP} ansible_user=${ADMIN_USER}

[pbs]
${PBS_VM_NAME} ansible_host=${PBS_IP} ansible_user=${ADMIN_USER}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Generate group vars
cat > ansible/group_vars/all.yml <<EOF
# Global variables
domain_base: ${DOMAIN_BASE}
letsencrypt_email: ${LE_EMAIL}
admin_user: ${ADMIN_USER}
lan_subnet: ${LAN_SUBNET}

# VIP Configuration
vip: ${VIP}
keepalived_password: ${KEEPALIVED_PASSWORD}
keepalived_router_id: ${KEEPALIVED_ROUTER_ID:-51}

# NFS Configuration
nfs_server: ${NFS_SERVER}
nfs_path: ${NFS_PATH}

# VPN Configuration
vpn_provider: ${VPN_PROVIDER}
vpn_port: ${VPN_PORT:-51820}

# Monitoring
grafana_admin_password: ${GRAFANA_ADMIN_PASSWORD}
prometheus_retention_days: ${PROMETHEUS_RETENTION_DAYS:-30}

# Backup Configuration
restic_password: ${RESTIC_PASSWORD}
restic_repo: ${RESTIC_REPO:-}
backup_s3_bucket: ${BACKUP_S3_BUCKET:-}
EOF

cat > ansible/group_vars/edge.yml <<EOF
app_ip: ${APP_IP}
monitoring_ip: ${MONITORING_IP}
EOF

cat > ansible/group_vars/app.yml <<EOF
edge_vip: ${VIP}
edge_a_ip: ${EDGE_A_IP}
edge_b_ip: ${EDGE_B_IP}
monitoring_ip: ${MONITORING_IP}
EOF

# Wait for VMs to be ready
log "Waiting for VMs to be ready..."
for ip in "$NFS_IP" "$EDGE_A_IP" "$EDGE_B_IP" "$APP_IP" "$MONITORING_IP" "$PBS_IP"; do
  if [[ -n "$ip" ]]; then
    for i in {1..30}; do
      if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ADMIN_USER}@${ip}" "echo 'VM ready'" &>/dev/null; then
        log "VM at $ip is ready"
        break
      fi
      [[ $i -eq 30 ]] && warn "VM at $ip may not be ready yet"
      sleep 5
    done
  fi
done

log "Running Ansible playbooks"
pushd ansible >/dev/null

# Run playbooks in order
ansible-playbook -i inventories/production.ini playbooks/site.yml

popd >/dev/null

log "Infrastructure deployment complete!"
echo ""
log "Access URLs:"
echo "  - Application: https://app.${DOMAIN_BASE}"
echo "  - PocketBase: https://pb.${DOMAIN_BASE}"
echo "  - Grafana: https://metrics.${DOMAIN_BASE}"
echo "  - Uptime Kuma: https://status.${DOMAIN_BASE}"
echo "  - PBS: https://backup.${DOMAIN_BASE}:8007"
echo ""
log "Virtual IP: ${VIP}"
log "Edge A: ${EDGE_A_IP}"
log "Edge B: ${EDGE_B_IP}"
echo ""
log "Test failover with: ./scripts/test-failover.sh"