#!/usr/bin/env bash
# Executed when this node becomes MASTER

logger -t keepalived "Becoming MASTER, ensuring services are running"

# Ensure Docker is running
systemctl start docker || rc-service docker start

# Start Traefik
cd /opt/traefik && docker compose up -d

# Start AmneziaVPN
cd /opt/amnezia && docker compose up -d

# Log status
logger -t keepalived "MASTER transition complete"

# Send notification (optional)
# curl -X POST https://status.domain.com/api/notify -d "host=$(hostname) is now MASTER"