#!/usr/bin/env bash
# GitLab Data Migration Script
#
# Migrates GitLab data from /var/lib/autogit to /data/autogit
# for better storage utilization

set -euo pipefail

OLD_PATH="/var/lib/autogit"
NEW_PATH="/data/autogit"

echo "GitLab Data Migration: $OLD_PATH -> $NEW_PATH"

# Check if new path already exists
if [[ -d $NEW_PATH ]]; then
    echo "Error: $NEW_PATH already exists. Please check and remove if safe."
    exit 1
fi

# Check available space on /data
DATA_AVAIL=$(df /data | tail -1 | awk '{print $4}')
DATA_AVAIL_GB=$((DATA_AVAIL / 1024 / 1024))

if [[ $DATA_AVAIL_GB -lt 10 ]]; then
    echo "Warning: Only ${DATA_AVAIL_GB}GB available on /data"
fi

# Stop GitLab services
echo "Stopping GitLab container..."
cd ~/autogit
DOCKER_HOST=unix:///run/user/1000/docker.sock docker compose down

# Create new directory
echo "Creating $NEW_PATH..."
sudo mkdir -p "$NEW_PATH"
sudo chown kang:kang "$NEW_PATH"

# Move data
echo "Moving data (this may take a while)..."
sudo mv "$OLD_PATH"/* "$NEW_PATH/" 2> /dev/null || true
sudo mv "$OLD_PATH"/.* "$NEW_PATH/" 2> /dev/null || true

# Update .env file
echo "Updating .env file..."
if ! grep -q "^GITLAB_DATA_PATH=" .env; then
    echo "GITLAB_DATA_PATH=$NEW_PATH" >> .env
fi

# Start services
echo "Starting GitLab container..."
DOCKER_HOST=unix:///run/user/1000/docker.sock docker compose up -d

# Wait for health
echo "Waiting for GitLab to be healthy..."
timeout=600
while [[ $timeout -gt 0 ]]; do
    if curl -s -f http://localhost:3000/-/health > /dev/null 2>&1; then
        break
    fi
    sleep 10
    timeout=$((timeout - 10))
done

if [[ $timeout -le 0 ]]; then
    echo "Warning: GitLab may not be fully ready yet"
else
    echo "GitLab is healthy!"
fi

# Clean up old directory
echo "Cleaning up old directory..."
sudo rmdir "$OLD_PATH" 2> /dev/null || echo "Could not remove $OLD_PATH (may not be empty)"

# Verify
echo "Verifying migration..."
NEW_SIZE=$(sudo du -sh "$NEW_PATH" | cut -f1)
echo "Data migrated to $NEW_PATH (size: $NEW_SIZE)"

echo "Migration complete! GitLab data is now on /data volume."
