#!/bin/bash

# Database Applications Restarter
# This script restarts all database applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🔄 Restarting Database Applications...${RESET}"
echo ""

# Stop applications
echo -e "${YELLOW}Step 1: Stopping applications...${RESET}"
./stop-db-apps.sh

echo ""
echo -e "${YELLOW}Step 2: Waiting for cleanup...${RESET}"
sleep 3

echo ""
echo -e "${YELLOW}Step 3: Starting applications...${RESET}"
./start-db-apps.sh

echo ""
echo -e "${GREEN}🎉 Database applications restarted successfully!${RESET}"
