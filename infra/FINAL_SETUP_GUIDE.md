# 🎯 ClarityClear - Final Setup Steps

## Current Status: 95% Complete! ✅

Everything is deployed and running. Just need to configure OAuth and go live.

---

## Step 1: Set Up Authentik (5 minutes)

1. **Access Authentik**: http://192.168.0.207:9000/if/flow/initial-setup/
2. **Create admin account**:
   - Email: your-email@example.com
   - Password: (choose a strong password)
3. **Login** with your new admin account

---

## Step 2: Create Netbird OAuth Provider in Authentik (10 minutes)

Following: https://integrations.goauthentik.io/networking/netbird/

### 2.1 Create OAuth Provider

1. In Authentik admin, go to **Applications** → **Providers** → **Create**
2. Select **OAuth2/OpenID Provider**
3. Configure:
   - **Name**: `Netbird`
   - **Authorization flow**: `default-provider-authorization-implicit-consent`
   - **Client type**: `Public`
   - **Client ID**: `netbird`
   - **Redirect URIs** (add all these):
     ```
     http://localhost:53000
     https://vpn.andub.go.ro/*
     http://192.168.0.207:8085/*
     ```
   - **Signing Key**: (use default)
   - **Scopes**: Select these:
     - `authentik default OAuth Mapping: OpenID 'email'`
     - `authentik default OAuth Mapping: OpenID 'openid'`
     - `authentik default OAuth Mapping: OpenID 'profile'`
     - `authentik default OAuth Mapping: OpenID 'offline_access'`
     - `authentik default OAuth Mapping: authentik API access`

4. **Click Save** and note the **Client ID** (should be `netbird`)

### 2.2 Create Service Account

1. Go to **Directory** → **Users** → **Create**
2. Configure:
   - **Username**: `netbird-service`
   - **Name**: `Netbird Service Account`
   - **Email**: `netbird@andub.go.ro`
   - **Path**: `users`
   - **Type**: Check ✅ **Service account**
3. **Set password**: `netbird_service_pass_2025`
4. **Save** the user

5. Go to **Directory** → **Groups** → `authentik Admins` → **Edit**
6. Add `netbird-service` user to the group
7. **Save**

### 2.3 Create Netbird Application

1. Go to **Applications** → **Applications** → **Create**
2. Configure:
   - **Name**: `Netbird`
   - **Slug**: `netbird`
   - **Provider**: Select the `Netbird` provider you just created
   - **Launch URL**: `https://vpn.andub.go.ro`
3. **Save**

### 2.4 Configure Device Code Flow (Important!)

1. Go to **Flows & Stages** → **Flows** → **Create**
2. Configure:
   - **Name**: `default-device-code-flow`
   - **Title**: `Device Code Authentication`
   - **Slug**: `default-device-code-flow`
   - **Designation**: `Authentication`
3. **Save**

4. Go to **System** → **Brands** → **authentik-default** → **Edit**
5. Under **Default flows**:
   - Set **Device code flow** to `default-device-code-flow`
6. **Save**

---

## Step 3: Update Netbird Configuration (2 minutes)

Now that Authentik is configured, update Netbird to use it:

```bash
ssh VespianRex@192.168.0.207

cd /opt/netbird

# Create the updated management.json
sudo tee management.json > /dev/null << 'EOF'
{
  "Stuns": [
    {
      "Proto": "udp",
      "URI": "stun:192.168.0.207:3478"
    }
  ],
  "TURNConfig": {
    "Turns": [
      {
        "Proto": "udp",
        "URI": "turn:192.168.0.207:3478",
        "Username": "netbird",
        "Password": "netbird123"
      }
    ]
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
    "AuthKeysLocation": "http://192.168.0.207:9000/application/o/netbird/jwks/",
    "OIDCConfigEndpoint": "http://192.168.0.207:9000/application/o/netbird/.well-known/openid-configuration"
  },
  "IdpManagerConfig": {
    "ManagerType": "authentik",
    "ClientConfig": {
      "Issuer": "http://192.168.0.207:9000/application/o/netbird/",
      "TokenEndpoint": "http://192.168.0.207:9000/application/o/netbird/token/",
      "ClientID": "netbird",
      "Username": "netbird-service",
      "Password": "netbird_service_pass_2025"
    }
  }
}
EOF

# Update docker-compose to use env file
sudo tee -a docker-compose.yml > /dev/null << 'EOF'

  # Dashboard needs environment variables
  dashboard:
    environment:
      - NETBIRD_MGMT_API_ENDPOINT=http://192.168.0.207:33073
      - NETBIRD_MGMT_GRPC_API_ENDPOINT=http://192.168.0.207:33073
      - AUTH_AUDIENCE=netbird
      - AUTH_CLIENT_ID=netbird
      - AUTH_AUTHORITY=http://192.168.0.207:9000/application/o/netbird/
      - USE_AUTH0=false
      - AUTH_SUPPORTED_SCOPES=openid profile email offline_access api
      - NETBIRD_TOKEN_SOURCE=accessToken
EOF

# Restart Netbird services
sudo docker compose down
sudo docker compose up -d

# Check status
docker compose ps
```

