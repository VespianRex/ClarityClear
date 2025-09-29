#!/bin/bash
set -euo pipefail

echo "ClarityClear App Deployment"
echo "==========================="

# Create inventory file with discovered IPs
cat > /tmp/inventory.yml << EOF
all:
  hosts:
    clarity-app:
      ansible_host: 192.168.0.180
      ansible_user: VespianRex
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519_clarity
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF

echo "1. Installing Docker on app VM..."
ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@192.168.0.180 << 'ENDSSH'
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installed successfully"
ENDSSH

echo ""
echo "2. Creating application directories..."
ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@192.168.0.180 << 'ENDSSH'
sudo mkdir -p /opt/clarity/{app,data,backups}
sudo chown -R VespianRex:VespianRex /opt/clarity
ENDSSH

echo ""
echo "3. Deploying Next.js application..."

# Create docker-compose file for the app
cat > /tmp/docker-compose.yml << 'EOF'
version: '3.8'

services:
  nextjs:
    image: node:20-alpine
    working_dir: /app
    volumes:
      - ./app:/app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - NEXT_PUBLIC_API_URL=http://192.168.0.180:8090
    command: sh -c "npm install && npm run build && npm start"
    restart: unless-stopped

  pocketbase:
    image: ghcr.io/muchobien/pocketbase:latest
    ports:
      - "8090:8090"
    volumes:
      - ./data/pb_data:/pb_data
      - ./data/pb_migrations:/pb_migrations
    environment:
      - PB_ENCRYPTION_KEY=YOUR_ENCRYPTION_KEY_HERE
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - ./data/redis:/data
    command: redis-server --appendonly yes
    restart: unless-stopped
EOF

# Copy docker-compose file
scp -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no /tmp/docker-compose.yml VespianRex@192.168.0.180:/opt/clarity/

echo ""
echo "4. Copying application code..."

# Check if we have the app code
if [ -d "../app" ]; then
    echo "Found app directory, copying..."
    scp -r -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no ../app VespianRex@192.168.0.180:/opt/clarity/
else
    echo "Creating sample Next.js app..."
    ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@192.168.0.180 << 'ENDSSH'
cd /opt/clarity
npx create-next-app@latest app --typescript --tailwind --no-app --no-src-dir --import-alias "@/*"
ENDSSH
fi

echo ""
echo "5. Starting services..."
ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@192.168.0.180 << 'ENDSSH'
cd /opt/clarity
docker-compose up -d
echo "Waiting for services to start..."
sleep 10
docker-compose ps
ENDSSH

echo ""
echo "6. Testing services..."
echo "  Next.js: http://192.168.0.180:3000"
curl -s -o /dev/null -w "    Status: %{http_code}\n" http://192.168.0.180:3000 || echo "    Not ready yet"

echo "  PocketBase: http://192.168.0.180:8090"
curl -s -o /dev/null -w "    Status: %{http_code}\n" http://192.168.0.180:8090/_/ || echo "    Not ready yet"

echo ""
echo "Deployment complete!"
echo ""
echo "Access your application at:"
echo "  - Local: http://192.168.0.180:3000"
echo "  - Domain: https://andub.go.ro (configure DNS and edge proxy)"
echo ""
echo "PocketBase Admin:"
echo "  - http://192.168.0.180:8090/_/"