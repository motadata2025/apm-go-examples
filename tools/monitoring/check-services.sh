#!/bin/bash

# =============================================================================
# APM Examples - Expert Service Monitoring Script
# =============================================================================
# Professional service monitoring with detailed process information
# Run with: ./tools/monitoring/check-services.sh

set -euo pipefail

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
RESET='\033[0m'

# Configuration
SERVICES=("db-sql-multi" "grpc-server" "grpc-client" "http-rest-api" "kafka-producer")
SERVICE_PORTS=(8081 50051 8083 8084 8082)
PID_DIRS=("services/db-sql-multi/pids" "services/grpc-svc/pids" "services/grpc-svc/pids" "services/http-rest/pids" "services/kafka-segmentio/pids")

echo -e "${CYAN}🔍 APM Examples - Expert Service Monitor${RESET}"
echo -e "${BLUE}================================================${RESET}"
echo ""

# =============================================================================
# Helper Functions
# =============================================================================

format_memory() {
    local kb=$1
    if [ $kb -gt 1048576 ]; then
        echo "$(( kb / 1048576 ))GB"
    elif [ $kb -gt 1024 ]; then
        echo "$(( kb / 1024 ))MB"
    else
        echo "${kb}KB"
    fi
}

format_uptime() {
    local seconds=$1
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local minutes=$(((seconds % 3600) / 60))

    if [ $days -gt 0 ]; then
        echo "${days}d ${hours}h ${minutes}m"
    elif [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

check_service_health() {
    local service=$1
    local port=$2

    case $service in
        "db-sql-multi")
            curl -f -s http://localhost:$port/health >/dev/null 2>&1
            ;;
        "grpc-server")
            if command -v grpc_health_probe >/dev/null 2>&1; then
                grpc_health_probe -addr=localhost:$port >/dev/null 2>&1
            else
                nc -z localhost $port >/dev/null 2>&1
            fi
            ;;
        "grpc-client"|"http-rest-api"|"kafka-producer")
            curl -f -s http://localhost:$port/health >/dev/null 2>&1
            ;;
        *)
            nc -z localhost $port >/dev/null 2>&1
            ;;
    esac
}

get_service_name() {
    local port=$1
    case $port in
        8081) echo "db-sql-multi" ;;
        50051) echo "grpc-server" ;;
        8083) echo "grpc-client" ;;
        8084) echo "http-rest-api" ;;
        8082) echo "kafka-producer" ;;
        5432) echo "postgresql" ;;
        3306) echo "mysql" ;;
        9092) echo "kafka" ;;
        2181) echo "zookeeper" ;;
        *) echo "unknown" ;;
    esac
}

# =============================================================================
# Service Status Check
# =============================================================================

echo -e "${YELLOW}Service Status Overview:${RESET}"
printf "%-20s %-8s %-10s %-10s %-12s %-10s %s\n" "SERVICE" "STATUS" "PID" "PORT" "MEMORY" "UPTIME" "HEALTH"
echo "----------------------------------------------------------------------------------------"

