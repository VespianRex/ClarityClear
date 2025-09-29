#!/bin/bash

set -euo pipefail

SSH_USER="${SSH_USER:-VespianRex}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_clarity}"
SSH_TIMEOUT="${SSH_TIMEOUT:-5}"
PING_COUNT="${PING_COUNT:-1}"
VM_IDS="${VM_IDS:-}" # Optional space separated list for qm agent lookups

usage() {
  cat <<'USAGE'
Usage: test-alpine-connectivity.sh [ip ...]

Options via environment variables:
  SSH_USER      SSH username to test (default: VespianRex)
  SSH_KEY       Path to SSH private key (default: ~/.ssh/id_ed25519_clarity)
  SSH_TIMEOUT   Seconds ssh should wait before failing (default: 5)
  PING_COUNT    Number of ICMP echo requests to send (default: 1)
  VM_IDS        Space separated Proxmox VMIDs to query via qm guest agent

If no IPs are provided on the command line, the script will look for
ALPINE_IPS environment variable. If still empty and VM_IDS is set with a
working qemu-guest-agent, IPs will be discovered automatically.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

declare -a ip_args
if [[ $# -gt 0 ]]; then
  ip_args=("$@")
elif [[ -n "${ALPINE_IPS:-}" ]]; then
  read -r -a ip_args <<<"${ALPINE_IPS}"
fi

# Attempt discovery via qm guest agent if requested and no IPs supplied yet
if [[ ${#ip_args[@]} -eq 0 && -n "$VM_IDS" ]] && command -v qm >/dev/null 2>&1; then
  for vmid in $VM_IDS; do
    echo "[discover] Querying qm guest agent for VM ${vmid} ..."
    if qm agent "$vmid" ping >/dev/null 2>&1; then
      ifaces=$(qm guest cmd "$vmid" network-get-interfaces 2>/dev/null || true)
      ips=$(echo "$ifaces" | jq -r '.[]?."ip-addresses"[]?."ip-address"' 2>/dev/null | awk 'NF')
      if [[ -n "$ips" ]]; then
        echo "$ips" | while read -r ip; do
          [[ "$ip" == 127.* || "$ip" == ::* ]] && continue
          echo "[discover] VM ${vmid} reported IP ${ip}"
          ip_args+=("$ip")
        done
      else
        echo "[warn] Guest agent returned no addresses for VM ${vmid}" >&2
      fi
    else
      echo "[warn] Guest agent ping failed for VM ${vmid}" >&2
    fi
  done
fi

if [[ ${#ip_args[@]} -eq 0 ]]; then
  echo "No target IPs supplied. Use arguments, ALPINE_IPS, or VM_IDS." >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$SSH_KEY" ]]; then
  echo "[warn] SSH key $SSH_KEY not found; SSH tests will likely fail." >&2
fi

for ip in "${ip_args[@]}"; do
  echo "=== Testing ${ip} ==="

  if ping -c "$PING_COUNT" -W "$SSH_TIMEOUT" "$ip" >/dev/null 2>&1; then
    echo "  [ok] Ping responded"
  else
    echo "  [warn] Ping failed" >&2
  fi

  if ssh -i "$SSH_KEY" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout="$SSH_TIMEOUT" \
    -o BatchMode=yes \
    "$SSH_USER@$ip" 'hostname && rc-service sshd status && rc-service qemu-guest-agent status' >/tmp/ssh-test-$$.log 2>&1; then
    echo "  [ok] SSH connection succeeded"
    sed 's/^/    /' /tmp/ssh-test-$$.log
  else
    echo "  [fail] SSH connection failed" >&2
    sed 's/^/    /' /tmp/ssh-test-$$.log >&2
  fi
  rm -f /tmp/ssh-test-$$.log
  echo
done

echo "Connectivity checks complete."
