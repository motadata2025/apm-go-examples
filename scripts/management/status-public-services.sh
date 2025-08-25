#!/bin/bash

# Public Services Status Checker
# This script checks the status of publicly accessible services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Public Services Status Check${RESET}"
echo -e "${BLUE}===============================${RESET}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to get IP")
echo -e "${CYAN}Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test external access
test_external_access() {
    local service=$1
    local port=$2
    local path=${3:-""}
    
    echo -e "${YELLOW}Testing $service (port $port)...${RESET}"
    
    if timeout 10 curl -s "http://$PUBLIC_IP:$port$path" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $service is publicly accessible${RESET}"
        echo -e "  URL: ${GREEN}http://$PUBLIC_IP:$port$path${RESET}"
    else
        echo -e "${RED}✗ $service is not publicly accessible${RESET}"
        echo -e "  Check firewall and port forwarding for port $port"
    fi
    echo ""
}

# Test infrastructure services
echo -e "${CYAN}Infrastructure Services:${RESET}"
test_external_access "Adminer (Database Admin)" 8080

# Test database applications
echo -e "${CYAN}Application Services:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    test_external_access "DB SQL Multi" "$port" "/trigger-crud"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    test_external_access "DB GORM" "$port" "/health"
fi

# Test database connections (these require special clients)
echo -e "${CYAN}Database Services (require database clients):${RESET}"
echo -e "  📊 PostgreSQL: ${GREEN}$PUBLIC_IP:5432${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📊 MySQL:      ${GREEN}$PUBLIC_IP:3306${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📨 Kafka:      ${GREEN}$PUBLIC_IP:9092${RESET} (topics: orders, payments)"
echo ""

echo -e "${CYAN}Security Recommendations:${RESET}"
echo -e "  🔒 Run: ${GREEN}./secure-public-services.sh${RESET} to add security measures"
echo -e "  🔍 Monitor access logs regularly"
echo -e "  🛡️  Consider using a reverse proxy with authentication"
echo -e "  🔐 Use SSL/TLS certificates for production"

