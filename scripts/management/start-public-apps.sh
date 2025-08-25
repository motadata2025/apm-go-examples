#!/bin/bash

# Public Applications Startup Script
# This script starts Go applications with public IPv4 access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Starting Applications with Public IPv4 Access${RESET}"
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

# Stop existing applications
echo -e "${YELLOW}Stopping existing applications...${RESET}"
./stop-db-apps.sh 2>/dev/null || true

# Set environment variables for public binding
export BIND_ADDRESS="0.0.0.0"
export HOST="0.0.0.0"
export SERVER_HOST="0.0.0.0"

# Start database applications with public binding
echo -e "${YELLOW}Starting applications with public access...${RESET}"
./start-db-apps.sh

echo ""
echo -e "${GREEN}🎉 Applications are now publicly accessible!${RESET}"
echo ""
echo -e "${CYAN}Public IPv4 Access URLs:${RESET}"
echo -e "  🌐 Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Show application URLs
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "${CYAN}DB SQL Multi Application:${RESET}"
    echo -e "  🚀 Base URL: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "  🔧 CRUD Operations: ${GREEN}http://$PUBLIC_IP:$port/trigger-crud${RESET}"
    echo -e "  📊 Health Check: ${GREEN}http://$PUBLIC_IP:$port/health${RESET}"
    echo -e "  🧪 Test Command: ${GREEN}curl http://$PUBLIC_IP:$port/trigger-crud${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "${CYAN}DB GORM Application:${RESET}"
    echo -e "  🚀 Base URL: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "  📊 Health Check: ${GREEN}http://$PUBLIC_IP:$port/health${RESET}"
    echo -e "  🧪 Test Command: ${GREEN}curl http://$PUBLIC_IP:$port/health${RESET}"
    echo ""
fi

# Show other applications if they exist
for app in services/grpc-svc services/kafka-segmentio services/http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        echo -e "${CYAN}${app} Application:${RESET}"
        echo -e "  🚀 Base URL: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
        echo ""
    fi
done

echo -e "${YELLOW}⚠️  Security Notice:${RESET}"
echo -e "  • Your application endpoints are now accessible from the internet"
echo -e "  • Infrastructure services (databases) remain internal"
echo -e "  • Consider adding authentication and rate limiting"
echo -e "  • Monitor access logs regularly"
echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./stop-public-apps.sh${RESET}     # Stop public applications"
echo -e "  ${GREEN}./status-public-apps.sh${RESET}   # Check public application status"
echo -e "  ${GREEN}./test-public-apps.sh${RESET}     # Test public application endpoints"
