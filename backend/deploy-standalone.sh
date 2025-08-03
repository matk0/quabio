#!/bin/bash

# FastAPI Backend Standalone Deployment Script
# For DigitalOcean Droplet deployment at api.qua.bio

set -e  # Exit on any error

echo "🧬 Starting FastAPI Backend deployment for api.qua.bio"

# Configuration
CONTAINER_NAME="qua-bio-backend"
COMPOSE_FILE="docker-compose.standalone.yml"
ENV_FILE=".env.production"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file $ENV_FILE not found!"
    print_warning "Please copy .env.production.example to .env.production and configure it"
    exit 1
fi

# Check if OPENAI_API_KEY is set
if ! grep -q "OPENAI_API_KEY=sk-" "$ENV_FILE"; then
    print_error "OPENAI_API_KEY not properly configured in $ENV_FILE"
    print_warning "Please set your OpenAI API key in $ENV_FILE"
    exit 1
fi

print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed"
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Load environment variables
print_status "Loading environment variables..."
set -a  # automatically export all variables
source "$ENV_FILE"
set +a

# Stop existing container if running
print_status "Stopping existing containers..."
docker-compose -f "$COMPOSE_FILE" down || true

# Remove old images to force rebuild
print_status "Cleaning up old images..."
docker image prune -f --filter "label=qua-bio-backend" || true

# Build and start the service
print_status "Building and starting FastAPI backend..."
docker-compose -f "$COMPOSE_FILE" build --no-cache
docker-compose -f "$COMPOSE_FILE" up -d

# Wait for service to be healthy
print_status "Waiting for service to be healthy..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
        break
    fi
    print_status "Waiting for health check... ($elapsed/$timeout seconds)"
    sleep 5
    elapsed=$((elapsed + 5))
done

# Check if container is running
if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    print_success "Container is running!"
else
    print_error "Container failed to start"
    print_status "Container logs:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=50
    exit 1
fi

# Test health endpoint
print_status "Testing health endpoint..."
sleep 5  # Give service time to fully start

if curl -f -s http://localhost:8000/api/health > /dev/null; then
    print_success "Health check passed!"
else
    print_warning "Health check failed, but container is running. Check logs."
fi

# Test RAG initialization
print_status "Checking RAG system initialization..."
if curl -f -s http://localhost:8000/api/debug/rag > /dev/null; then
    rag_status=$(curl -s http://localhost:8000/api/debug/rag | grep -o '"document_count":[0-9]*' | cut -d':' -f2 || echo "0")
    if [ "$rag_status" -gt 0 ]; then
        print_success "RAG system initialized with $rag_status documents"
    else
        print_warning "RAG system has 0 documents. Initialize with:"
        print_warning "docker-compose -f $COMPOSE_FILE exec fastapi-backend python setup_rag.py"
    fi
else
    print_warning "Could not check RAG status"
fi

# Display status
print_status "Deployment summary:"
echo "📊 Container Status:"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo "🔗 Service URLs:"
echo "   Health Check: http://localhost:8000/api/health"
echo "   API Docs:     http://localhost:8000/docs"
echo "   Debug Info:   http://localhost:8000/api/debug/rag"

echo ""
echo "📋 Useful Commands:"
echo "   View logs:    docker-compose -f $COMPOSE_FILE logs -f"
echo "   Stop service: docker-compose -f $COMPOSE_FILE down"
echo "   Restart:      docker-compose -f $COMPOSE_FILE restart"
echo "   Shell access: docker-compose -f $COMPOSE_FILE exec fastapi-backend bash"

echo ""
print_success "🚀 FastAPI Backend deployment completed!"
print_status "Configure your domain (api.qua.bio) to point to this server"
print_status "Set up SSL/TLS certificate for production use"