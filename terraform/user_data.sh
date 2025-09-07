#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get install -y docker.io curl jq

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/2.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Backup old Docker data
if [ -d "/var/lib/docker" ]; then
  mv /var/lib/docker /var/lib/docker.bak
fi

# Format and mount EBS
mkfs -t ext4 /dev/sdh
mkdir -p /var/lib/docker
mount /dev/sdh /var/lib/docker

# Restore backup
if [ -d "/var/lib/docker.bak" ]; then
  cp -r /var/lib/docker.bak/* /var/lib/docker/ || true
fi

# Make persistent
echo "/dev/sdh /var/lib/docker ext4 defaults,nofail 0 2" >> /etc/fstab

# Start Docker
systemctl enable docker
systemctl restart docker

# Create app dir
mkdir -p /opt/app
cd /opt/app

# Copy docker-compose.yml from your S3/GitHub/repo location
# Example 1: If you upload to S3 bucket
# aws s3 cp s3://your-bucket/docker-compose.yml /opt/app/docker-compose.yml

# Example 2: If Terraform uploads it to EC2
cp /home/ubuntu/docker/docker-compose.yml /opt/app/docker-compose.yml

# Deploy Jenkins & Nexus
/usr/local/bin/docker-compose up -d