for i in "${!SERVICES[@]}"; do
    service="${SERVICES[$i]}"
    if [ $i -lt ${#SERVICE_PORTS[@]} ]; then
        port="${SERVICE_PORTS[$i]}"
    else
        port="N/A"
    fi
    if [ $i -lt ${#PID_DIRS[@]} ]; then
        pid_dir="${PID_DIRS[$i]}"
    else
        pid_dir="pids"
    fi
    pid_file="$pid_dir/$service.pid"

    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")

        if kill -0 "$pid" 2>/dev/null; then
            # Process is running
            status="${GREEN}RUNNING${RESET}"

            # Get process information
            if [ -f "/proc/$pid/stat" ]; then
                # Memory usage (RSS in KB)
                memory_kb=$(awk '{print $24}' "/proc/$pid/stat" 2>/dev/null || echo "0")
                memory_kb=$((memory_kb * 4)) # Convert pages to KB
                memory=$(format_memory $memory_kb)

                # Uptime
                start_time=$(awk '{print $22}' "/proc/$pid/stat" 2>/dev/null || echo "0")
                boot_time=$(awk '/btime/ {print $2}' /proc/stat 2>/dev/null || echo "0")
                current_time=$(date +%s)
                uptime_seconds=$((current_time - boot_time - start_time / 100))
                uptime=$(format_uptime $uptime_seconds)
            else
                memory="N/A"
                uptime="N/A"
            fi

            # Health check
            if check_service_health "$service" "$port"; then
                health="${GREEN}HEALTHY${RESET}"
            else
                health="${YELLOW}DEGRADED${RESET}"
            fi
        else
            # PID file exists but process is dead
            status="${RED}DEAD${RESET}"
            memory="N/A"
            uptime="N/A"
            health="${RED}FAILED${RESET}"
            pid="(stale)"
        fi
    else
        # No PID file
        status="${YELLOW}STOPPED${RESET}"
        pid="N/A"
        memory="N/A"
        uptime="N/A"
        health="${YELLOW}N/A${RESET}"
    fi

    printf "%-30s %-18s %-10s %-10s %-12s %-10s %s\n" "$service" "$status" "$pid" "$port" "$memory" "$uptime" "$health"
done

echo ""

# =============================================================================
# Docker Infrastructure Status
# =============================================================================

echo -e "${YELLOW}Docker Infrastructure Status:${RESET}"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(kafka|zookeeper|postgres|mysql)" || echo "No infrastructure containers running"
else
    echo -e "${RED}Docker not available${RESET}"
fi

echo ""

# =============================================================================
# Port Usage Summary
# =============================================================================

echo -e "${YELLOW}Port Usage Summary:${RESET}"
printf "%-10s %-20s %-15s %s\n" "PORT" "SERVICE" "STATUS" "PROCESS"
echo "---------------------------------------------------------------"

for port in "${SERVICE_PORTS[@]}" 5432 3306 9092 2181; do
    if command -v lsof >/dev/null 2>&1; then
        port_info=$(lsof -Pi :$port -sTCP:LISTEN 2>/dev/null | tail -n +2)
        if [ -n "$port_info" ]; then
            process=$(echo "$port_info" | awk '{print $1}' | head -1)
            pid=$(echo "$port_info" | awk '{print $2}' | head -1)
            status="${GREEN}LISTENING${RESET}"
            printf "%-10s %-20s %-25s %s (PID: %s)\n" "$port" "$(get_service_name $port)" "$status" "$process" "$pid"
        fi
    else
        if nc -z localhost $port 2>/dev/null; then
            printf "%-10s %-20s %-25s %s\n" "$port" "$(get_service_name $port)" "${GREEN}LISTENING${RESET}" "Unknown"
        fi
    fi
done

echo ""

# =============================================================================
# System Resource Summary
# =============================================================================

echo -e "${YELLOW}System Resource Summary:${RESET}"

# Memory usage
if [ -f /proc/meminfo ]; then
    total_mem=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    avail_mem=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    used_mem=$((total_mem - avail_mem))
    mem_percent=$((used_mem * 100 / total_mem))

    echo -e "Memory: $(format_memory $used_mem) / $(format_memory $total_mem) (${mem_percent}%)"
fi

# CPU load
if [ -f /proc/loadavg ]; then
    load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    echo -e "Load Average: $load"
fi

# Disk usage for current directory
disk_usage=$(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
echo -e "Disk Usage: $disk_usage"

echo ""

# =============================================================================
# Quick Actions
# =============================================================================

echo -e "${CYAN}Quick Actions:${RESET}"
echo -e "  ${GREEN}make status${RESET}        - Detailed service status"
echo -e "  ${GREEN}make health${RESET}        - Run health checks"
echo -e "  ${GREEN}make logs${RESET}          - View service logs"
echo -e "  ${GREEN}make restart-all${RESET}   - Restart all services"
echo -e "  ${GREEN}make stop-all${RESET}      - Stop all services"
