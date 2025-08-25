#!/bin/bash

# Public Services Startup Script
# This script starts all services with public internet access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Starting Services with Public Internet Access${RESET}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to get IP")

# Stop existing services
echo -e "${YELLOW}Stopping existing services...${RESET}"
./stop-db-apps.sh 2>/dev/null || true
docker compose -f docker-compose.minimal.yml down 2>/dev/null || true

# Start infrastructure with public bindings
echo -e "${YELLOW}Starting infrastructure with public access...${RESET}"
docker compose -f docker-compose.public.yml up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${RESET}"
sleep 15

# Start database applications
echo -e "${YELLOW}Starting database applications...${RESET}"
export BIND_ADDRESS="0.0.0.0"
./start-db-apps.sh

echo ""
echo -e "${GREEN}🎉 All services are now publicly accessible!${RESET}"
echo ""
echo -e "${CYAN}Public Access URLs:${RESET}"
echo -e "  🌐 Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""
echo -e "${CYAN}Infrastructure Services:${RESET}"
echo -e "  📊 PostgreSQL:  ${GREEN}$PUBLIC_IP:5432${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📊 MySQL:       ${GREEN}$PUBLIC_IP:3306${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📨 Kafka:       ${GREEN}$PUBLIC_IP:9092${RESET} (topics: orders, payments)"
echo -e "  🔧 Adminer:     ${GREEN}http://$PUBLIC_IP:8080${RESET} (database admin)"
echo ""
echo -e "${CYAN}Application Services:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  🚀 DB SQL Multi: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "     Test: ${GREEN}curl http://$PUBLIC_IP:$port/trigger-crud${RESET}"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  🚀 DB GORM:      ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "     Test: ${GREEN}curl http://$PUBLIC_IP:$port/health${RESET}"
fi

echo ""
echo -e "${YELLOW}⚠️  Security Notice:${RESET}"
echo -e "  • Your services are now accessible from the internet"
echo -e "  • Make sure to use strong passwords and enable SSL in production"
echo -e "  • Consider using a reverse proxy with authentication"
echo -e "  • Monitor access logs regularly"
echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./stop-public-services.sh${RESET}  # Stop public services"
echo -e "  ${GREEN}./status-public-services.sh${RESET} # Check public status"
echo -e "  ${GREEN}./secure-public-services.sh${RESET} # Add security measures"

