# Digital Ocean Docker Marketplace Deployment Guide

This guide walks you through deploying the MITO Slovak health chatbot to a Digital Ocean Docker Marketplace droplet using Git.

## Prerequisites

- Digital Ocean Docker Marketplace droplet (pre-configured with Docker)
- GitHub repository with your code
- OpenAI API key
- SSH access to your droplet

## Quick Git-Based Deployment

### 1. Connect to Your Droplet

```bash
ssh root@209.38.249.130
# Or use your actual droplet IP
```

### 2. Clone Your Repository

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME

# Or if using private repo with SSH key
git clone git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
```

### 3. Set Up Environment Variables

```bash
# Create production environment file
cp .env.production.example .env.production

# Edit with your OpenAI API key
nano .env.production
```

Add your OpenAI API key:
```env
OPENAI_API_KEY=sk-your-openai-api-key-here
ENVIRONMENT=production
CHROMA_PERSIST_DIR=/app/chroma_db
```

### 4. Deploy with Docker Compose

```bash
# Build and start the application
docker-compose -f docker-compose.prod.yml up -d --build

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 5. Verify Deployment

```bash
# Test the application
curl http://localhost/ping

# Check if both frontend and backend are working
curl http://localhost/api/health
```

Your app will be available at: `http://209.38.249.130` (or your actual droplet IP)

## Docker Marketplace Droplet Advantages

The Docker marketplace droplet comes pre-configured with:
- ✅ Docker Engine installed
- ✅ Docker Compose installed  
- ✅ Basic firewall configured
- ✅ Automatic security updates

### 2. Connect to Your Droplet

```bash
ssh root@YOUR_DROPLET_IP
```

### 3. Install Docker and Docker Compose

```bash
# Update system
apt-get update -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker $USER

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### 4. Upload Application Files

From your local machine:

```bash
# Create deployment package
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='chroma_data' \
    --exclude='*.log' \
    --exclude='__pycache__' \
    -czf mito-deploy.tar.gz .

# Upload to server
scp mito-deploy.tar.gz root@YOUR_DROPLET_IP:/opt/
scp .env.production root@YOUR_DROPLET_IP:/opt/.env
```

### 5. Deploy Application

On the server:

```bash
# Create app directory
mkdir -p /opt/mito
cd /opt/mito

# Extract application
tar -xzf ../mito-deploy.tar.gz
mv ../.env .

# Build and start services
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

## Configuration Options

### Basic Setup (Single Container)

Uses `docker-compose.prod.yml` - serves the app directly on port 80:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Advanced Setup (with Nginx)

For better performance and SSL support:

```bash
# Start with Nginx reverse proxy
docker-compose -f docker-compose.prod.yml --profile nginx up -d
```

## Environment Variables

Create `.env.production` with:

```env
# Required
OPENAI_API_KEY=sk-your-openai-api-key-here

# Production settings
ENVIRONMENT=production
CHROMA_PERSIST_DIR=/app/chroma_db

# Optional
PORT=8000
```

## Domain and SSL Setup (Optional)

### 1. Point Domain to Droplet

Add an A record in your DNS:
```
@ -> YOUR_DROPLET_IP
www -> YOUR_DROPLET_IP
```

### 2. Install Certbot for SSL

```bash
# Install Certbot
apt-get install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
```

### 3. Update Nginx Config

Edit `nginx.conf` to:
- Update server_name to your domain
- Uncomment HTTPS server block
- Configure SSL certificate paths

## Monitoring and Maintenance

### Check Application Status

```bash
# Container status
docker-compose -f docker-compose.prod.yml ps

# Application health
curl http://YOUR_DROPLET_IP/ping

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Update Application

```bash
# On your local machine, create new deployment package
tar --exclude='node_modules' --exclude='.git' -czf mito-update.tar.gz .
scp mito-update.tar.gz root@YOUR_DROPLET_IP:/opt/mito/

# On server
cd /opt/mito
tar -xzf mito-update.tar.gz
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

### Backup Data

```bash
# Backup vector database
docker-compose -f docker-compose.prod.yml exec app tar -czf /tmp/chroma_backup.tar.gz /app/chroma_db
docker cp $(docker-compose -f docker-compose.prod.yml ps -q app):/tmp/chroma_backup.tar.gz ./chroma_backup_$(date +%Y%m%d).tar.gz
```

## Troubleshooting

### Common Issues

**1. RAG Database Not Initialized**
```bash
# Check if articles are present
docker-compose -f docker-compose.prod.yml exec app ls -la data/articles/

# Manually initialize
docker-compose -f docker-compose.prod.yml exec app python setup_rag.py
```

**2. Out of Memory**
```bash
# Check memory usage
free -h
docker stats

# Consider upgrading droplet or optimizing
```

**3. No Sources in Responses**
```bash
# Debug RAG system
curl http://YOUR_DROPLET_IP/api/debug/rag

# Test source extraction
curl -X POST http://YOUR_DROPLET_IP/api/debug/test-sources \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
```

### Performance Optimization

**1. Enable Swap** (for 1GB droplets):
```bash
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

**2. Configure Docker Logging**:
```bash
# Add to docker-compose.prod.yml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## Security Considerations

1. **Firewall**: Configure UFW to only allow necessary ports
2. **SSH**: Disable password authentication, use keys only
3. **Updates**: Keep system and Docker updated
4. **Monitoring**: Set up log monitoring and alerts
5. **Backups**: Regular automated backups of data

## Cost Estimation

**Basic Setup:**
- Droplet: $12/month (2GB RAM)
- Domain: $10-15/year (optional)
- SSL: Free with Let's Encrypt

**Total**: ~$12-15/month for production-ready deployment

## Support

For deployment issues:
1. Check application logs: `docker-compose logs`
2. Verify health endpoints: `/ping`, `/api/health`
3. Use debug endpoints: `/api/debug/rag`