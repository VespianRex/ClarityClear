#!/usr/bin/env bash
# Executed when this node enters FAULT state

logger -t keepalived "FAULT state detected!"

# Alert about the fault
echo "$(date): Keepalived FAULT on $(hostname)" >> /var/log/keepalived-faults.log

# Try to recover services
systemctl restart docker || rc-service docker restart

# Optional: Send alert
# curl -X POST https://status.domain.com/api/alert -d "host=$(hostname) in FAULT state"

logger -t keepalived "FAULT handler complete"