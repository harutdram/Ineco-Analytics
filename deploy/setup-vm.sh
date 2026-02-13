#!/bin/bash
# INECOBANK Superset - GCP VM Setup Script
# Run this on a fresh Ubuntu VM after cloning the repo

set -e

echo "=== INECOBANK Superset VM Setup ==="

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# Install Docker Compose if not present
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    apt-get update && apt-get install -y docker-compose-plugin
fi

# Navigate to project directory (run from repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Create .env if missing
if [ ! -f .env ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT: Edit .env and set:"
    echo "   - ADMIN_PASSWORD (strong password)"
    echo "   - SECRET_KEY (run: openssl rand -base64 42)"
    echo "   - POSTGRES_PASSWORD"
    echo ""
    read -p "Press Enter after editing .env, or Ctrl+C to exit..."
fi

# Create credentials dir if missing
mkdir -p credentials
if [ ! -f credentials/bigquery-service-account.json ]; then
    echo ""
    echo "⚠️  Add BigQuery credentials:"
    echo "   Place bigquery-service-account.json in credentials/"
    echo ""
fi

# Start Superset
echo "Starting Superset..."
docker compose up -d

echo ""
echo "=== Setup complete ==="
echo "Superset is starting. Wait 2-3 minutes, then access at:"
echo "  http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VM_IP'):8088"
echo ""
echo "Default login: admin / (password from .env)"
