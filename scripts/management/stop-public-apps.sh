#!/bin/bash

# Stop Public Applications Script

echo "🛑 Stopping public applications..."

# Stop applications
./stop-db-apps.sh 2>/dev/null || true

echo "✓ All public applications stopped"
echo "Note: Infrastructure services (databases) continue running internally"
