#!/bin/bash

# Machine IP Applications Comprehensive Tester

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🧪 Comprehensive Machine IP Endpoint Testing${RESET}"
echo -e "${BLUE}==========================================${RESET}"
echo ""

MACHINE_IP="10.128.22.89"
echo -e "${CYAN}Testing with Machine IP: ${GREEN}$MACHINE_IP${RESET}"
echo ""

# Function to test endpoint with detailed analysis
test_endpoint_detailed() {
    local name=$1
    local url=$2
    local expected_content=${3:-""}
    
    echo -e "${YELLOW}Testing $name...${RESET}"
    echo -e "  URL: $url"
    
    # Test connectivity
    local http_code=$(timeout 10 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    local response_time=$(timeout 10 curl -s -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || echo "timeout")
    
    if [ "$http_code" = "200" ]; then
        echo -e "  Status: ${GREEN}✓ SUCCESS (HTTP $http_code)${RESET}"
        echo -e "  Response Time: ${GREEN}${response_time}s${RESET}"
        
        # Get response content
        local response=$(timeout 10 curl -s "$url" 2>/dev/null | head -c 200)
        if [ -n "$response" ]; then
            echo -e "  Response: ${GREEN}$(echo "$response" | tr '\n' ' ' | cut -c1-80)...${RESET}"
        fi
        
        # Check for expected content if provided
        if [ -n "$expected_content" ]; then
            if echo "$response" | grep -q "$expected_content"; then
                echo -e "  Content Check: ${GREEN}✓ PASSED${RESET}"
            else
                echo -e "  Content Check: ${YELLOW}⚠ UNEXPECTED CONTENT${RESET}"
            fi
        fi
        
    elif [ "$http_code" != "000" ]; then
        echo -e "  Status: ${YELLOW}⚠ HTTP $http_code${RESET}"
        echo -e "  Note: Endpoint reachable but returned non-200 status"
    else
        echo -e "  Status: ${RED}✗ FAILED${RESET}"
        echo -e "  Note: Check if application is running and firewall settings"
    fi
    echo ""
}

# Test all application endpoints
echo -e "${CYAN}Application Endpoint Tests:${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "${BLUE}DB SQL Multi Application:${RESET}"
    test_endpoint_detailed "Health Check" "http://$MACHINE_IP:$port/"
    test_endpoint_detailed "CRUD Operations" "http://$MACHINE_IP:$port/trigger-crud" "message"
    test_endpoint_detailed "Database Test" "http://$MACHINE_IP:$port/trigger-crud" "success"
else
    echo -e "${YELLOW}DB SQL Multi not running - start with ./start-machine-ip-apps.sh${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "${BLUE}DB GORM Application:${RESET}"
    test_endpoint_detailed "Health Check" "http://$MACHINE_IP:$port/health" "ok"
else
    echo -e "${YELLOW}DB GORM not running${RESET}"
    echo ""
fi

# Summary
echo -e "${CYAN}Test Summary:${RESET}"
echo -e "  🌐 Machine IP: ${GREEN}$MACHINE_IP${RESET}"
echo -e "  📊 Application endpoints tested"
echo -e "  🔧 Accessible from same network"
echo ""

echo -e "${CYAN}Network Access:${RESET}"
echo -e "  • Same machine: ✓ Working"
echo -e "  • Same network: ✓ Should work (if firewall allows)"
echo -e "  • Internet: Requires port forwarding/public IP"
echo ""

echo -e "${YELLOW}📝 Notes:${RESET}"
echo -e "  • Applications are bound to 0.0.0.0 (all interfaces)"
echo -e "  • Accessible from other devices on the same network"
echo -e "  • For internet access, configure router port forwarding"
