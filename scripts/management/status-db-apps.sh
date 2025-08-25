#!/bin/bash

# Database Applications Status Checker
# This script shows the status of all database applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}📊 Database Applications Status${RESET}"
echo -e "${BLUE}================================${RESET}"
echo ""

# Function to check application status
check_app_status() {
    local app_name=$1
    local pid_file="runtime/logs/${app_name}.pid"
    local port_file="runtime/logs/${app_name}.port"
    local log_file="runtime/logs/${app_name}.log"
    
    echo -e "${CYAN}$app_name:${RESET}"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "  Status: ${GREEN}RUNNING${RESET} (PID: $pid)"
            
            if [ -f "$port_file" ]; then
                local port=$(cat "$port_file")
                echo -e "  Port: ${GREEN}$port${RESET}"
                echo -e "  URL: ${GREEN}http://localhost:$port${RESET}"
                
                # Test health endpoint
                if curl -s "http://localhost:$port/health" >/dev/null 2>&1; then
                    echo -e "  Health: ${GREEN}OK${RESET}"
                elif curl -s "http://localhost:$port/" >/dev/null 2>&1; then
                    echo -e "  Health: ${GREEN}OK${RESET}"
                else
                    echo -e "  Health: ${YELLOW}NO RESPONSE${RESET}"
                fi
            else
                echo -e "  Port: ${YELLOW}UNKNOWN${RESET}"
            fi
            
            # Show memory usage
            local memory=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print int($1/1024)}')
            if [ -n "$memory" ]; then
                echo -e "  Memory: ${GREEN}${memory}MB${RESET}"
            fi
            
        else
            echo -e "  Status: ${RED}STOPPED${RESET} (stale PID file)"
            rm -f "$pid_file" "$port_file"
        fi
    else
        echo -e "  Status: ${RED}STOPPED${RESET}"
    fi
    
    # Show recent log entries
    if [ -f "$log_file" ]; then
        local log_size=$(wc -l < "$log_file")
        echo -e "  Log entries: ${GREEN}$log_size${RESET}"
        
        # Show last error if any
        local last_error=$(grep -i "error\|fatal\|panic" "$log_file" | tail -1 2>/dev/null || true)
        if [ -n "$last_error" ]; then
            echo -e "  Last error: ${RED}$(echo "$last_error" | cut -c1-60)...${RESET}"
        fi
    else
        echo -e "  Log: ${YELLOW}NO LOG FILE${RESET}"
    fi
    
    echo ""
}

# Check infrastructure status
echo -e "${CYAN}Infrastructure Status:${RESET}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "apm-(postgres|mysql|kafka|zookeeper)" | while read line; do
    name=$(echo "$line" | awk '{print $1}')
    status=$(echo "$line" | awk '{print $2}')
    if [ "$status" = "Up" ]; then
        echo -e "  $name: ${GREEN}RUNNING${RESET}"
    else
        echo -e "  $name: ${RED}$status${RESET}"
    fi
done
echo ""

# Check database applications
echo -e "${CYAN}Database Applications:${RESET}"
check_app_status "db-sql-multi"
check_app_status "db-gorm"

# Show quick test commands
echo -e "${CYAN}Quick Test Commands:${RESET}"
if [ -f "runtime/logs/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/db-sql-multi.port)
    echo -e "  ${GREEN}curl http://localhost:$port/trigger-crud${RESET}  # Test db-sql-multi"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  ${GREEN}curl http://localhost:$port/health${RESET}        # Test db-gorm"
fi

echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./start-db-apps.sh${RESET}   # Start applications"
echo -e "  ${GREEN}./stop-db-apps.sh${RESET}    # Stop applications"
echo -e "  ${GREEN}./restart-db-apps.sh${RESET} # Restart applications"
echo -e "  ${GREEN}tail -f runtime/logs/*.log${RESET}   # View logs"
