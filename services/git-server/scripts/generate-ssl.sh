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
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" 2>/dev/null && pwd)"

if [ -z "$CONFIG_DIR" ]; then
    print_error "Could not resolve config directory at $SCRIPT_DIR/../config"
    exit 1
fi

SSL_DIR="$CONFIG_DIR/ssl"
mkdir -p "$SSL_DIR"

if [ -f "$SSL_DIR/$DOMAIN.crt" ] || [ -f "$SSL_DIR/$DOMAIN.key" ]; then
    print_info "Certificates for $DOMAIN already exist. Backing up..."
    # Use nanoseconds and a random suffix to avoid collisions
    BACKUP_TIME=$(date +%Y%m%d_%H%M%S_%N)
    RANDOM_SUFFIX=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)
    [ -f "$SSL_DIR/$DOMAIN.crt" ] && mv "$SSL_DIR/$DOMAIN.crt" "$SSL_DIR/$DOMAIN.crt.$BACKUP_TIME.$RANDOM_SUFFIX.bak"
    [ -f "$SSL_DIR/$DOMAIN.key" ] && mv "$SSL_DIR/$DOMAIN.key" "$SSL_DIR/$DOMAIN.key.$BACKUP_TIME.$RANDOM_SUFFIX.bak"
fi

print_info "Generating self-signed certificate for $DOMAIN..."

# Check OpenSSL version for -addext support (OpenSSL >= 1.1.1)
OPENSSL_VERSION=$(openssl version | awk '{print $2}')
if [[ $OPENSSL_VERSION < "1.1.1" ]]; then
    print_error "OpenSSL version $OPENSSL_VERSION does not support -addext. Please upgrade to 1.1.1 or newer."
    exit 1
fi

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/$DOMAIN.key" \
    -out "$SSL_DIR/$DOMAIN.crt" \
    -subj "/C=US/ST=State/L=City/O=AutoGit/OU=Dev/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN"

print_info "✅ Certificates generated in $SSL_DIR"
print_info "To use these in GitLab, ensure the volume mapping includes this directory and update gitlab.rb."
