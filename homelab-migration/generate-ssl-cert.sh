#!/bin/bash
# Generate SSL certificates for GitLab HTTPS access
# Creates self-signed certificates for LAN access

set -e

DOMAIN="gitlab.vectorweight.com"
SSL_DIR="./data/gitlab/ssl"
CERT_FILE="$SSL_DIR/$DOMAIN.crt"
KEY_FILE="$SSL_DIR/$DOMAIN.key"

echo "🔐 Generating SSL certificates for $DOMAIN"
echo "=========================================="

# Create SSL directory
mkdir -p "$SSL_DIR"

# Check if certificates already exist
if [[ -f $CERT_FILE && -f $KEY_FILE ]]; then
    echo "✅ SSL certificates already exist at $SSL_DIR"
    echo "   Certificate: $CERT_FILE"
    echo "   Private Key: $KEY_FILE"
    echo ""
    echo "SSL certificates generated" # For monitoring script compatibility
    echo "To regenerate certificates, delete the data/gitlab/ssl/ directory and run this script again."
    exit 0
fi

# Generate private key
echo "📝 Generating private key..."
openssl genrsa -out "$KEY_FILE" 2048

# Generate certificate signing request
echo "📋 Generating certificate signing request..."
cat >/tmp/cert.conf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = HomeLab
L = HomeLab
O = VectorWeight
OU = GitLab
CN = $DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = gitlab.vectorweight.com
IP.1 = 192.168.1.170
EOF

# Generate self-signed certificate
echo "🎯 Generating self-signed certificate..."
openssl req -new -x509 -key "$KEY_FILE" -out "$CERT_FILE" -days 3650 -config /tmp/cert.conf -extensions v3_req

# Set proper permissions
chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

# Clean up
rm -f /tmp/cert.conf

echo "✅ SSL certificates generated successfully!"
echo "=========================================="
echo "Certificate: $CERT_FILE"
echo "Private Key: $KEY_FILE"
echo ""
echo "📋 Certificate Details:"
openssl x509 -in "$CERT_FILE" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"
echo ""
echo "🔒 For LAN access, you'll need to:"
echo "   1. Trust this certificate in your browser"
echo "   2. Or add it to your system's certificate store"
echo ""
echo "📚 To trust the certificate in browsers:"
echo "   - Chrome/Firefox: Visit https://$DOMAIN and click 'Advanced' → 'Proceed to site'"
echo "   - Or import the certificate file into your browser's certificate manager"
