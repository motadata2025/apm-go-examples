#!/bin/bash

# Public Application Endpoints Comprehensive Tester
# This script thoroughly tests all public application endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🧪 Comprehensive Public Endpoint Testing${RESET}"
echo -e "${BLUE}=========================================${RESET}"
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
echo -e "${CYAN}Testing with IPv4: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test endpoint with detailed analysis
test_endpoint_detailed() {
    local name=$1
    local url=$2
    local expected_content=${3:-""}
    
    echo -e "${YELLOW}Testing $name...${RESET}"
    echo -e "  URL: $url"
    
    # Test connectivity
    local http_code=$(timeout 10 curl -4 -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    local response_time=$(timeout 10 curl -4 -s -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || echo "timeout")
    
    if [ "$http_code" = "200" ]; then
        echo -e "  Status: ${GREEN}✓ SUCCESS (HTTP $http_code)${RESET}"
        echo -e "  Response Time: ${GREEN}${response_time}s${RESET}"
        
        # Get response content
        local response=$(timeout 10 curl -4 -s "$url" 2>/dev/null | head -c 200)
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
        echo -e "  Note: Check cloud provider security groups/firewall rules"
    fi
    echo ""
}

# Test all application endpoints
echo -e "${CYAN}Application Endpoint Tests:${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "${BLUE}DB SQL Multi Application:${RESET}"
    test_endpoint_detailed "Health Check" "http://$PUBLIC_IP:$port/"
    test_endpoint_detailed "CRUD Operations" "http://$PUBLIC_IP:$port/trigger-crud" "message"
    test_endpoint_detailed "Database Test" "http://$PUBLIC_IP:$port/trigger-crud" "success"
else
    echo -e "${YELLOW}DB SQL Multi not running - start with ./start-public-apps.sh${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "${BLUE}DB GORM Application:${RESET}"
    test_endpoint_detailed "Health Check" "http://$PUBLIC_IP:$port/health" "ok"
else
    echo -e "${YELLOW}DB GORM not running${RESET}"
    echo ""
fi

# Test other applications
for app in services/grpc-svc services/kafka-segmentio services/http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        echo -e "${BLUE}${app} Application:${RESET}"
        test_endpoint_detailed "Base Endpoint" "http://$PUBLIC_IP:$port/"
    fi
done

# Summary
echo -e "${CYAN}Test Summary:${RESET}"
echo -e "  🌐 Public IPv4: ${GREEN}$PUBLIC_IP${RESET}"
echo -e "  📊 Application endpoints tested"
echo -e "  🔧 Infrastructure services remain internal (secure)"
echo ""

echo -e "${CYAN}Next Steps:${RESET}"
echo -e "  1. If tests fail: Check cloud provider security groups"
echo -e "  2. Add authentication: Implement API keys or OAuth"
echo -e "  3. Add monitoring: Set up access logging"
echo -e "  4. Add SSL: Use HTTPS with certificates"
echo ""

echo -e "${YELLOW}⚠️  Security Reminder:${RESET}"
echo -e "  • Your application endpoints are now public"
echo -e "  • Add authentication before production use"
echo -e "  • Monitor access logs regularly"
echo -e "  • Consider rate limiting for production"
