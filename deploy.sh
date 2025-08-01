#!/bin/bash

# MITO Deployment Script for DigitalOcean
# Usage: ./deploy.sh

set -e

echo "🚀 Starting MITO deployment to DigitalOcean..."

# Check if required environment variables are set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY environment variable is not set"
    echo "Please set it with: export OPENAI_API_KEY='your-api-key'"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

echo_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to wait for service to be ready
wait_for_service() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    echo_info "Waiting for $service to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo_info "$service is ready!"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: $service not ready yet..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo_error "$service failed to start within timeout"
    return 1
}

# Stop existing containers
echo_info "Stopping existing containers..."
docker-compose -f docker-compose.prod.yml down || true

# Build and start services
echo_info "Building and starting services..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for backend to be ready
wait_for_service "Backend" "http://localhost:8000/ping"

# Initialize RAG system if needed
echo_info "Checking RAG system status..."
STATS=$(curl -s http://localhost:8000/api/stats || echo '{"document_count": 0}')
DOC_COUNT=$(echo $STATS | grep -o '"document_count":[0-9]*' | cut -d: -f2 || echo "0")

if [ "$DOC_COUNT" -eq "0" ]; then
    echo_warn "RAG system not initialized. Running setup..."
    docker-compose -f docker-compose.prod.yml exec -T backend python setup_rag.py
    echo_info "RAG system initialized with documents"
else
    echo_info "RAG system already has $DOC_COUNT documents"
fi

# Get SSL certificates
echo_info "Getting SSL certificates..."
./ssl-setup.sh

echo_info "Restarting nginx with SSL..."
docker-compose -f docker-compose.prod.yml restart nginx

# Final health check
echo_info "Running final health checks..."
sleep 5

if curl -f -s "https://www.qua.bio/ping" > /dev/null; then
    echo_info "✅ HTTPS deployment successful!"
    echo_info "🌐 Your MITO chatbot is available at: https://www.qua.bio"
else
    echo_warn "HTTPS not ready yet, checking HTTP..."
    if curl -f -s "http://www.qua.bio/ping" > /dev/null; then
        echo_info "✅ HTTP deployment successful!"
        echo_warn "SSL certificate may still be processing. Check in a few minutes."
        echo_info "🌐 Your MITO chatbot is available at: http://www.qua.bio"
    else
        echo_error "Deployment verification failed"
        echo_info "Check logs with: docker-compose -f docker-compose.prod.yml logs"
        exit 1
    fi
fi

echo_info "🎉 Deployment complete!"
echo_info "📊 Monitor with: docker-compose -f docker-compose.prod.yml logs -f"