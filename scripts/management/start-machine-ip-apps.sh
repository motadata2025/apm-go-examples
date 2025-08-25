#!/bin/bash

# Machine IP Applications Startup Script
# This script starts applications accessible via your machine's IP address

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Starting Applications on Machine IP\033[0m"
echo ""

MACHINE_IP="10.128.22.89"

# Stop existing applications
echo -e "${YELLOW}Stopping existing applications...${RESET}"
./stop-db-apps.sh 2>/dev/null || true

# Set environment variables for public binding
export BIND_ADDRESS="0.0.0.0"
export HOST="0.0.0.0"
export SERVER_HOST="0.0.0.0"

# Start database applications
echo -e "${YELLOW}Starting applications...${RESET}"
./start-db-apps.sh

echo ""
echo -e "${GREEN}🎉 Applications are now accessible via machine IP!${RESET}"
echo ""
echo -e "${CYAN}Machine IP Access URLs:${RESET}"
echo -e "  🌐 Machine IP: ${GREEN}$MACHINE_IP${RESET}"
echo ""

# Show application URLs
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "${CYAN}DB SQL Multi Application:${RESET}"
    echo -e "  🚀 Base URL: ${GREEN}http://$MACHINE_IP:$port${RESET}"
    echo -e "  🔧 CRUD Operations: ${GREEN}http://$MACHINE_IP:$port/trigger-crud${RESET}"
    echo -e "  📊 Health Check: ${GREEN}http://$MACHINE_IP:$port/health${RESET}"
    echo -e "  🧪 Test Command: ${GREEN}curl http://$MACHINE_IP:$port/trigger-crud${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "${CYAN}DB GORM Application:${RESET}"
    echo -e "  🚀 Base URL: ${GREEN}http://$MACHINE_IP:$port${RESET}"
    echo -e "  📊 Health Check: ${GREEN}http://$MACHINE_IP:$port/health${RESET}"
    echo -e "  🧪 Test Command: ${GREEN}curl http://$MACHINE_IP:$port/health${RESET}"
    echo ""
fi

# Show other applications if they exist
for app in services/grpc-svc services/kafka-segmentio services/http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        echo -e "${CYAN}${app} Application:${RESET}"
        echo -e "  🚀 Base URL: ${GREEN}http://$MACHINE_IP:$port${RESET}"
        echo ""
    fi
done

echo -e "${CYAN}Access from other machines on the same network:${RESET}"
echo -e "  • Use the URLs above from any device on the same network"
echo -e "  • Make sure firewall allows connections to these ports"
echo -e "  • Applications are bound to 0.0.0.0 (all interfaces)"
echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./stop-machine-ip-apps.sh${RESET}     # Stop applications"
echo -e "  ${GREEN}./status-machine-ip-apps.sh${RESET}   # Check status"
echo -e "  ${GREEN}./test-machine-ip-apps.sh${RESET}     # Test endpoints"
