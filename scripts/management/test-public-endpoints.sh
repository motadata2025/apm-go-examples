#!/bin/bash

# Public Endpoints Test Script
# This script tests all public endpoints to verify they're working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🧪 Testing Public Endpoints${RESET}"
echo -e "${BLUE}===========================${RESET}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
echo -e "${CYAN}Testing with IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test HTTP endpoint
test_http_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -e "${YELLOW}Testing $name...${RESET}"
    echo -e "  URL: $url"
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "  Status: ${GREEN}✓ WORKING${RESET}"
        
        # Try to get response content
        local response=$(curl -s "$url" 2>/dev/null | head -c 100)
        if [ -n "$response" ]; then
            echo -e "  Response: ${GREEN}$(echo "$response" | tr '\n' ' ')${RESET}"
        fi
    else
        echo -e "  Status: ${RED}✗ FAILED${RESET}"
        echo -e "  Note: Check firewall and port forwarding"
    fi
    echo ""
}

# Function to test database connection
test_database() {
    local name=$1
    local host=$2
    local port=$3
    local command=$4
    
    echo -e "${YELLOW}Testing $name...${RESET}"
    echo -e "  Host: $host:$port"
    
    if timeout 10 $command >/dev/null 2>&1; then
        echo -e "  Status: ${GREEN}✓ WORKING${RESET}"
    else
        echo -e "  Status: ${RED}✗ FAILED${RESET}"
        echo -e "  Note: Check firewall and database configuration"
    fi
    echo ""
}

# Test infrastructure services
echo -e "${CYAN}Infrastructure Services:${RESET}"

# Test Adminer
test_http_endpoint "Adminer (Database Admin)" "http://$PUBLIC_IP:8080"

# Test application services
echo -e "${CYAN}Application Services:${RESET}"

# Test database applications
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    test_http_endpoint "DB SQL Multi - Health" "http://$PUBLIC_IP:$port/"
    test_http_endpoint "DB SQL Multi - CRUD" "http://$PUBLIC_IP:$port/trigger-crud"
else
    echo -e "${YELLOW}DB SQL Multi not running${RESET}"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    test_http_endpoint "DB GORM - Health" "http://$PUBLIC_IP:$port/health"
else
    echo -e "${YELLOW}DB GORM not running${RESET}"
fi

# Test database connections (these require database clients)
echo -e "${CYAN}Database Services:${RESET}"
echo -e "${YELLOW}Note: Database tests require database clients to be installed${RESET}"

# Test PostgreSQL
if command -v psql >/dev/null 2>&1; then
    test_database "PostgreSQL" "$PUBLIC_IP" "5432" "psql -h $PUBLIC_IP -p 5432 -U testuser -d testdb -c 'SELECT 1;'"
else
    echo -e "${YELLOW}PostgreSQL client not installed, skipping test${RESET}"
    echo -e "  Manual test: psql -h $PUBLIC_IP -p 5432 -U testuser -d testdb"
    echo ""
fi

# Test MySQL
if command -v mysql >/dev/null 2>&1; then
    test_database "MySQL" "$PUBLIC_IP" "3306" "mysql -h $PUBLIC_IP -P 3306 -u testuser -pTest@1234 -D testdb -e 'SELECT 1;'"
else
    echo -e "${YELLOW}MySQL client not installed, skipping test${RESET}"
    echo -e "  Manual test: mysql -h $PUBLIC_IP -P 3306 -u testuser -pTest@1234 -D testdb"
    echo ""
fi

# Test Kafka (requires kafka tools)
if command -v kafka-topics >/dev/null 2>&1; then
    test_database "Kafka" "$PUBLIC_IP" "9092" "kafka-topics --bootstrap-server $PUBLIC_IP:9092 --list"
else
    echo -e "${YELLOW}Kafka client not installed, skipping test${RESET}"
    echo -e "  Manual test: kafka-topics --bootstrap-server $PUBLIC_IP:9092 --list"
    echo ""
fi

# Summary
echo -e "${CYAN}Summary:${RESET}"
echo -e "  🌐 Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo -e "  📊 Services configured for public access"
echo -e "  🔧 Use ${GREEN}./status-public-services.sh${RESET} for detailed status"
echo ""

echo -e "${CYAN}Quick Access URLs:${RESET}"
echo -e "  🔧 Database Admin: ${GREEN}http://$PUBLIC_IP:8080${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  🚀 DB Operations: ${GREEN}http://$PUBLIC_IP:$port/trigger-crud${RESET}"
fi

echo ""
echo -e "${YELLOW}⚠️  Security Reminder:${RESET}"
echo -e "  • Your services are now accessible from the internet"
echo -e "  • Run ${GREEN}./secure-public-services.sh${RESET} to add security measures"
echo -e "  • Change default passwords before production use"
echo -e "  • Monitor access logs regularly"
