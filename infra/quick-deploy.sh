#!/bin/bash
set -euo pipefail

echo "Quick Deploy - Getting ClarityClear Online"
echo "=========================================="

APP_IP="192.168.0.180"

echo "1. Installing Node.js and creating basic app..."

ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@$APP_IP << 'ENDSSH'
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Create simple app directory
mkdir -p /opt/clarity/app
cd /opt/clarity/app

# Create a simple Next.js app
cat > package.json << 'EOF'
{
  "name": "clarity-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start -p 3000"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18",
    "react-dom": "^18"
  }
}
EOF

# Create pages directory
mkdir -p pages

# Create index page
cat > pages/index.js << 'EOF'
export default function Home() {
  return (
    <div style={{ padding: '50px', fontFamily: 'Arial' }}>
      <h1>Welcome to ClarityClear</h1>
      <p>Your site is now online!</p>
      <p>Services:</p>
      <ul>
        <li>Application: Running on port 3000</li>
        <li>PocketBase: Running on port 8090</li>
        <li>Redis: Running on port 6379</li>
      </ul>
    </div>
  )
}
EOF

# Install dependencies
npm install

# Build the app
npm run build

ENDSSH

echo ""
echo "2. Creating systemd service for Next.js..."

ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@$APP_IP << 'ENDSSH'
sudo tee /etc/systemd/system/clarity-app.service > /dev/null << 'EOF'
[Unit]
Description=ClarityClear Next.js App
After=network.target

[Service]
Type=simple
User=VespianRex
WorkingDirectory=/opt/clarity/app
ExecStart=/usr/bin/npm start
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable clarity-app
sudo systemctl restart clarity-app

ENDSSH

echo ""
echo "3. Starting Docker services (PocketBase & Redis)..."

ssh -i ~/.ssh/id_ed25519_clarity -o StrictHostKeyChecking=no VespianRex@$APP_IP << 'ENDSSH'
cd /opt/clarity

# Restart Docker to ensure it's working
sudo systemctl restart docker

# Start services
docker-compose up -d

# Check status
docker ps
ENDSSH

echo ""
echo "4. Checking services..."
sleep 5

echo "  Testing Next.js..."
curl -s -o /dev/null -w "    HTTP Status: %{http_code}\n" http://$APP_IP:3000 || echo "    Service starting..."

echo "  Testing PocketBase..."
curl -s -o /dev/null -w "    HTTP Status: %{http_code}\n" http://$APP_IP:8090/_/ || echo "    Service starting..."

echo ""
echo "====================================="
echo "Deployment Complete!"
echo "====================================="
echo ""
echo "Access your site at:"
echo "  - http://$APP_IP:3000 (Next.js App)"
echo "  - http://$APP_IP:8090/_/ (PocketBase Admin)"
echo ""
echo "To access from the internet:"
echo "  1. Configure your router to forward ports 80/443 to your edge VMs"
echo "  2. Update DNS for andub.go.ro to point to 86.121.4.16"
echo "  3. The edge load balancer will handle SSL and routing"