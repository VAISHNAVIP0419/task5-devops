#!/bin/bash
set -e

# Log output
exec > /var/log/user-data.log 2>&1

# Variables
MOUNT_POINT="/data1"
DOCKER_DATA_ROOT="${MOUNT_POINT}/docker"

echo "==== Updating system and installing Docker ===="
apt-get update -y
apt-get install -y docker.io curl

systemctl enable docker
systemctl stop docker || true

echo "==== Installing Docker Compose ===="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "==== Checking for extra EBS volume ===="
# Find first non-root disk
EBS_DEVICE=$(lsblk -dpno NAME | grep -v "nvme0n1" | head -n1 || true)

if [ -n "$EBS_DEVICE" ]; then
  echo "Found device: $EBS_DEVICE"

  # Format if empty
  if ! blkid "$EBS_DEVICE"; then
    mkfs.ext4 -F "$EBS_DEVICE"
  fi

  # Mount it
  mkdir -p "$MOUNT_POINT"
  UUID=$(blkid -s UUID -o value "$EBS_DEVICE")
  echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
  mount -a
else
  echo "No extra disk found, using default root volume"
fi

echo "==== Setting Docker data-root ===="
mkdir -p "$DOCKER_DATA_ROOT"
cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "${DOCKER_DATA_ROOT}"
}
EOF

systemctl restart docker

echo "==== Adding ubuntu user to docker group ===="
usermod -aG docker ubuntu || true

echo "==== Setup Finished at $(date) ===="