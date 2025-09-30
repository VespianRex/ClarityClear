#!/bin/bash

set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@192.168.0.33}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519_clarity}"
SSH_OPTS=(
  -i "$SSH_KEY_PATH"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=6
)

REMOTE_SCRIPT="/tmp/alpine-build-run.sh"
REMOTE_LOG="/tmp/alpine-build.log"
REMOTE_STATUS="/tmp/alpine-build.status"
REMOTE_EXIT="/tmp/alpine-build.exit"
REMOTE_PID="/tmp/alpine-build.pid"
REMOTE_VM_SUMMARY="/tmp/alpine-build-summary.txt"
VMID="${VMID:-9008}"

FOLLOW=${FOLLOW:-0}
if [[ "${1:-}" == "--follow" ]]; then
  FOLLOW=1
elif [[ "${1:-}" == "--no-follow" ]]; then
  FOLLOW=0
fi

echo "🚀 Launching Alpine VM build on ${REMOTE_HOST} (VMID ${VMID})"

# Stage the remote build script with logging and status markers
cat <<'EOS' | ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "cat > ${REMOTE_SCRIPT}"
#!/bin/bash
set -euo pipefail

STATUS_FILE='/tmp/alpine-build.status'
EXIT_FILE='/tmp/alpine-build.exit'
SUMMARY_FILE='/tmp/alpine-build-summary.txt'
LOG_PREFIX='[AlpineBuild]'
BUILD_DIR=/tmp/alpine-builder
IMAGE_PATH=/var/lib/vz/images/alpine-ssh-custom.qcow2
VMID=${VMID:-9008}

report() {
  printf "%s %s %s\n" "$(date -Iseconds)" "${LOG_PREFIX}" "$*"
}

update_status() {
  echo "$1" > "${STATUS_FILE}"
}

cleanup() {
  local rc=$?
  echo ${rc} > "${EXIT_FILE}"
  if [ ${rc} -eq 0 ]; then
    update_status success
    report "Build completed successfully"
  else
    update_status failed
    report "Build failed with exit code ${rc}"
  fi
}

trap cleanup EXIT

update_status running

report "Cleaning build directory ${BUILD_DIR}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

report "Fetching alpine-make-vm-image v0.13.3"
wget -q -O alpine-make-vm-image https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.3/alpine-make-vm-image
chmod +x alpine-make-vm-image

report "Writing setup script"
cat > setup-alpine-ssh.sh <<'SETUP'
#!/bin/sh
set -e

echo "🔧 Configuring Alpine Linux with SSH..."

cat > /etc/apk/repositories <<'REPOS'
https://dl-cdn.alpinelinux.org/alpine/v3.20/main
https://dl-cdn.alpinelinux.org/alpine/v3.20/community
REPOS

apk update
apk add --no-cache \
    openssh \
    openssh-server \
    openssh-client \
    sudo \
    qemu-guest-agent \
    curl \
    wget \
    bash \
    openrc \
    ifupdown-ng \
    iproute2

rc-update add sshd default
rc-update add qemu-guest-agent default
rc-update add networking boot
rc-update add hostname boot
rc-update add localmount boot

adduser -D -s /bin/bash VespianRex
echo 'VespianRex:${ADMIN_PASSWORD:-ChangeMe}' | chpasswd
addgroup VespianRex wheel

echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

mkdir -p /home/VespianRex/.ssh
cat > /home/VespianRex/.ssh/authorized_keys <<'SSHKEY'
${SSH_PUBKEY}
SSHKEY
chown -R VespianRex:VespianRex /home/VespianRex/.ssh
chmod 700 /home/VespianRex/.ssh
chmod 600 /home/VespianRex/.ssh/authorized_keys

mkdir -p /root/.ssh
cp /home/VespianRex/.ssh/authorized_keys /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

cat > /etc/ssh/sshd_config <<'SSHCFG'
Port 22
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/ssh/sftp-server
SSHCFG

ssh-keygen -A

cat > /etc/network/interfaces <<'NETCFG'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    udhcpc_opts -x hostname:alpine-ssh
NETCFG

mkdir -p /etc/modules-load.d
cat > /etc/modules-load.d/virtio.conf <<'MODULES'
virtio_pci
virtio_net
virtio_blk
virtio_console
MODULES

echo "alpine-ssh" > /etc/hostname
echo "root:${ADMIN_PASSWORD:-ChangeMe}" | chpasswd

echo "✅ Alpine SSH configuration complete!"
SETUP
chmod +x setup-alpine-ssh.sh

report "Invoking alpine-make-vm-image"
./alpine-make-vm-image \
    --image-format qcow2 \
    --image-size 3G \
    --serial-console \
    --branch v3.20 \
    --packages "openssh openssh-server sudo qemu-guest-agent bash openrc curl wget ifupdown-ng iproute2" \
    --script-chroot \
    alpine-ssh.qcow2 \
    ./setup-alpine-ssh.sh

report "Image creation finished"
qemu-img info alpine-ssh.qcow2

report "Moving image to ${IMAGE_PATH}"
mkdir -p /var/lib/vz/images/
mv alpine-ssh.qcow2 "${IMAGE_PATH}"

