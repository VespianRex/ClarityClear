# ClarityClear Security Guide - DDNS Home Hosting

## ⚠️ Critical Security Warning

**Home hosting with DDNS has significant security risks:**
- Your home IP address is publicly exposed
- Direct attacks can target your home network
- No enterprise-grade DDoS protection
- Potential ISP Terms of Service violations

**Strongly consider Cloudflare Tunnel instead for production use.**

## Architecture Overview

```
Internet → Router (Port Forward 80/443) → Ubuntu/WSL2 Host
                                               ↓
                                          Caddy (Reverse Proxy)
                                               ↓
                                    Docker Network (Isolated)
                                          ↙         ↘
                                    Next.js      PocketBase
```

## Security Layers Implemented

### 1. Network Security
- **UFW Firewall**: Only ports 22 (SSH), 80 (HTTP), 443 (HTTPS) open
- **Docker Network Isolation**: Backend services on internal-only network
- **No Direct Database Access**: PocketBase only accessible internally

### 2. Application Security
- **Caddy Reverse Proxy**: 
  - Automatic HTTPS with Let's Encrypt
  - Security headers (HSTS, CSP, X-Frame-Options, etc.)
  - Rate limiting (60 requests/minute per IP)
  - Bot/crawler blocking
  - Path-based attack blocking

### 3. Container Security
- **Non-root users**: All containers run as non-privileged users
- **Read-only filesystems**: Containers use read-only root filesystems
- **Capability dropping**: Minimal Linux capabilities
- **Resource limits**: CPU and memory limits enforced
- **Security options**: no-new-privileges enabled

### 4. Intrusion Prevention
- **Fail2ban**: Automatic IP banning for:
  - Excessive 404 attempts (30 in 10 minutes)
  - HTTP errors (5 in 10 minutes)
  - Rate limit violations (100 requests/minute)
- **Kernel hardening**: SYN cookies, IP spoofing protection

### 5. Monitoring & Logging
- **Centralized logging**: JSON format with rotation
- **Health checks**: Automatic container restart on failure
- **Monitoring script**: Regular service status checks
- **Backup automation**: Daily backups at 3 AM

## Quick Start

### 1. Initial Setup (Run as root/sudo)
```bash
sudo bash security-setup.sh
```

### 2. Configure Environment
Edit `.env.production`:
```bash
# Update with your actual values
NEXT_PUBLIC_WHATSAPP_PHONE_NUMBER=your_phone
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

### 3. Configure DDNS
Edit `ddns-updater.sh`:
```bash
DDNS_USERNAME="your_username"
DDNS_PASSWORD="your_password"
UPDATE_URL="your_provider_update_url"
```

### 4. Deploy
```bash
bash deploy-secure.sh
```

### 5. Set Up Automated Tasks
```bash
# Add to crontab
crontab -e

# Add these lines:
*/5 * * * * /home/alexa/DEV/ClarityClear/ClarityClear/ddns-updater.sh
0 3 * * * /home/alexa/DEV/ClarityClear/ClarityClear/backup.sh
*/30 * * * * /home/alexa/DEV/ClarityClear/ClarityClear/monitor.sh
```

### 6. Router Configuration
1. Log into your router admin panel
2. Set up port forwarding:
   - External Port 80 → Internal Port 80 (Your machine's IP)
   - External Port 443 → Internal Port 443 (Your machine's IP)
3. Consider setting a static internal IP for this machine

## Security Best Practices

### Daily Operations
1. **Monitor logs regularly**:
   ```bash
   docker-compose -f docker-compose.secure.yml logs -f
   ```

2. **Check banned IPs**:
   ```bash
   docker exec fail2ban fail2ban-client status
   ```

3. **Review access logs**:
   ```bash
   tail -f logs/access.log | jq '.'
   ```

### Weekly Maintenance
1. **Update system packages**:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

2. **Update Docker images**:
   ```bash
   docker-compose -f docker-compose.secure.yml pull
   docker-compose -f docker-compose.secure.yml up -d
   ```

3. **Check disk usage**:
   ```bash
   df -h
   docker system prune -a
   ```

### Security Hardening Checklist

#### Network Level
- [ ] Router firewall enabled
- [ ] Only necessary ports forwarded (80, 443)
- [ ] UPnP disabled on router
- [ ] WPS disabled on router
- [ ] Strong WiFi password (WPA3 if available)
- [ ] Guest network isolated from main network

#### System Level
- [ ] UFW firewall active
- [ ] Fail2ban running
- [ ] SSH key authentication only (no passwords)
- [ ] Regular security updates installed
- [ ] Kernel parameters hardened

#### Application Level
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Rate limiting active
- [ ] Bot protection enabled
- [ ] Database not publicly accessible
- [ ] Secrets properly managed

#### Monitoring
- [ ] Log rotation configured
- [ ] Backup automation running
- [ ] Health checks active
- [ ] Monitoring alerts set up

## Common Issues & Solutions

### Issue: Services not starting
```bash
# Check logs
docker-compose -f docker-compose.secure.yml logs [service_name]

# Restart services
docker-compose -f docker-compose.secure.yml restart
```

### Issue: HTTPS not working
```bash
# Check Caddy logs
docker logs caddy

# Verify DNS is pointing to your IP
nslookup andub.go.ro
```

### Issue: High number of attacks
```bash
# Check Fail2ban status
docker exec fail2ban fail2ban-client status caddy-status

# Manually ban an IP
docker exec fail2ban fail2ban-client set caddy-status banip [IP_ADDRESS]
```

### Issue: Running out of disk space
```bash
# Clean Docker resources
docker system prune -a --volumes

# Check log sizes
du -sh logs/*

# Rotate logs manually if needed
logrotate -f /etc/logrotate.d/caddy
```

## Emergency Procedures

### Under Attack
1. **Immediate response**:
   ```bash
   # Block all traffic except SSH
   sudo ufw default deny incoming
   sudo ufw reload
   ```

2. **Analyze attack**:
   ```bash
   # Check recent logs
   tail -n 1000 logs/access.log | jq '.remote_addr' | sort | uniq -c | sort -rn
   ```

3. **Mitigate**:
   ```bash
   # Ban attacking IPs
   docker exec fail2ban fail2ban-client set caddy-status banip [IP]
   ```

### Data Breach Suspected
1. **Isolate immediately**:
   ```bash
   docker-compose -f docker-compose.secure.yml down
   ```

2. **Preserve evidence**:
   ```bash
   # Create forensic backup
   tar -czf incident_$(date +%Y%m%d).tar.gz logs/ pb_data/
   ```

3. **Reset credentials**:
   - Change all passwords
   - Regenerate API keys
   - Review access logs

## Alternative: Cloudflare Tunnel (Recommended)

For better security, consider switching to Cloudflare Tunnel:

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create clarityclear

# Configure and run
cloudflared tunnel route dns clarityclear andub.go.ro
cloudflared tunnel run clarityclear
```

Benefits:
- No exposed IP or ports
- Built-in DDoS protection
- Zero attack surface
- Free tier available

## Support & Resources

- **Docker Security**: https://docs.docker.com/engine/security/
- **Caddy Documentation**: https://caddyserver.com/docs/
- **Fail2ban Wiki**: https://www.fail2ban.org/wiki/
- **UFW Guide**: https://ubuntu.com/server/docs/security-firewall

## Final Notes

Remember: **Security is a continuous process, not a one-time setup.**

- Regular updates are critical
- Monitor logs daily
- Test backups regularly
- Consider professional hosting for production
- Have an incident response plan

Stay safe and monitor actively!