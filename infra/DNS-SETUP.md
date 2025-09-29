# DNS Configuration for andub.go.ro

## Required DNS Records

Add these DNS records to your domain provider for **andub.go.ro**:

### A Records (IPv4)
```
Type  | Name    | Value          | TTL
------|---------|----------------|------
A     | @       | 86.121.4.16    | 300
A     | *       | 86.121.4.16    | 300
A     | app     | 86.121.4.16    | 300
A     | pb      | 86.121.4.16    | 300
A     | metrics | 86.121.4.16    | 300
A     | status  | 86.121.4.16    | 300
A     | vpn     | 86.121.4.16    | 300
```

### AAAA Records (IPv6) - Optional
```
Type  | Name    | Value                                | TTL
------|---------|--------------------------------------|------
AAAA  | @       | 2a02:2f00:4302:ea00:d485:873b:13d2:b5fc | 300
AAAA  | *       | 2a02:2f00:4302:ea00:d485:873b:13d2:b5fc | 300
```

## Router Port Forwarding

Configure your router to forward these ports to the VIP (192.168.0.51):

| External Port | Internal IP    | Internal Port | Protocol | Service    |
|--------------|----------------|---------------|----------|------------|
| 80           | 192.168.0.51   | 80           | TCP      | HTTP       |
| 443          | 192.168.0.51   | 443          | TCP      | HTTPS      |
| 51820        | 192.168.0.51   | 51820        | UDP      | AmneziaVPN |

## Verification

After setting up DNS, verify with:

```bash
# Check DNS resolution
nslookup app.andub.go.ro
nslookup pb.andub.go.ro

# Check if records are propagated
dig +short app.andub.go.ro
dig +short pb.andub.go.ro

# Test connectivity (after deployment)
curl -I https://app.andub.go.ro
```

## Common DNS Providers

### Cloudflare
1. Log in to Cloudflare Dashboard
2. Select your domain
3. Go to DNS tab
4. Add the records above
5. Set Proxy status to "DNS only" (grey cloud) initially

### GoDaddy
1. Log in to GoDaddy
2. Go to Domain Management
3. Click DNS for andub.go.ro
4. Add the A records

### Namecheap
1. Log in to Namecheap
2. Go to Domain List
3. Click Manage next to andub.go.ro
4. Go to Advanced DNS
5. Add the Host Records

## Notes

- TTL of 300 (5 minutes) allows quick changes during setup
- After everything works, you can increase TTL to 3600 (1 hour)
- The wildcard (*) record covers all subdomains not explicitly defined
- Make sure your ISP doesn't block ports 80/443 (some residential ISPs do)