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
SSL_DIR="./services/git-server/config/ssl"

mkdir -p "$SSL_DIR"

print_info "Generating self-signed certificate for $DOMAIN..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/$DOMAIN.key" \
    -out "$SSL_DIR/$DOMAIN.crt" \
    -subj "/C=US/ST=State/L=City/O=AutoGit/OU=Dev/CN=$DOMAIN"

print_info "✅ Certificates generated in $SSL_DIR"
print_info "To use these in GitLab, ensure the volume mapping includes this directory and update gitlab.rb."
