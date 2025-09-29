.PHONY: help up down destroy plan apply ansible health test-failover backup clean validate

# Default target
help:
	@echo "Infrastructure Management Commands:"
	@echo ""
	@echo "  make up              - Deploy complete infrastructure"
	@echo "  make down            - Stop all services (keeps data)"
	@echo "  make destroy         - Destroy all infrastructure (WARNING: data loss)"
	@echo "  make plan            - Show infrastructure changes"
	@echo "  make apply           - Apply infrastructure only"
	@echo "  make ansible         - Run Ansible playbooks only"
	@echo "  make health          - Run health checks"
	@echo "  make test-failover   - Test HA failover"
	@echo "  make backup          - Run manual backup"
	@echo "  make clean           - Clean local temporary files"
	@echo "  make validate        - Validate configurations"
	@echo ""
	@echo "Quick actions:"
	@echo "  make restart-edge    - Restart Edge services"
	@echo "  make restart-app     - Restart Application services"
	@echo "  make logs-edge       - Show Edge logs"
	@echo "  make logs-app        - Show App logs"

# Main operations
up:
	@echo "🚀 Deploying infrastructure..."
	@./run.sh

down:
	@echo "⏸️  Stopping services..."
	@cd ansible && ansible-playbook -i inventories/production.ini playbooks/stop.yml

destroy:
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@read -p "Are you sure? (type 'yes' to confirm): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@cd tofu && tofu destroy -auto-approve

# Infrastructure management
plan:
	@echo "📋 Planning infrastructure changes..."
	@cd tofu && tofu plan

apply:
	@echo "⚙️  Applying infrastructure..."
	@cd tofu && tofu apply -auto-approve

ansible:
	@echo "🔧 Running Ansible playbooks..."
	@cd ansible && ansible-playbook -i inventories/production.ini playbooks/site.yml

# Health and testing
health:
	@echo "🏥 Running health checks..."
	@./scripts/health-check.sh

test-failover:
	@echo "🔄 Testing HA failover..."
	@./scripts/test-failover.sh

# Backup operations
backup:
	@echo "💾 Running manual backup..."
	@ssh alex@clarity-app "/usr/local/bin/backup-clarity"

backup-status:
	@echo "📊 Backup status:"
	@ssh alex@clarity-app "restic -r /opt/clarity/backups snapshots --latest 5"

# Service management
restart-edge:
	@echo "🔄 Restarting Edge services..."
	@ssh alex@edge-a "cd /opt/traefik && docker compose restart"
	@ssh alex@edge-b "cd /opt/traefik && docker compose restart"

restart-app:
	@echo "🔄 Restarting Application services..."
	@ssh alex@clarity-app "cd /opt/clarity && docker compose restart"

# Logging
logs-edge:
	@echo "📜 Edge logs (last 50 lines):"
	@ssh alex@edge-a "docker logs traefik --tail 50"

logs-app:
	@echo "📜 Application logs (last 50 lines):"
	@ssh alex@clarity-app "docker logs pocketbase --tail 50"
	@ssh alex@clarity-app "docker logs clarity-web --tail 50"

logs-monitoring:
	@echo "📜 Monitoring logs (last 50 lines):"
	@ssh alex@monitoring "docker logs prometheus --tail 30"
	@ssh alex@monitoring "docker logs grafana --tail 30"

# Validation
validate:
	@echo "✅ Validating configurations..."
	@cd tofu && tofu validate
	@cd ansible && ansible-playbook -i inventories/production.ini playbooks/site.yml --syntax-check

# Cleanup
clean:
	@echo "🧹 Cleaning temporary files..."
	@find . -name "*.swp" -delete
	@find . -name "*~" -delete
	@find . -name "*.bak" -delete
	@rm -rf tofu/.terraform
	@rm -f tofu/.terraform.lock.hcl
	@rm -f ansible/*.retry

# Development
dev-env:
	@echo "🛠️  Setting up development environment..."
	@cp .env.example .env.dev
	@echo "Edit .env.dev with your development settings"

# Monitoring
grafana-password:
	@echo "🔑 Grafana admin password:"
	@grep GRAFANA_ADMIN_PASSWORD .env | cut -d= -f2

prometheus-targets:
	@echo "🎯 Prometheus targets:"
	@curl -s http://monitoring:9090/api/v1/targets | jq '.data.activeTargets[] | {job, instance, health}'

# VPN Management
vpn-users:
	@echo "👥 VPN users:"
	@ssh alex@edge-a "docker exec amnezia-vpn amnezia list-users"

vpn-add-user:
	@read -p "Enter username: " user && \
	ssh alex@edge-a "docker exec amnezia-vpn amnezia add-user $$user"

vpn-qr:
	@read -p "Enter username: " user && \
	ssh alex@edge-a "docker exec amnezia-vpn amnezia export-user $$user --qr"

# Quick status
status: health
	@echo ""
	@echo "🌐 Service URLs:"
	@echo "  - App: https://app.${DOMAIN_BASE}"
	@echo "  - PocketBase: https://pb.${DOMAIN_BASE}"
	@echo "  - Grafana: https://metrics.${DOMAIN_BASE}"
	@echo "  - Status: https://status.${DOMAIN_BASE}"