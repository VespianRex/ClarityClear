# PocketBase Setup Instructions

## Quick Start

1. **Download PocketBase**:
   ```bash
   # Download PocketBase for your platform
   wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.0/pocketbase_0.22.0_linux_amd64.zip
   unzip pocketbase_0.22.0_linux_amd64.zip
   chmod +x pocketbase
   ```

2. **Start PocketBase**:
   ```bash
   ./pocketbase serve
   ```
   
3. **Setup Collections**:
   ```bash
   npm run setup:pocketbase
   ```

4. **Start Development**:
   ```bash
   npm run dev
   ```

## Next Steps
- Access PocketBase admin at http://localhost:8090/_/
- Configure your .env.local file
- Run the setup script to create collections

