#!/bin/bash
# Setup script for autogit

set -e

echo "Setting up autogit..."

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created .env file from .env.example"
fi

# Create necessary directories
mkdir -p data/git data/runners logs
echo "✓ Created data directories"

echo ""
echo "Setup complete! Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Run: docker-compose up -d"
echo "3. Check status: docker-compose ps"
