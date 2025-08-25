#!/bin/bash

# Stop Machine IP Applications Script

echo "🛑 Stopping machine IP applications..."

# Stop applications
./stop-db-apps.sh 2>/dev/null || true

echo "✓ All applications stopped"
