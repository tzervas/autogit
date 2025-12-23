#!/bin/bash
# SSL Certificate Generation Script for AutoGit
# Generates self-signed certificates for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

DOMAIN=${1:-gitlab.autogit.local}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)/ssl"

mkdir -p "$SSL_DIR"

if [ -f "$SSL_DIR/$DOMAIN.crt" ] || [ -f "$SSL_DIR/$DOMAIN.key" ]; then
    print_info "Certificates for $DOMAIN already exist. Backing up..."
    BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
    [ -f "$SSL_DIR/$DOMAIN.crt" ] && mv "$SSL_DIR/$DOMAIN.crt" "$SSL_DIR/$DOMAIN.crt.$BACKUP_TIME.bak"
    [ -f "$SSL_DIR/$DOMAIN.key" ] && mv "$SSL_DIR/$DOMAIN.key" "$SSL_DIR/$DOMAIN.key.$BACKUP_TIME.bak"
fi

print_info "Generating self-signed certificate for $DOMAIN..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/$DOMAIN.key" \
    -out "$SSL_DIR/$DOMAIN.crt" \
    -subj "/C=US/ST=State/L=City/O=AutoGit/OU=Dev/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN"

print_info "✅ Certificates generated in $SSL_DIR"
print_info "To use these in GitLab, ensure the volume mapping includes this directory and update gitlab.rb."
