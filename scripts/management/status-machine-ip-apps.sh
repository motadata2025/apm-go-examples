#!/bin/bash

# Machine IP Applications Status Checker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Machine IP Application Status${RESET}"
echo -e "${BLUE}================================${RESET}"
echo ""

MACHINE_IP="10.128.22.89"
echo -e "${CYAN}Machine IP: ${GREEN}$MACHINE_IP${RESET}"
echo ""

# Function to test application endpoint
test_app_endpoint() {
    local app_name=$1
    local port=$2
    local endpoint=${3:-""}
    
    echo -e "${YELLOW}Testing $app_name...${RESET}"
    echo -e "  Port: $port"
    echo -e "  URL: http://$MACHINE_IP:$port$endpoint"
    
    if timeout 5 curl -s "http://$MACHINE_IP:$port$endpoint" >/dev/null 2>&1; then
        echo -e "  Status: ${GREEN}✓ ACCESSIBLE${RESET}"
        
        # Try to get response content
        local response=$(timeout 3 curl -s "http://$MACHINE_IP:$port$endpoint" 2>/dev/null | head -c 100)
        if [ -n "$response" ]; then
            echo -e "  Response: ${GREEN}$(echo "$response" | tr '\n' ' ')${RESET}"
        fi
    else
        echo -e "  Status: ${RED}✗ NOT ACCESSIBLE${RESET}"
        echo -e "  Note: Check if application is running and firewall settings"
    fi
    echo ""
}

# Test application endpoints
echo -e "${CYAN}Application Endpoints:${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    test_app_endpoint "DB SQL Multi - Health" "$port" "/"
    test_app_endpoint "DB SQL Multi - CRUD" "$port" "/trigger-crud"
else
    echo -e "${YELLOW}DB SQL Multi not running${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    test_app_endpoint "DB GORM - Health" "$port" "/health"
else
    echo -e "${YELLOW}DB GORM not running${RESET}"
    echo ""
fi

echo -e "${CYAN}Quick Test Commands:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  ${GREEN}curl http://$MACHINE_IP:$port/trigger-crud${RESET}  # Test database operations"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  ${GREEN}curl http://$MACHINE_IP:$port/health${RESET}        # Test GORM health"
fi
