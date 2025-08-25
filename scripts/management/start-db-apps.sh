#!/bin/bash

# Database Applications Launcher
# This script ensures Go database applications start without port conflicts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🚀 Starting Database Applications...${RESET}"
echo ""

# Function to find available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    while lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; do
        port=$((port + 1))
    done
    echo $port
}

# Function to wait for database to be ready
wait_for_database() {
    local db_type=$1
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Waiting for $db_type to be ready...${RESET}"
    
    while [ $attempt -le $max_attempts ]; do
        if [ "$db_type" = "PostgreSQL" ]; then
            if pg_isready -h localhost -p 5432 -U testuser >/dev/null 2>&1; then
                echo -e "${GREEN}✓ PostgreSQL is ready${RESET}"
                return 0
            fi
        elif [ "$db_type" = "MySQL" ]; then
            if docker exec apm-mysql mysqladmin ping -u testuser -pTest@1234 >/dev/null 2>&1; then
                echo -e "${GREEN}✓ MySQL is ready${RESET}"
                return 0
            fi
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ $db_type failed to become ready${RESET}"
    return 1
}

# Function to test database connection
test_database_connection() {
    local db_type=$1
    
    echo -e "${YELLOW}Testing $db_type connection...${RESET}"
    
    if [ "$db_type" = "PostgreSQL" ]; then
        if psql "postgres://testuser:Test%401234@localhost:5432/testdb?sslmode=disable" -c "SELECT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ PostgreSQL connection successful${RESET}"
            return 0
        fi
    elif [ "$db_type" = "MySQL" ]; then
        if docker exec apm-mysql mysql -u testuser -pTest@1234 -D testdb -e "SELECT 1;" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ MySQL connection successful${RESET}"
            return 0
        fi
    fi
    
    echo -e "${RED}✗ $db_type connection failed${RESET}"
    return 1
}

# Function to start application with available port
start_app() {
    local app_dir=$1
    local default_port=$2
    local app_name=$3
    local description=$4
    
    echo -e "${CYAN}Starting $app_name ($description)...${RESET}"
    
    if [ ! -d "$app_dir" ]; then
        echo -e "${YELLOW}  ⚠️  $app_dir not found, skipping $app_name${RESET}"
        return 1
    fi
    
    cd "$app_dir"
    
    # Check if go.mod exists
    if [ ! -f "go.mod" ]; then
        echo -e "${YELLOW}  ⚠️  No go.mod found in $app_dir, skipping $app_name${RESET}"
        cd ..
        return 1
    fi
    
    # Find available port
    available_port=$(find_available_port $default_port)
    
    if [ "$available_port" != "$default_port" ]; then
        echo -e "${YELLOW}  Port $default_port in use, using port $available_port instead${RESET}"
    fi
    
    # Ensure dependencies are up to date
    echo -e "${YELLOW}  Updating dependencies...${RESET}"
    go mod tidy >/dev/null 2>&1
    
    # Set environment variables
    export PORT=$available_port
    export HTTP_PORT=$available_port
    export MYSQL_DSN="testuser:Test@1234@tcp(127.0.0.1:3306)/testdb?parseTime=true"
    export PG_DSN="postgres://testuser:Test%401234@127.0.0.1:5432/testdb?sslmode=disable"
    
    # Start the application
    echo -e "${YELLOW}  Starting application...${RESET}"
    nohup go run cmd/app/main.go > "../../runtime/logs/${app_name}.log" 2>&1 &
    local pid=$!
    echo $pid > "../../runtime/logs/${app_name}.pid"
    
    # Wait a moment for the app to start
    sleep 3
    
    # Check if the process is still running
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${GREEN}  ✓ $app_name started successfully on port $available_port (PID: $pid)${RESET}"
        echo "$available_port" > "../../runtime/logs/${app_name}.port"
        
        # Test the endpoint
        if curl -s "http://localhost:$available_port/health" >/dev/null 2>&1 || \
           curl -s "http://localhost:$available_port/" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✓ Health check passed${RESET}"
        else
            echo -e "${YELLOW}  ⚠️  Health check failed, but service is running${RESET}"
        fi
    else
        echo -e "${RED}  ✗ $app_name failed to start${RESET}"
        echo -e "${YELLOW}  Check logs: tail -f runtime/logs/${app_name}.log${RESET}"
        rm -f "../../runtime/logs/${app_name}.pid"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Create logs directory
mkdir -p logs

# Check if infrastructure is running
echo -e "${BLUE}Step 1: Checking infrastructure status...${RESET}"

if ! docker ps | grep -q apm-postgres; then
    echo -e "${RED}✗ PostgreSQL container not running${RESET}"
    echo -e "${YELLOW}Please run: make infra-only${RESET}"
    exit 1
fi

if ! docker ps | grep -q apm-mysql; then
    echo -e "${RED}✗ MySQL container not running${RESET}"
    echo -e "${YELLOW}Please run: make infra-only${RESET}"
    exit 1
fi

echo -e "${GREEN}✓ Infrastructure containers are running${RESET}"
echo ""

# Wait for databases to be ready
echo -e "${BLUE}Step 2: Waiting for databases to be ready...${RESET}"
wait_for_database "PostgreSQL"
wait_for_database "MySQL"
echo ""

# Test database connections
echo -e "${BLUE}Step 3: Testing database connections...${RESET}"
test_database_connection "PostgreSQL"
test_database_connection "MySQL"
echo ""

# Start database applications
echo -e "${BLUE}Step 4: Starting database applications...${RESET}"
start_app "services/db-sql-multi" 8001 "db-sql-multi" "Multi-database SQL operations"
start_app "db-gorm" 8005 "db-gorm" "GORM ORM operations"
echo ""

# Display status
echo -e "${GREEN}🎯 Database Applications Status:${RESET}"
echo ""

if [ -f "runtime/logs/db-sql-multi.pid" ] && [ -f "runtime/logs/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/db-sql-multi.port)
    echo -e "  ✅ ${CYAN}DB SQL Multi:${RESET} http://localhost:$port"
    echo -e "     Test: ${GREEN}curl http://localhost:$port/trigger-crud${RESET}"
fi

if [ -f "runtime/logs/db-gorm.pid" ] && [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  ✅ ${CYAN}DB GORM:${RESET} http://localhost:$port"
    echo -e "     Test: ${GREEN}curl http://localhost:$port/health${RESET}"
fi

echo ""
echo -e "${CYAN}📋 Management Commands:${RESET}"
echo -e "  ${GREEN}./stop-db-apps.sh${RESET}    # Stop all database applications"
echo -e "  ${GREEN}./restart-db-apps.sh${RESET} # Restart all database applications"
echo -e "  ${GREEN}tail -f runtime/logs/*.log${RESET}   # View application logs"
echo -e "  ${GREEN}./status-db-apps.sh${RESET}  # Check application status"
echo ""
echo -e "${GREEN}🎉 Database applications are ready!${RESET}"
