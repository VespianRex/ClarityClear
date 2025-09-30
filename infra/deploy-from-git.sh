#!/bin/bash
set -euo pipefail

# Simple script to start edge VM services
EDGE_IP="192.168.0.192"
SSH_KEY="$HOME/.ssh/id_ed25519_clarity"
SSH_USER="VespianRex"

echo "Starting ClarityClear Edge Services"
echo "===================================="

# Start Traefik
echo "Starting Traefik reverse proxy..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$EDGE_IP" \
    "cd /opt/traefik && sudo docker compose up -d"

# Start AmneziaVPN
echo "Starting AmneziaVPN..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$EDGE_IP" \
    "cd /opt/amnezia && sudo docker compose up -d"

# Check status
echo -e "\nChecking services..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$EDGE_IP" \
    "sudo docker ps"

echo -e "\n✅ Edge services started!"
echo ""
echo "Configure your router:"
echo "  Port 80  → 192.168.0.192"
echo "  Port 443 → 192.168.0.192"
echo "  Port 51820 → 192.168.0.192 (VPN)"
echo ""
echo "Your domains will be:"
echo "  https://app.andub.go.ro  (Main site - auto SSL)"
echo "  https://pb.andub.go.ro   (PocketBase admin)"
echo "  https://metrics.andub.go.ro (Grafana)"
echo "  https://status.andub.go.ro  (Uptime monitoring)"