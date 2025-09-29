#!/bin/bash

# Test if we can connect to Proxmox API directly

echo "Testing Proxmox API connection..."

# Test authentication
RESPONSE=$(curl -k -s -o /dev/null -w "%{http_code}" -X POST \
  "https://192.168.0.33:8006/api2/json/access/ticket" \
  -d "username=root@pam&password=sonicx555")

if [ "$RESPONSE" = "200" ]; then
  echo "✓ Authentication successful"
else
  echo "✗ Authentication failed with code: $RESPONSE"
  exit 1
fi

# Get ticket for further API calls
AUTH_DATA=$(curl -k -s -X POST \
  "https://192.168.0.33:8006/api2/json/access/ticket" \
  -d "username=root@pam&password=sonicx555")

TICKET=$(echo "$AUTH_DATA" | python3 -c "import sys, json; d = json.load(sys.stdin); print(d['data']['ticket'])" 2>/dev/null)

if [ -z "$TICKET" ]; then
  echo "✗ Failed to get authentication ticket"
  exit 1
fi

echo "✓ Got authentication ticket"

# Check permissions
echo ""
echo "Checking user permissions..."
PERMS=$(curl -k -s "https://192.168.0.33:8006/api2/json/access/permissions" \
  -H "Cookie: PVEAuthCookie=$TICKET" | python3 -m json.tool 2>/dev/null | head -50)

if [ $? -eq 0 ]; then
  echo "✓ Can access permissions API"
else
  echo "✗ Cannot access permissions API"
fi

# Check nodes
echo ""
echo "Checking nodes..."
NODES=$(curl -k -s "https://192.168.0.33:8006/api2/json/nodes" \
  -H "Cookie: PVEAuthCookie=$TICKET")

if echo "$NODES" | grep -q "pve"; then
  echo "✓ Node 'pve' found"
else
  echo "✗ Node 'pve' not found"
fi

# Check storage
echo ""
echo "Checking storage..."
STORAGE=$(curl -k -s "https://192.168.0.33:8006/api2/json/nodes/pve/storage" \
  -H "Cookie: PVEAuthCookie=$TICKET")

if echo "$STORAGE" | grep -q "local-lvm"; then
  echo "✓ Storage 'local-lvm' found"
else
  echo "✗ Storage 'local-lvm' not found"
fi

# Check VMs
echo ""
echo "Checking existing VMs and templates..."
VMS=$(curl -k -s "https://192.168.0.33:8006/api2/json/nodes/pve/qemu" \
  -H "Cookie: PVEAuthCookie=$TICKET")

echo "$VMS" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'data' in data:
        vms = data['data']
        print(f'Found {len(vms)} VMs/templates:')
        for vm in vms:
            vmid = vm.get('vmid', 'unknown')
            name = vm.get('name', 'unnamed')
            template = vm.get('template', 0)
            status = vm.get('status', 'unknown')
            vm_type = 'template' if template else 'vm'
            print(f'  - {vmid}: {name} ({vm_type}, status: {status})')
    else:
        print('No VMs found')
except:
    print('Error parsing VM data')
"

echo ""
echo "API connectivity test complete!"