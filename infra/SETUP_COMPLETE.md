# 🎉 ClarityClear Deployment - Ready to Go Live!

## Current Status: ✅ ALL SERVICES RUNNING

### Running Services:

**Edge VM (192.168.0.192):**
- ✅ Traefik reverse proxy (ports 80, 443) with auto SSL
- ✅ fail2ban protecting SSH
- ✅ Netbird client installed

**App VM (192.168.0.180):**
- ✅ Your actual ClarityClear Next.js website
- ✅ PocketBase with YOUR database (pb_data/)
- ✅ Netbird client installed

**Monitoring VM (192.168.0.207):**
- ✅ Prometheus, Grafana, Loki
- ✅ Authentik SSO (identity provider)
- ✅ Netbird self-hosted management server
- ✅ Netbird client installed

---

## 🚀 TO GO LIVE (15 minutes):

### Step 1: Configure Router Port Forwarding

Forward these ports to **192.168.0.192** (your edge VM):
```
External Port 80  → Internal 192.168.0.192:80
External Port 443 → Internal 192.168.0.192:443
```

### Step 2: Set up Authentik (First Time Only)

1. Access: `http://192.168.0.207:9000/if/flow/initial-setup/`
2. Create admin account (email + password)
3. Login to Authentik admin

### Step 3: Configure Netbird OIDC in Authentik

1. In Authentik, go to **Applications** → **Providers** → **Create Provider**
2. Select **OAuth2/OpenID Provider**
3. Fill in:
   - **Name**: Netbird
   - **Authorization flow**: default-provider-authorization-implicit-consent
   - **Client type**: Confidential
   - **Client ID**: netbird
   - **Redirect URIs**: `http://192.168.0.207:80/auth` (add more as needed)
   - **Scopes**: openid, profile, email, offline_access

4. Click **Create** and **copy the Client Secret**

### Step 4: Update Netbird Configuration

SSH to monitoring VM and update Netbird:

```bash
ssh VespianRex@192.168.0.207

# Stop Netbird services
cd /opt/netbird
sudo docker compose down

# Update management.json with Authentik details
sudo tee management.json > /dev/null << 'EOF'
{
  "Stuns": [
    {"Proto": "udp", "URI": "stun:192.168.0.207:3478"}
  ],
  "TURNConfig": {
    "Turns": [{
      "Proto": "udp",
      "URI": "turn:192.168.0.207:3478",
      "Username": "netbird",
      "Password": "netbird123"
    }]
  },
  "Signal": {
    "Proto": "http",
    "URI": "192.168.0.207:10000"
  },
  "Datadir": "/var/lib/netbird",
  "HttpConfig": {
    "Address": "0.0.0.0:33073",
    "AuthIssuer": "http://192.168.0.207:9000/application/o/netbird/",
    "AuthAudience": "netbird",
    "AuthKeysLocation": "http://192.168.0.207:9000/application/o/netbird/.well-known/jwks.json"
  }
}
EOF

# Restart Netbird
sudo docker compose up -d
```

### Step 5: Connect Your VMs to Netbird Mesh

On each VM (edge, app, monitoring), run:

```bash
# Get setup key from Netbird dashboard first
sudo netbird up --management-url http://192.168.0.207:33073 --setup-key <SETUP-KEY>
```

To get setup key:
1. Access Netbird dashboard (see URLs below)
2. Go to **Setup Keys** → **Create Setup Key**
3. Copy the key
4. Run the command above on each VM

---

## 🌐 Your Live URLs (after router config):

### Public URLs (with auto SSL):
- `https://app.andub.go.ro` - Your main website
- `https://pb.andub.go.ro` - PocketBase admin
- `https://auth.andub.go.ro` - Authentik SSO login
- `https://vpn.andub.go.ro` - Netbird dashboard
- `https://metrics.andub.go.ro` - Grafana monitoring
- `https://status.andub.go.ro` - Uptime monitoring

### Internal URLs (LAN only):
- `http://192.168.0.180:3000` - App direct access
- `http://192.168.0.207:9000` - Authentik direct
- `http://192.168.0.207:3000` - Grafana direct

---

## 📋 Quick Commands:

### Check Service Status:
```bash
# Edge VM
ssh VespianRex@192.168.0.192 "sudo docker ps && sudo fail2ban-client status"

# App VM
ssh VespianRex@192.168.0.180 "systemctl status clarity-app pocketbase"

# Monitoring VM
ssh VespianRex@192.168.0.207 "docker ps | grep -E 'authentik|netbird|prometheus|grafana'"
```

### View Logs:
```bash
# Next.js app
ssh VespianRex@192.168.0.180 "journalctl -u clarity-app -f"

# PocketBase
ssh VespianRex@192.168.0.180 "journalctl -u pocketbase -f"

# Traefik
ssh VespianRex@192.168.0.192 "sudo docker logs -f traefik"
```

### Restart Services:
```bash
# Restart everything
ssh VespianRex@192.168.0.180 "sudo systemctl restart clarity-app pocketbase"
ssh VespianRex@192.168.0.192 "sudo docker restart traefik"
ssh VespianRex@192.168.0.207 "cd /opt/authentik && docker compose restart"
```

---

## 🔐 Security Summary:

✅ **HTTPS/SSL** - Automatic Let's Encrypt certificates via Traefik
✅ **Firewall** - fail2ban protecting SSH on edge VM
✅ **Rate Limiting** - Traefik protecting all services
✅ **Security Headers** - HSTS, XSS protection, etc.
✅ **VPN Access** - Netbird mesh network for secure remote access
✅ **SSO** - Authentik for centralized authentication

---

## 📊 What's NOT Done Yet:

- ⏳ Keepalived (need 2nd edge VM for HA)
- ⏳ NFS shared storage (for edge HA state)
- ⏳ Backup automation with PBS
- ⏳ Complete monitoring dashboards

These can be added later. **Your site is production-ready now!**

---

## 🎯 Summary:

1. **Configure your router** (forward ports 80, 443 → 192.168.0.192)
2. **Set up Authentik** (create admin account)
3. **Configure Netbird OIDC** in Authentik
4. **Connect VMs** to Netbird mesh
5. **Your site goes live** at https://app.andub.go.ro with auto SSL!

**Total time to go live: ~15 minutes** ⚡