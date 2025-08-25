#!/bin/bash

# Public Applications Status Checker
# This script checks the status of publicly accessible application endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Public Application Endpoints Status${RESET}"
echo -e "${BLUE}======================================${RESET}"
echo ""

# Get IPv4 public IP
get_ipv4_public_ip() {
    local ip=""
    ip=$(curl -4 -s ifconfig.me 2>/dev/null) || \
    ip=$(curl -4 -s ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -4 -s icanhazip.com 2>/dev/null) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo "Unable to determine IPv4 public IP"
        return 1
    fi
}

PUBLIC_IP=$(get_ipv4_public_ip)
echo -e "${CYAN}Public IPv4: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test application endpoint
test_app_endpoint() {
    local app_name=$1
    local port=$2
    local endpoint=${3:-""}
    
    echo -e "${YELLOW}Testing $app_name...${RESET}"
    echo -e "  Port: $port"
    echo -e "  URL: http://$PUBLIC_IP:$port$endpoint"
    
    if timeout 10 curl -4 -s "http://$PUBLIC_IP:$port$endpoint" >/dev/null 2>&1; then
        echo -e "  Status: ${GREEN}✓ PUBLICLY ACCESSIBLE${RESET}"
        
        # Try to get response content
        local response=$(timeout 5 curl -4 -s "http://$PUBLIC_IP:$port$endpoint" 2>/dev/null | head -c 100)
        if [ -n "$response" ]; then
            echo -e "  Response: ${GREEN}$(echo "$response" | tr '\n' ' ')${RESET}"
        fi
    else
        echo -e "  Status: ${RED}✗ NOT ACCESSIBLE${RESET}"
        echo -e "  Note: Check cloud provider security groups/firewall"
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

# Test other applications
for app in services/grpc-svc services/kafka-segmentio services/http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        test_app_endpoint "$app" "$port" "/"
    fi
done

echo -e "${CYAN}Quick Test Commands:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  ${GREEN}curl http://$PUBLIC_IP:$port/trigger-crud${RESET}  # Test database operations"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  ${GREEN}curl http://$PUBLIC_IP:$port/health${RESET}        # Test GORM health"
fi

echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./start-public-apps.sh${RESET}    # Start public applications"
echo -e "  ${GREEN}./stop-public-apps.sh${RESET}     # Stop public applications"
echo -e "  ${GREEN}./test-public-apps.sh${RESET}     # Comprehensive endpoint testing"
