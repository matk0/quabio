#!/bin/bash

# Digital Ocean Docker Deployment Script for MITO
# Usage: ./deploy.sh [server_ip] [ssh_key_path]

set -e  # Exit on any error

# Configuration
SERVER_IP="${1:-}"
SSH_KEY="${2:-~/.ssh/id_rsa}"
APP_NAME="mito"
REMOTE_DIR="/opt/$APP_NAME"
ENV_FILE=".env.production"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate inputs
if [ -z "$SERVER_IP" ]; then
    log_error "Server IP not provided"
    echo "Usage: $0 <server_ip> [ssh_key_path]"
    echo "Example: $0 192.168.1.100 ~/.ssh/id_rsa"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH key not found at $SSH_KEY"
    exit 1
fi

# Check if .env.production exists
if [ ! -f "$ENV_FILE" ]; then
    log_warn "$ENV_FILE not found. Creating template..."
    cat > "$ENV_FILE" << EOF
# Production environment variables for MITO
OPENAI_API_KEY=your_openai_api_key_here
ENVIRONMENT=production
CHROMA_PERSIST_DIR=/app/chroma_db
EOF
    log_warn "Please edit $ENV_FILE with your actual values before deploying"
    exit 1
fi

log_info "🚀 Starting deployment to $SERVER_IP"

# Create deployment package
log_info "📦 Creating deployment package..."
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='chroma_data' \
    --exclude='*.log' \
    --exclude='__pycache__' \
    --exclude='.env' \
    -czf "${APP_NAME}-deploy.tar.gz" \
    . > /dev/null

log_info "✅ Deployment package created: ${APP_NAME}-deploy.tar.gz"

# Server setup commands
SETUP_COMMANDS=$(cat << 'EOF'
# Update system
sudo apt-get update -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create application directory
sudo mkdir -p /opt/mito
sudo chown $USER:$USER /opt/mito

# Install useful tools
sudo apt-get install -y curl htop
EOF
)

# Deploy to server
log_info "🔧 Setting up server environment..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@"$SERVER_IP" "$SETUP_COMMANDS"

log_info "📤 Uploading application files..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "${APP_NAME}-deploy.tar.gz" root@"$SERVER_IP":"$REMOTE_DIR/"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$ENV_FILE" root@"$SERVER_IP":"$REMOTE_DIR/.env"

# Server deployment commands
DEPLOY_COMMANDS=$(cat << EOF
cd $REMOTE_DIR

# Extract application
tar -xzf ${APP_NAME}-deploy.tar.gz
rm ${APP_NAME}-deploy.tar.gz

# Stop existing containers
docker-compose -f docker-compose.prod.yml down || true

# Build and start application
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Wait for health check
echo "Waiting for application to start..."
for i in {1..30}; do
    if curl -f http://localhost/ping > /dev/null 2>&1; then
        echo "✅ Application is healthy!"
        break
    fi
    echo "Waiting... (\$i/30)"
    sleep 2
done

# Show status
docker-compose -f docker-compose.prod.yml ps
echo "🌐 Application deployed and running at http://$SERVER_IP"
EOF
)

log_info "🚀 Deploying application..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no root@"$SERVER_IP" "$DEPLOY_COMMANDS"

# Cleanup
rm "${APP_NAME}-deploy.tar.gz"

log_info "✅ Deployment completed successfully!"
log_info "🌐 Your MITO app is now running at: http://$SERVER_IP"
log_info "📊 Check health: http://$SERVER_IP/ping"
log_info "📋 API docs: http://$SERVER_IP/docs"

# Show next steps
echo ""
log_info "Next steps:"
echo "1. Test your application: curl http://$SERVER_IP/ping"
echo "2. Check logs: ssh -i $SSH_KEY root@$SERVER_IP 'cd $REMOTE_DIR && docker-compose -f docker-compose.prod.yml logs'"
echo "3. Monitor: ssh -i $SSH_KEY root@$SERVER_IP 'htop'"
echo "4. Set up SSL certificates and domain (optional)"