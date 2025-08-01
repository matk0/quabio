# MITO Deployment Guide

## DigitalOcean Deployment with SSL

### Prerequisites

1. **DigitalOcean Account**: Create an account at [DigitalOcean](https://digitalocean.com)
2. **Domain Setup**: Configure your domain `qua.bio` at Namecheap
3. **OpenAI API Key**: Get your API key from [OpenAI](https://platform.openai.com)

### Step 1: Create DigitalOcean Droplet

1. **Create a new Droplet:**
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Basic ($12/month minimum recommended for 2GB RAM)
   - **Region**: Choose closest to your users
   - **Authentication**: SSH Key (recommended) or Password
   - **Hostname**: `mito-chatbot`

2. **Connect to your droplet:**
   ```bash
   ssh root@your-droplet-ip
   ```

### Step 2: Install Docker and Docker Compose

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose-plugin -y

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Install additional tools
apt install curl git -y
```

### Step 3: Configure Domain DNS

1. **Login to Namecheap:**
   - Go to Domain List → Manage → Advanced DNS

2. **Add DNS Records:**
   ```
   Type: A Record
   Host: @
   Value: YOUR_DROPLET_IP
   TTL: Automatic

   Type: A Record  
   Host: www
   Value: YOUR_DROPLET_IP
   TTL: Automatic
   ```

3. **Wait for DNS propagation** (5-30 minutes)

### Step 4: Deploy MITO

1. **Clone/Upload your project:**
   ```bash
   # Option 1: If using Git
   git clone https://github.com/yourusername/mito.git
   cd mito

   # Option 2: Upload files via SCP
   scp -r /Users/matejlukasik/Learning/graphrag/mito root@your-droplet-ip:/root/
   cd /root/mito
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.production .env
   nano .env
   ```
   
   Update with your actual values:
   ```env
   OPENAI_API_KEY=sk-your-actual-openai-key
   ENVIRONMENT=production
   DOMAIN=www.qua.bio
   SSL_EMAIL=your-email@example.com
   ```

3. **Run the deployment:**
   ```bash
   export OPENAI_API_KEY=sk-your-actual-openai-key
   ./deploy.sh
   ```

   This script will:
   - Build and start all Docker containers
   - Initialize the RAG system with your articles
   - Set up SSL certificates via Let's Encrypt
   - Configure Nginx with security headers

### Step 5: Verify Deployment

1. **Check services are running:**
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   ```

2. **Test the application:**
   ```bash
   # Test HTTP redirect
   curl -I http://www.qua.bio
   
   # Test HTTPS
   curl -I https://www.qua.bio
   
   # Test API
   curl https://www.qua.bio/api/health
   ```

3. **View logs if needed:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs -f
   ```

### Step 6: Post-Deployment

1. **Set up automatic SSL renewal:**
   ```bash
   crontab -e
   # Add this line:
   0 12 * * * /usr/bin/docker-compose -f /root/mito/docker-compose.prod.yml exec certbot certbot renew --quiet
   ```

2. **Configure firewall:**
   ```bash
   ufw allow 22    # SSH
   ufw allow 80    # HTTP
   ufw allow 443   # HTTPS
   ufw enable
   ```

3. **Set up monitoring (optional):**
   ```bash
   # Install htop for system monitoring
   apt install htop -y
   
   # Check Docker stats
   docker stats
   ```

## Troubleshooting

### Common Issues

1. **SSL Certificate Failed:**
   ```bash
   # Check if domain points to your server
   nslookup www.qua.bio
   
   # Manually run certbot
   ./ssl-setup.sh
   ```

2. **Backend Not Starting:**
   ```bash
   # Check backend logs
   docker-compose -f docker-compose.prod.yml logs backend
   
   # Verify OpenAI API key
   echo $OPENAI_API_KEY
   ```

3. **Frontend Not Loading:**
   ```bash
   # Check nginx logs
   docker-compose -f docker-compose.prod.yml logs nginx
   
   # Verify containers are running
   docker ps
   ```

4. **RAG System Empty:**
   ```bash
   # Reinitialize RAG system
   docker-compose -f docker-compose.prod.yml exec backend python setup_rag.py
   ```

## Updating the Application

```bash
# Pull latest changes
git pull origin main

# Rebuild and redeploy
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

## Monitoring and Maintenance

1. **Check disk space:**
   ```bash
   df -h
   ```

2. **Monitor Docker containers:**
   ```bash
   docker system df
   docker system prune  # Clean up unused images
   ```

3. **View application logs:**
   ```bash
   docker-compose -f docker-compose.prod.yml logs -f --tail=100
   ```

## Security Notes

- SSL certificates auto-renew every 12 hours via cron
- Rate limiting is configured (10 requests/minute per IP)
- Security headers are set in Nginx
- Firewall blocks all ports except SSH, HTTP, and HTTPS
- Use strong passwords and SSH keys

## Support

For issues, check:
1. Docker logs: `docker-compose -f docker-compose.prod.yml logs`
2. System resources: `htop`
3. DNS resolution: `nslookup www.qua.bio`
4. SSL status: `curl -I https://www.qua.bio`