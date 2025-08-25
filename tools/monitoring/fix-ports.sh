#!/bin/bash
set -euo pipefail

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${CYAN}🔧 Port Conflict Resolver${RESET}"
echo -e "${BLUE}=========================${RESET}"
echo ""

# Required ports for infrastructure
REQUIRED_PORTS=(3306 5432 2181 9092)
CONFLICTS=()

# Function to check if port is in use
port_in_use() {
    lsof -i ":$1" >/dev/null 2>&1
}

# Function to get process info for port
get_port_info() {
    lsof -i ":$1" 2>/dev/null | tail -n +2
}

# Function to kill processes on port
kill_port_processes() {
    local port="$1"
    echo -e "${YELLOW}Killing processes on port $port...${RESET}"
    
    local pids=$(lsof -ti ":$port" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        local remaining_pids=$(lsof -ti ":$port" 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            echo -e "${YELLOW}Force killing remaining processes...${RESET}"
            echo "$remaining_pids" | xargs kill -KILL 2>/dev/null || true
        fi
        
        echo -e "${GREEN}✓ Port $port cleared${RESET}"
    else
        echo -e "${GREEN}✓ Port $port already free${RESET}"
    fi
}

# Check for conflicts
echo -e "${BLUE}Checking for port conflicts...${RESET}"
echo ""

for port in "${REQUIRED_PORTS[@]}"; do
    if port_in_use "$port"; then
        CONFLICTS+=("$port")
        echo -e "${RED}✗ Port $port is in use:${RESET}"
        get_port_info "$port" | while read -r line; do
            echo -e "  ${YELLOW}$line${RESET}"
        done
        echo ""
    else
        echo -e "${GREEN}✓ Port $port is available${RESET}"
    fi
done

if [ ${#CONFLICTS[@]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 No port conflicts detected!${RESET}"
    echo -e "${CYAN}You can run: ./quick-start.sh${RESET}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Found conflicts on ports: ${CONFLICTS[*]}${RESET}"
echo ""

# Ask user what to do
echo -e "${CYAN}What would you like to do?${RESET}"
echo -e "  ${GREEN}1${RESET}) Kill conflicting processes automatically"
echo -e "  ${GREEN}2${RESET}) Show detailed process information"
echo -e "  ${GREEN}3${RESET}) Exit and handle manually"
echo ""

read -p "Choose option (1-3): " -n 1 -r choice
echo ""
echo ""

case $choice in
    1)
        echo -e "${BLUE}Killing conflicting processes...${RESET}"
        echo ""
        
        for port in "${CONFLICTS[@]}"; do
            kill_port_processes "$port"
        done
        
        echo ""
        echo -e "${GREEN}🎉 All port conflicts resolved!${RESET}"
        echo -e "${CYAN}You can now run: ./quick-start.sh${RESET}"
        ;;
        
    2)
        echo -e "${BLUE}Detailed process information:${RESET}"
        echo ""
        
        for port in "${CONFLICTS[@]}"; do
            echo -e "${CYAN}Port $port:${RESET}"
            get_port_info "$port"
            echo ""
        done
        
        echo -e "${YELLOW}To kill processes manually:${RESET}"
        for port in "${CONFLICTS[@]}"; do
            echo -e "  ${GREEN}sudo lsof -ti:$port | xargs sudo kill -9${RESET}"
        done
        ;;
        
    3)
        echo -e "${YELLOW}Manual resolution required.${RESET}"
        echo ""
        echo -e "${CYAN}Commands to resolve conflicts:${RESET}"
        for port in "${CONFLICTS[@]}"; do
            echo -e "  ${GREEN}sudo lsof -ti:$port | xargs sudo kill -9${RESET}  # Kill port $port"
        done
        echo ""
        echo -e "${CYAN}Or stop specific services:${RESET}"
        echo -e "  ${GREEN}sudo systemctl stop mysql${RESET}      # If MySQL is running"
        echo -e "  ${GREEN}sudo systemctl stop postgresql${RESET} # If PostgreSQL is running"
        echo -e "  ${GREEN}sudo systemctl stop kafka${RESET}     # If Kafka is running"
        ;;
        
    *)
        echo -e "${RED}Invalid option. Exiting.${RESET}"
        exit 1
        ;;
esac