---

## Step 4: Configure Your Router (5 minutes)

Log into your router and forward these ports to **192.168.0.192**:

```
External Port 80  → 192.168.0.192:80
External Port 443 → 192.168.0.192:443
```

Your router IP: Likely 192.168.0.1 or check your gateway with `ip route | grep default`

---

## Step 5: Access Netbird Dashboard & Create Setup Key

1. **Access dashboard**: http://192.168.0.207:8085
2. **Login** - It will redirect to Authentik
3. **Login with your Authentik admin account**
4. In Netbird dashboard:
   - Go to **Setup Keys**
   - Click **Add Key**
   - Name: `infrastructure-vms`
   - Expires: Never (or set expiry)
   - Copy the setup key

---

## Step 6: Connect Your VMs to Netbird Mesh (5 minutes)

Using the setup key from Step 5, run on each VM:

### Edge VM:
```bash
ssh VespianRex@192.168.0.192
sudo netbird up --management-url http://192.168.0.207:33073 --setup-key YOUR_SETUP_KEY_HERE
```

### App VM:
```bash
ssh VespianRex@192.168.0.180
sudo netbird up --management-url http://192.168.0.207:33073 --setup-key YOUR_SETUP_KEY_HERE
```

### Monitoring VM:
```bash
ssh VespianRex@192.168.0.207
sudo netbird up --management-url http://192.168.0.207:33073 --setup-key YOUR_SETUP_KEY_HERE
```

After connecting, all VMs will be in a secure mesh network!

---

## 🎉 You're Live!

Once router is configured, your site will be accessible at:

### Public URLs (auto SSL via Let's Encrypt):
- **https://app.andub.go.ro** - Your ClarityClear website
- **https://pb.andub.go.ro** - PocketBase admin
- **https://auth.andub.go.ro** - Authentik SSO
- **https://vpn.andub.go.ro** - Netbird dashboard
- **https://metrics.andub.go.ro** - Grafana
- **https://status.andub.go.ro** - Uptime monitoring

### Security Features Active:
- ✅ Automatic HTTPS/SSL certificates
- ✅ fail2ban protecting SSH
- ✅ Rate limiting on all endpoints
- ✅ Security headers (HSTS, XSS protection)
- ✅ Mesh VPN for secure remote access
- ✅ Centralized SSO with Authentik

---

## Troubleshooting

### Netbird not connecting?
```bash
# Check logs
ssh VespianRex@192.168.0.207 "docker logs netbird-management-1"
ssh VespianRex@192.168.0.207 "docker logs netbird-dashboard-1"

# Verify Authentik connectivity
curl http://192.168.0.207:9000/application/o/netbird/.well-known/openid-configuration
```

### SSL certificates not working?
- Wait 1-2 minutes for Let's Encrypt validation
- Check Traefik logs: `ssh VespianRex@192.168.0.192 "sudo docker logs traefik"`
- Ensure ports 80,443 are forwarded in router

### Can't access services?
- Verify router port forwarding is active
- Check DNS with: `dig app.andub.go.ro`
- Test locally first: `curl http://192.168.0.192`

---

## Next Steps (Optional):

1. **Second Edge VM** - Deploy edge-b for high availability with keepalived
2. **Monitoring Dashboards** - Import Grafana dashboards for better visibility
3. **Backup Automation** - Set up PBS automated backups
4. **NFS Storage** - Set up shared storage for edge VM state

But your site is **production-ready right now!** 🚀