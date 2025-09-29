# Phase 3 Progress Notes (September 24, 2025)

## Inventory Update
- `infra/ansible/inventory/hosts.yml` now defines explicit groups (`edge`, `app`, `monitoring`, `pbs`, `nfs`) matching `site.yml` plays.
- Added `edge-primary` host pointing to the newly built Alpine VM (`192.168.0.192`).
- Introduced `domain_base` and `nfs_path` variables used by roles.
- Disabled host key checking via `ansible_ssh_common_args` for smoother automation.

## Ansible Runs
- `ansible-playbook ... --tags edge --skip-tags edge-packages --check --diff` completed successfully via background execution; log at `infra/logs/2025-09-24/ansible-edge-check.log`.
- The subsequent apply run (`ansible-playbook ... --skip-tags edge-packages`) progressed through directory creation and keepalived config but failed mounting NFS shares: Proxmox/Synology export denied access (`mount.nfs: access denied by server while mounting ...`).
- Manual follow-up required on NAS export permissions or adjust mount strategy (e.g., ensure subdirectories exported, or configure credentials).
- Base packages, util-linux, rpcbind, and docker dependencies installed ahead of the role to reduce playbook duration.

## Connectivity Verification
- Re-ran `infra/scripts/test-alpine-connectivity.sh` against `192.168.0.192`; results in `infra/logs/2025-09-24/connectivity-check-20-15.txt` (ping + OpenRC service checks).

## Next Steps
1. Re-run the full edge role (`ansible-playbook ... --tags edge`) from an environment without the CLI timeout and capture logs under `infra/logs/ansible/`.
2. Resolve NFS export permissions so `/volume1/proxmox-shared/{traefik,amnezia}` are mountable from edge nodes, then rerun apply.
3. Once apply completes, update CIplan and archive the successful apply log under `infra/logs/ansible/`.
