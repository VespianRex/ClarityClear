#!/bin/bash

# Start servers for ClarityClear accessible via Tailscale

echo "Starting ClarityClear servers..."

# Kill existing processes
pkill -f "pocketbase serve"
pkill -f "next dev"

# Start PocketBase on all interfaces
echo "Starting PocketBase on 0.0.0.0:8090..."
./pocketbase serve --http=0.0.0.0:8090 > pocketbase.log 2>&1 &

# Wait for PocketBase to start
sleep 2

# Start Next.js dev server on all interfaces
echo "Starting Next.js on 0.0.0.0:9002..."
npm run dev &

echo ""
echo "Servers started!"
echo "Access via Tailscale IP (100.73.114.121):"
echo "  - Next.js: http://100.73.114.121:9002"
echo "  - PocketBase Admin: http://100.73.114.121:8090/_/"
echo ""
echo "Or locally:"
echo "  - Next.js: http://localhost:9002"
echo "  - PocketBase Admin: http://localhost:8090/_/"