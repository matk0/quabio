#!/bin/bash

# FastAPI Backend Deployment Script
# Usage: ./deploy-backend.sh

set -e

echo "🚀 Starting FastAPI Backend deployment..."

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
docker-compose -f docker-compose.backend.yml down || true

# Build and start services
echo_info "Building and starting FastAPI backend..."
docker-compose -f docker-compose.backend.yml up -d --build

# Wait for backend to be ready
wait_for_service "FastAPI Backend" "http://localhost:8000/api/health"

# Initialize RAG system if needed
echo_info "Checking RAG system status..."
STATS=$(curl -s http://localhost:8000/api/stats || echo '{"documents_count": 0}')
DOC_COUNT=$(echo $STATS | grep -o '"documents_count":[0-9]*' | cut -d: -f2 || echo "0")

if [ "$DOC_COUNT" -eq "0" ]; then
    echo_warn "RAG system not initialized. Running setup..."
    docker-compose -f docker-compose.backend.yml exec -T backend python setup_rag.py --variant both
    echo_info "RAG system initialized with documents"
else
    echo_info "RAG system already has $DOC_COUNT documents"
fi

# Final health check
echo_info "Running final health checks..."
sleep 5

if curl -f -s "http://localhost:8000/api/health" > /dev/null; then
    echo_info "✅ Backend deployment successful!"
    echo_info "🌐 FastAPI backend is available at: http://localhost:8000"
    echo_info "📊 API Stats: http://localhost:8000/api/stats"
    echo_info "🏥 Health Check: http://localhost:8000/api/health"
else
    echo_error "Deployment verification failed"
    echo_info "Check logs with: docker-compose -f docker-compose.backend.yml logs"
    exit 1
fi

echo_info "🎉 Backend deployment complete!"
echo_info "📊 Monitor with: docker-compose -f docker-compose.backend.yml logs -f"
echo_info ""
echo_info "Useful commands:"
echo_info "  • View logs: docker-compose -f docker-compose.backend.yml logs -f"
echo_info "  • Stop: docker-compose -f docker-compose.backend.yml down"
echo_info "  • Restart: docker-compose -f docker-compose.backend.yml restart"
echo_info "  • Shell access: docker-compose -f docker-compose.backend.yml exec backend bash"