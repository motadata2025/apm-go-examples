#!/bin/bash
set -euo pipefail

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# Configuration
MULTI_SET_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
    echo "Usage: $0 <set-name>"
    echo "Example: $0 build-800"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

SET_NAME="$1"
SET_DIR="$MULTI_SET_ROOT/$SET_NAME"

if [ ! -d "$SET_DIR" ]; then
    echo -e "${RED}Error: Set directory $SET_DIR does not exist${RESET}"
    exit 1
fi

echo -e "${BLUE}Stopping set: $SET_NAME${RESET}"

# Function to stop a service
stop_service() {
    local service_name="$1"
    local pid_file="$SET_DIR/logs/$service_name.pid"
    
    if [ ! -f "$pid_file" ]; then
        echo -e "${YELLOW}No PID file for $service_name${RESET}"
        return 0
    fi
    
    local pid=$(cat "$pid_file")
    
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "${YELLOW}Service $service_name not running (stale PID file)${RESET}"
        rm -f "$pid_file"
        return 0
    fi
    
    echo -e "${YELLOW}Stopping $service_name (PID: $pid)...${RESET}"
    
    # Try graceful shutdown first
    if kill -TERM "$pid" 2>/dev/null; then
        # Wait up to 10 seconds for graceful shutdown
        local count=0
        while [ $count -lt 10 ] && kill -0 "$pid" 2>/dev/null; do
            sleep 1
            count=$((count + 1))
        done
        
        # If still running, force kill
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${YELLOW}Graceful shutdown failed, force killing...${RESET}"
            kill -KILL "$pid" 2>/dev/null || true
            sleep 1
        fi
    fi
    
    # Check if process is really gone
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${RED}✗ Failed to stop $service_name${RESET}"
        return 1
    else
        echo -e "${GREEN}✓ $service_name stopped${RESET}"
        rm -f "$pid_file"
        return 0
    fi
}

# Stop services in reverse order (consumers first, then producers)
LOGS_DIR="$SET_DIR/logs"

if [ -d "$LOGS_DIR" ]; then
    echo -e "${CYAN}Stopping services for $SET_NAME...${RESET}"
    
    # Stop in reverse dependency order
    stop_service "kafka-consumer"
    stop_service "http-rest"
    stop_service "grpc-client"
    stop_service "kafka-producer"
    stop_service "database-sql"
    stop_service "grpc-server"
    
    echo ""
    echo -e "${GREEN}✓ Set $SET_NAME stopped successfully${RESET}"
else
    echo -e "${YELLOW}No logs directory found, no services to stop${RESET}"
fi

# Also try to kill any processes that might match the set's binary pattern
BASE=$(echo "$SET_NAME" | grep -o '[0-9]\+' | head -1)
if [ -n "$BASE" ]; then
    echo -e "${YELLOW}Checking for any remaining processes...${RESET}"
    
    # Kill any processes whose executable path contains our set's bin directory
    BIN_DIR="$SET_DIR/bin"
    if [ -d "$BIN_DIR" ]; then
        # Find processes running from our bin directory
        local pids=$(pgrep -f "$BIN_DIR" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo -e "${YELLOW}Found additional processes, terminating...${RESET}"
            echo "$pids" | xargs kill -TERM 2>/dev/null || true
            sleep 2
            echo "$pids" | xargs kill -KILL 2>/dev/null || true
        fi
    fi
fi

echo -e "${BLUE}Cleanup complete for $SET_NAME${RESET}"
