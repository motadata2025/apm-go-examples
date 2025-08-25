#!/bin/bash

# Database Applications Stopper
# This script gracefully stops all database applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🛑 Stopping Database Applications...${RESET}"
echo ""

# Function to stop application
stop_app() {
    local app_name=$1
    local pid_file="runtime/logs/${app_name}.pid"
    local port_file="runtime/logs/${app_name}.port"
    
    echo -e "${CYAN}Stopping $app_name...${RESET}"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            # Try graceful shutdown first
            kill -TERM "$pid" 2>/dev/null || true
            sleep 2
            
            # Check if still running
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "${YELLOW}  Forcing shutdown...${RESET}"
                kill -KILL "$pid" 2>/dev/null || true
            fi
            
            echo -e "${GREEN}  ✓ Stopped $app_name (PID: $pid)${RESET}"
        else
            echo -e "${YELLOW}  ⚠️  $app_name was not running${RESET}"
        fi
        rm -f "$pid_file"
    else
        echo -e "${YELLOW}  ⚠️  No PID file found for $app_name${RESET}"
    fi
    
    # Clean up port file
    rm -f "$port_file"
}

# Stop all applications
stop_app "services/db-sql-multi"
stop_app "db-gorm"

# Clean up any orphaned processes
echo -e "${YELLOW}Cleaning up any orphaned processes...${RESET}"
pkill -f "go run cmd/app/main.go" 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ All database applications stopped${RESET}"
