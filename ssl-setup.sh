#!/bin/bash

# SSL Certificate Setup Script for Let's Encrypt
set -e

DOMAIN="www.qua.bio"
EMAIL="admin@qua.bio"  # Change this to your email

echo "🔒 Setting up SSL certificates for $DOMAIN..."

# Create temporary nginx config for initial certificate request
cat > nginx/nginx-temp.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name www.qua.bio qua.bio;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 200 "Server is ready for SSL setup";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Start nginx with temporary config
echo "Starting nginx for certificate generation..."
docker run --rm -d \
    --name nginx-temp \
    -p 80:80 \
    -v $(pwd)/nginx/nginx-temp.conf:/etc/nginx/nginx.conf:ro \
    -v certbot_data:/var/www/certbot \
    nginx:alpine

# Wait for nginx to start
sleep 5

# Get SSL certificate
echo "Requesting SSL certificate from Let's Encrypt..."
docker run --rm \
    -v certbot_data:/var/www/certbot \
    -v ssl_certs:/etc/letsencrypt \
    certbot/certbot \
    certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d qua.bio

# Stop temporary nginx
docker stop nginx-temp

echo "✅ SSL certificates obtained successfully!"
echo "Certificates are stored in the ssl_certs volume"