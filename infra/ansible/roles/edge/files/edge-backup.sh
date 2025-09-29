#!/usr/bin/env bash
# Executed when this node becomes BACKUP

logger -t keepalived "Becoming BACKUP, keeping services running for hot standby"

# Keep services running for instant failover (hot standby)
# This ensures zero-downtime during failover

# Optionally stop services for cold standby (not recommended)
# cd /opt/traefik && docker compose down
# cd /opt/amnezia && docker compose down

logger -t keepalived "BACKUP transition complete (hot standby mode)"