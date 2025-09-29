#!/bin/bash

echo "Checking ClarityClear Services Status"
echo "======================================"

# First, let's find the actual IP addresses of the VMs
echo -e "\n1. Scanning for VM IPs..."

# Scan common DHCP range
for i in {100..250}; do
    ip="192.168.0.$i"
    if ping -c 1 -W 0.2 "$ip" &> /dev/null; then
        # Try to identify the VM by SSH banner
        banner=$(echo "" | nc -w 1 "$ip" 22 2>/dev/null | head -1)
        if [[ "$banner" == *"SSH"* ]] || [[ "$banner" == *"OpenSSH"* ]]; then
            echo "  Found VM at: $ip"

            # Check web services
            if nc -zv -w1 "$ip" 80 &>/dev/null; then
                echo "    ✓ Port 80 (HTTP) open"
            fi
            if nc -zv -w1 "$ip" 443 &>/dev/null; then
                echo "    ✓ Port 443 (HTTPS) open"
            fi
            if nc -zv -w1 "$ip" 3000 &>/dev/null; then
                echo "    ✓ Port 3000 (App/Grafana) open"
            fi
            if nc -zv -w1 "$ip" 8090 &>/dev/null; then
                echo "    ✓ Port 8090 (PocketBase) open"
            fi
            if nc -zv -w1 "$ip" 9090 &>/dev/null; then
                echo "    ✓ Port 9090 (Prometheus) open"
            fi
        fi
    fi
done

echo -e "\n2. Testing known service endpoints..."

# Check VIP
echo -e "\nVirtual IP (192.168.0.50):"
if ping -c 1 -W 1 192.168.0.50 &> /dev/null; then
    echo "  ✓ VIP is responsive"
else
    echo "  ✗ VIP not responding"
fi

# Check domain
echo -e "\nDomain (andub.go.ro):"
host andub.go.ro 2>/dev/null | head -2

echo -e "\n3. Testing public IP NAT..."
echo "Public IP: 86.121.4.16"
curl -s --max-time 3 http://86.121.4.16 &>/dev/null && echo "  ✓ Port 80 accessible" || echo "  ✗ Port 80 not accessible"
curl -s --max-time 3 https://86.121.4.16 &>/dev/null && echo "  ✓ Port 443 accessible" || echo "  ✗ Port 443 not accessible"