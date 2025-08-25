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
    echo -e "${YELLOW}Available sets:${RESET}"
    ls -d "$MULTI_SET_ROOT"/*/bin 2>/dev/null | sed 's|.*/\([^/]*\)/bin|\1|' || echo "No sets found"
    exit 1
fi

echo -e "${BLUE}Starting set: $SET_NAME${RESET}"

# Load environment variables
ENV_FILE="$SET_DIR/env/$SET_NAME.env"
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Loading environment from $ENV_FILE${RESET}"
    source "$ENV_FILE"
else
    echo -e "${YELLOW}Warning: Environment file $ENV_FILE not found${RESET}"
fi

# Extract base from set name
BASE=$(echo "$SET_NAME" | grep -o '[0-9]\+' | head -1)
if [ -z "$BASE" ]; then
    echo -e "${RED}Error: Could not extract base number from set name${RESET}"
    exit 1
fi

# Create logs directory
mkdir -p "$SET_DIR/logs"

# Function to start a service
start_service() {
    local binary="$1"
    local service_name="$2"
    local log_file="$SET_DIR/logs/$service_name.log"
    local pid_file="$SET_DIR/logs/$service_name.pid"
    
    if [ ! -f "$binary" ]; then
        echo -e "${YELLOW}Warning: Binary $binary not found, skipping${RESET}"
        return 0
    fi
    
    # Check if already running
    if [ -f "$pid_file" ]; then
        local old_pid=$(cat "$pid_file")
        if kill -0 "$old_pid" 2>/dev/null; then
            echo -e "${YELLOW}Service $service_name already running (PID: $old_pid)${RESET}"
            return 0
        else
            rm -f "$pid_file"
        fi
    fi
    
    echo -e "${YELLOW}Starting $service_name...${RESET}"
    
    # Start service in background
    nohup "$binary" > "$log_file" 2>&1 &
    local pid=$!
    echo "$pid" > "$pid_file"
    
    # Wait a moment and check if it's still running
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${GREEN}✓ $service_name started (PID: $pid)${RESET}"
    else
        echo -e "${RED}✗ $service_name failed to start${RESET}"
        cat "$log_file" | tail -10
        return 1
    fi
}

# Start services based on what's available in the set
BIN_DIR="$SET_DIR/bin"

echo -e "${CYAN}Starting services for $SET_NAME...${RESET}"

# Start gRPC server first (if available, only in build-800)
if [ -f "$BIN_DIR/grpc-server-$BASE" ]; then
    start_service "$BIN_DIR/grpc-server-$BASE" "grpc-server"
    sleep 2  # Give gRPC server time to start
fi

# Start main services
start_service "$BIN_DIR/database-sql-$BASE" "database-sql"
start_service "$BIN_DIR/kafka-producer-$BASE" "kafka-producer"
start_service "$BIN_DIR/grpc-client-$BASE" "grpc-client"
start_service "$BIN_DIR/http-rest-$BASE" "http-rest"

# Start kafka consumer (if available, only in build-800)
if [ -f "$BIN_DIR/kafka-consumer-$BASE" ]; then
    start_service "$BIN_DIR/kafka-consumer-$BASE" "kafka-consumer"
fi

echo ""
echo -e "${GREEN}✓ Set $SET_NAME started successfully${RESET}"
echo ""

# Show service map
echo -e "${CYAN}Service Endpoints:${RESET}"
if [ -n "${PORT_DB:-}" ]; then
    echo -e "  Database:     ${GREEN}http://localhost:${PORT_DB}/trigger-crud${RESET}"
fi
if [ -n "${PORT_KAFKA:-}" ]; then
    echo -e "  Kafka:        ${GREEN}http://localhost:${PORT_KAFKA}/trigger-produce${RESET}"
fi
if [ -n "${PORT_GRPC_CLIENT:-}" ]; then
    echo -e "  gRPC Client:  ${GREEN}http://localhost:${PORT_GRPC_CLIENT}/trigger-simple${RESET}"
    echo -e "  gRPC Stream:  ${GREEN}http://localhost:${PORT_GRPC_CLIENT}/trigger-stream${RESET}"
fi
if [ -n "${PORT_HTTP:-}" ]; then
    echo -e "  HTTP REST:    ${GREEN}http://localhost:${PORT_HTTP}/trigger/allservices${RESET}"
fi

echo ""
echo -e "${YELLOW}To stop services: $MULTI_SET_ROOT/scripts/stop_set.sh $SET_NAME${RESET}"
echo -e "${YELLOW}To check logs: tail -f $SET_DIR/logs/*.log${RESET}"
