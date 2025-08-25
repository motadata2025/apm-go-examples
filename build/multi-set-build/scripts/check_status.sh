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

echo -e "${BLUE}Status check for set: $SET_NAME${RESET}"
echo ""

# Load environment variables if available
ENV_FILE="$SET_DIR/env/$SET_NAME.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Function to check service status
check_service() {
    local service_name="$1"
    local port="$2"
    local endpoint="$3"
    local pid_file="$SET_DIR/logs/$service_name.pid"
    
    echo -e "${CYAN}=== $service_name ===${RESET}"
    
    # Check PID file
    if [ ! -f "$pid_file" ]; then
        echo -e "  Status: ${RED}Not running (no PID file)${RESET}"
        return 1
    fi
    
    local pid=$(cat "$pid_file")
    
    # Check if process is running
    if ! kill -0 "$pid" 2>/dev/null; then
        echo -e "  Status: ${RED}Not running (stale PID file)${RESET}"
        echo -e "  PID: ${RED}$pid (dead)${RESET}"
        return 1
    fi
    
    echo -e "  Status: ${GREEN}Running${RESET}"
    echo -e "  PID: ${GREEN}$pid${RESET}"
    
    if [ -n "$port" ] && [ -n "$endpoint" ]; then
        echo -e "  Port: ${YELLOW}$port${RESET}"
        echo -e "  Endpoint: ${YELLOW}http://localhost:$port$endpoint${RESET}"
        
        # Test endpoint
        if curl -s --max-time 3 "http://localhost:$port$endpoint" >/dev/null 2>&1; then
            echo -e "  Health: ${GREEN}OK${RESET}"
        else
            echo -e "  Health: ${RED}Not responding${RESET}"
        fi
    fi
    
    # Show recent log entries
    local log_file="$SET_DIR/logs/$service_name.log"
    if [ -f "$log_file" ]; then
        echo -e "  Recent logs:"
        tail -3 "$log_file" 2>/dev/null | sed 's/^/    /' || echo "    (no recent logs)"
    fi
    
    echo ""
}

# Check services
LOGS_DIR="$SET_DIR/logs"

if [ ! -d "$LOGS_DIR" ]; then
    echo -e "${YELLOW}No logs directory found${RESET}"
    exit 1
fi

# Check each service
check_service "grpc-server" "" ""
check_service "database-sql" "${PORT_DB:-}" "/trigger-crud"
check_service "kafka-producer" "${PORT_KAFKA:-}" "/trigger-produce"
check_service "grpc-client" "${PORT_GRPC_CLIENT:-}" "/trigger-simple"
check_service "http-rest" "${PORT_HTTP:-}" "/trigger/allservices"
check_service "kafka-consumer" "" ""

# Summary
echo -e "${CYAN}=== Summary ===${RESET}"

# Count running services
running_count=0
total_count=0

for service in grpc-server database-sql kafka-producer grpc-client http-rest kafka-consumer; do
    pid_file="$SET_DIR/logs/$service.pid"
    if [ -f "$pid_file" ]; then
        total_count=$((total_count + 1))
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            running_count=$((running_count + 1))
        fi
    fi
done

if [ $running_count -eq $total_count ] && [ $total_count -gt 0 ]; then
    echo -e "  Overall Status: ${GREEN}All services running ($running_count/$total_count)${RESET}"
elif [ $running_count -gt 0 ]; then
    echo -e "  Overall Status: ${YELLOW}Partial ($running_count/$total_count services running)${RESET}"
else
    echo -e "  Overall Status: ${RED}No services running${RESET}"
fi

# Show environment info
if [ -n "${BASE:-}" ]; then
    echo -e "  Base: ${YELLOW}$BASE${RESET}"
fi

if [ -n "${PORT_DB:-}" ]; then
    echo -e "  Port Range: ${YELLOW}${PORT_DB}-${PORT_HTTP}${RESET}"
fi

echo ""
echo -e "${YELLOW}Commands:${RESET}"
echo -e "  Start: ${GREEN}$MULTI_SET_ROOT/scripts/run_set_bg.sh $SET_NAME${RESET}"
echo -e "  Stop:  ${GREEN}$MULTI_SET_ROOT/scripts/stop_set.sh $SET_NAME${RESET}"
echo -e "  Logs:  ${GREEN}tail -f $SET_DIR/logs/*.log${RESET}"
