#!/bin/bash

# Git-based deployment script for Digital Ocean Docker Marketplace droplet
# Usage: ./deploy-git.sh [droplet_ip]

set -e

# Configuration
DROPLET_IP="${1:-209.38.249.130}"
APP_DIR="/opt/mito"
REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"  # Update this

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "🚀 Starting Git-based deployment to $DROPLET_IP"

# Check if .env.production exists locally
if [ ! -f ".env.production" ]; then
    log_warn ".env.production not found locally"
    log_info "Please create .env.production with your OpenAI API key before deploying"
    exit 1
fi

# Create deployment commands
DEPLOY_COMMANDS=$(cat << 'EOF'
# Create app directory
mkdir -p /opt/mito
cd /opt/mito

# Clone or update repository
if [ -d ".git" ]; then
    echo "📥 Updating existing repository..."
    git pull origin main
else
    echo "📥 Cloning repository..."
    # You'll need to replace this with your actual repo URL
    git clone REPO_URL_PLACEHOLDER .
fi

# Stop existing containers if running
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Build and start application
echo "🔨 Building application..."
docker-compose -f docker-compose.prod.yml build --no-cache

echo "🚀 Starting application..."
docker-compose -f docker-compose.prod.yml up -d

# Wait for application to be ready
echo "⏳ Waiting for application to start..."
for i in {1..30}; do
    if curl -f http://localhost/ping > /dev/null 2>&1; then
        echo "✅ Application is running!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# Show status
echo "📊 Container status:"
docker-compose -f docker-compose.prod.yml ps

echo "🌐 Application deployed at: http://DROPLET_IP_PLACEHOLDER"
EOF
)

# Replace placeholders in deployment commands
DEPLOY_COMMANDS="${DEPLOY_COMMANDS//REPO_URL_PLACEHOLDER/$REPO_URL}"
DEPLOY_COMMANDS="${DEPLOY_COMMANDS//DROPLET_IP_PLACEHOLDER/$DROPLET_IP}"

log_info "📤 Uploading environment file..."
scp -o StrictHostKeyChecking=no .env.production root@$DROPLET_IP:/opt/mito/.env.production

log_info "🚀 Executing deployment on droplet..."
ssh -o StrictHostKeyChecking=no root@$DROPLET_IP "$DEPLOY_COMMANDS"

log_info "✅ Deployment completed!"
log_info "🌐 Your MITO app should be running at: http://$DROPLET_IP"
log_info "🔍 Check health: curl http://$DROPLET_IP/ping"

echo ""
log_info "Next steps:"
echo "1. Test your application: curl http://$DROPLET_IP/api/health"
echo "2. Check logs: ssh root@$DROPLET_IP 'cd /opt/mito && docker-compose -f docker-compose.prod.yml logs'"
echo "3. Monitor: ssh root@$DROPLET_IP 'docker stats'"