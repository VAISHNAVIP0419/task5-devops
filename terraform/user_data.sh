#!/bin/bash
set -e

# Install Docker
apt-get update -y
apt-get install -y docker.io curl
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Setup EBS volume for Docker
EBS_DEVICE="/dev/nvme1n1"
DOCKER_DIR="/var/lib/docker"

while [ ! -b $EBS_DEVICE ]; do
  echo "Waiting for EBS device $EBS_DEVICE..."
  sleep 5
done

systemctl stop docker || true

if ! blkid $EBS_DEVICE; then
    mkfs.ext4 $EBS_DEVICE
fi

mkdir -p $DOCKER_DIR
mount $EBS_DEVICE $DOCKER_DIR
grep -q "$EBS_DEVICE" /etc/fstab || echo "$EBS_DEVICE $DOCKER_DIR ext4 defaults,nofail 0 2" >> /etc/fstab

systemctl start docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Deploy Jenkins & Nexus using docker-compose
APP_DIR="/opt/app"
mkdir -p $APP_DIR
cd $APP_DIR

curl -s -O https://raw.githubusercontent.com/VAISHNAVIP0419/task5-devops/main/docker/docker-compose.yml

docker-compose up -d