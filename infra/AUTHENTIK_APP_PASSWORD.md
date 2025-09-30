# Create Authentik App Password for Netbird

Netbird management needs an **App Password** (not the regular password) for the service account.

## Steps:

1. **Login to Authentik**: http://192.168.0.207:9000

2. **Go to Directory** → **Tokens & App passwords**

3. **Click "Create"** → Select **"App password"**

4. **Configure**:
   - **User**: Select `netbird-service`
   - **Description**: `Netbird Management API Access`
   - **Expires**: Never (or set expiry date)

5. **Click "Create"**

6. **COPY THE APP PASSWORD** - It will look like: `akp_xxx...`

7. **Run this command** (replace `YOUR_APP_PASSWORD` with the copied password):

```bash
ssh VespianRex@192.168.0.207 << 'ENDSSH'
cd /opt/netbird

# Update management.json with the app password
sudo tee management.json > /dev/null << 'EOF'
{
  "Stuns": [
    {"Proto": "udp", "URI": "stun:192.168.0.207:3478"}
  ],
  "TURNConfig": {
    "Turns": [
      {"Proto": "udp", "URI": "turn:192.168.0.207:3478", "Username": "netbird", "Password": "netbird123"}
    ]
  },
  "Signal": {"Proto": "http", "URI": "192.168.0.207:10000"},
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
      "Password": "YOUR_APP_PASSWORD_HERE",
      "GrantType": "password"
    }
  }
}
EOF

# Restart management
sudo docker compose restart management
sudo docker logs netbird-management-1 --tail 20

ENDSSH
```

8. **Verify it's running**:
```bash
ssh VespianRex@192.168.0.207 "docker compose -f /opt/netbird/docker-compose.yml ps | grep management"
```

You should see: `Up` instead of `Restarting`

9. **Access Netbird Dashboard**: http://192.168.0.207:8085
   - It will redirect to Authentik
   - Login with your Authentik admin account
   - You're in!

10. **Create Setup Key** in Netbird dashboard to connect your VMs