report "Reprovisioning VM ${VMID}"
qm stop ${VMID} 2>/dev/null || true
sleep 2
qm destroy ${VMID} 2>/dev/null || true

report "Creating VM configuration"
qm create ${VMID} \
    --name alpine-ssh-final \
    --memory 2048 \
    --balloon 1024 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --serial0 socket \
    --vga serial0 \
    --ostype l26

report "Importing disk"
qm importdisk ${VMID} "${IMAGE_PATH}" local-lvm

report "Attaching disk and enabling agent"
qm set ${VMID} --scsi0 local-lvm:vm-${VMID}-disk-0
qm set ${VMID} --bootdisk scsi0
qm set ${VMID} --boot order=scsi0
qm set ${VMID} --scsihw virtio-scsi-pci
qm set ${VMID} --agent 1

report "Resizing disk to 10G"
qm resize ${VMID} scsi0 10G

report "Starting VM ${VMID}"
qm start ${VMID}

report "Waiting 60s for guest agent"
sleep 60
if qm agent ${VMID} ping 2>/dev/null; then
  report "Guest agent responding"
  qm guest cmd ${VMID} network-get-interfaces 2>/dev/null || true
else
  report "Guest agent not ready after wait"
fi

report "Collecting guest diagnostics"
qm guest exec ${VMID} -- /bin/sh -lc 'rc-update show' >/tmp/alpine-rc-update.log 2>/tmp/alpine-rc-update.err || true
qm guest exec ${VMID} -- /bin/sh -lc 'rc-status -a' >/tmp/alpine-rc-status.log 2>/tmp/alpine-rc-status.err || true
qm guest exec ${VMID} -- /bin/sh -lc 'cat /etc/network/interfaces' >/tmp/alpine-network.log 2>/tmp/alpine-network.err || true

cat > "${SUMMARY_FILE}" <<SUMMARY
VMID: ${VMID}
Image: ${IMAGE_PATH}
Build completed: $(date -Iseconds)
SUMMARY

report "Build procedure finished"
EOS

# Ensure script is executable and clean prior state
ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "chmod +x ${REMOTE_SCRIPT}"
ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "rm -f ${REMOTE_LOG} ${REMOTE_STATUS} ${REMOTE_EXIT} ${REMOTE_PID} ${REMOTE_VM_SUMMARY}"

# Launch remote script in the background and capture PID
ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "VMID=${VMID} nohup bash ${REMOTE_SCRIPT} > ${REMOTE_LOG} 2>&1 & echo \$! > ${REMOTE_PID}"

echo "📡 Remote build started."

if [[ "${FOLLOW}" == "0" ]]; then
  echo "ℹ️ Follow disabled (default)."
  echo "   Run ./infra/scripts/watch-alpine-build.sh for status or tail ${REMOTE_LOG} on the host."
  exit 0
fi

last_lines=0
sleep 5

while true; do
  status=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f ${REMOTE_STATUS} ]; then cat ${REMOTE_STATUS}; else echo pending; fi")
  exit_code=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f ${REMOTE_EXIT} ]; then cat ${REMOTE_EXIT}; else echo ''; fi")
  log_lines=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f ${REMOTE_LOG} ]; then wc -l < ${REMOTE_LOG}; else echo 0; fi")

  log_lines=${log_lines//$'\r'/}
  log_lines=${log_lines:-0}

  if (( log_lines > last_lines )); then
    next_line=$((last_lines + 1))
    ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f ${REMOTE_LOG} ]; then sed -n '${next_line},\$p' ${REMOTE_LOG}; fi"
    last_lines=${log_lines}
  fi

  if [[ "${status}" == "success" ]]; then
    echo "✅ Remote build completed successfully."
    if [[ -n "${exit_code}" ]]; then
      echo "Remote exit code: ${exit_code}"
    fi
    summary=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f ${REMOTE_VM_SUMMARY} ]; then cat ${REMOTE_VM_SUMMARY}; fi" || true)
    if [[ -n "${summary}" ]]; then
      echo "--- Remote Summary ---"
      echo "${summary}"
      echo "----------------------"
    fi
    break
  elif [[ "${status}" == "failed" ]]; then
    echo "❌ Remote build failed."
    if [[ -n "${exit_code}" ]]; then
      echo "Remote exit code: ${exit_code}"
    fi
    ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "tail -n 100 ${REMOTE_LOG} 2>/dev/null" || true
    exit 1
  fi

  alive=$(ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "if [ -f ${REMOTE_PID} ] && ps -p \\$(cat ${REMOTE_PID}) >/dev/null 2>&1; then echo alive; else echo dead; fi")
  if [[ "${alive}" == "dead" && "${status}" != "success" && "${status}" != "failed" ]]; then
    echo "⚠️ Remote process ended unexpectedly. Dumping last log entries."
    ssh "${SSH_OPTS[@]}" "${REMOTE_HOST}" "tail -n 100 ${REMOTE_LOG} 2>/dev/null" || true
    exit 1
  fi

  sleep 15
done

echo "📁 Logs available on ${REMOTE_HOST}:${REMOTE_LOG}"
echo "Run 'ssh ${REMOTE_HOST} \"tail -f ${REMOTE_LOG}\"' for live monitoring in another terminal."
