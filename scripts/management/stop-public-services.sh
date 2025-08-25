#!/bin/bash

# Stop Public Services Script

echo "🛑 Stopping public services..."

# Stop applications
./stop-db-apps.sh 2>/dev/null || true

# Stop infrastructure
docker compose -f docker-compose.public.yml down 2>/dev/null || true
docker compose -f docker-compose.minimal.yml down 2>/dev/null || true

echo "✓ All public services stopped"
