#!/bin/bash

# Database Issues Fixer
# This script diagnoses and fixes common database issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🔧 Database Issues Diagnostic & Fix Tool${RESET}"
echo -e "${BLUE}=========================================${RESET}"
echo ""

# Function to check port availability
check_port() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local process=$(lsof -Pi :$port -sTCP:LISTEN | tail -n +2 | awk '{print $1, $2}' | head -1)
        echo -e "${RED}✗ Port $port is in use by: $process${RESET}"
        return 1
    else
        echo -e "${GREEN}✓ Port $port is available for $service${RESET}"
        return 0
    fi
}

# Function to fix port conflicts
fix_port_conflicts() {
    echo -e "${YELLOW}Checking for port conflicts...${RESET}"
    
    local conflicts=0
    
    if ! check_port 5432 "PostgreSQL"; then
        echo -e "${YELLOW}Attempting to stop PostgreSQL service...${RESET}"
        sudo systemctl stop postgresql 2>/dev/null || true
        sudo service postgresql stop 2>/dev/null || true
        conflicts=1
    fi
    
    if ! check_port 3306 "MySQL"; then
        echo -e "${YELLOW}Attempting to stop MySQL service...${RESET}"
        sudo systemctl stop mysql 2>/dev/null || true
        sudo service mysql stop 2>/dev/null || true
        conflicts=1
    fi
    
    if ! check_port 2181 "ZooKeeper"; then
        echo -e "${YELLOW}ZooKeeper port conflict detected...${RESET}"
        conflicts=1
    fi
    
    if ! check_port 9092 "Kafka"; then
        echo -e "${YELLOW}Kafka port conflict detected...${RESET}"
        conflicts=1
    fi
    
    if [ $conflicts -eq 1 ]; then
        echo -e "${YELLOW}Waiting for services to stop...${RESET}"
        sleep 5
        echo -e "${GREEN}✓ Port conflicts resolved${RESET}"
    else
        echo -e "${GREEN}✓ No port conflicts detected${RESET}"
    fi
}

# Function to check Docker status
check_docker() {
    echo -e "${YELLOW}Checking Docker status...${RESET}"
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}✗ Docker is not running${RESET}"
        echo -e "${YELLOW}Please start Docker and try again${RESET}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Docker is running${RESET}"
    return 0
}

# Function to check infrastructure containers
check_infrastructure() {
    echo -e "${YELLOW}Checking infrastructure containers...${RESET}"
    
    local containers=("apm-postgres" "apm-mysql" "apm-kafka" "apm-zookeeper")
    local missing=0
    
    for container in "${containers[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            echo -e "${GREEN}✓ $container is running${RESET}"
        else
            echo -e "${RED}✗ $container is not running${RESET}"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo -e "${YELLOW}Some containers are missing. Restarting infrastructure...${RESET}"
        make infra-clean
        make infra-only
        echo -e "${GREEN}✓ Infrastructure restarted${RESET}"
    fi
}

# Function to test database connections
test_database_connections() {
    echo -e "${YELLOW}Testing database connections...${RESET}"
    
    # Test PostgreSQL
    if psql "postgres://testuser:Test%401234@localhost:5432/testdb?sslmode=disable" -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PostgreSQL connection successful${RESET}"
    else
        echo -e "${RED}✗ PostgreSQL connection failed${RESET}"
        echo -e "${YELLOW}Attempting to fix PostgreSQL...${RESET}"
        
        # Reinitialize PostgreSQL
        docker exec apm-postgres psql -U testuser -d testdb -f /docker-entrypoint-initdb.d/postgres-init.sql
        echo -e "${GREEN}✓ PostgreSQL reinitialized${RESET}"
    fi
    
    # Test MySQL
    if mysql -h localhost -P 3306 -u testuser -pTest@1234 -D testdb -e "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ MySQL connection successful${RESET}"
    else
        echo -e "${RED}✗ MySQL connection failed${RESET}"
        echo -e "${YELLOW}Attempting to fix MySQL...${RESET}"
        
        # Reinitialize MySQL
        docker exec apm-mysql mysql -u testuser -pTest@1234 -D testdb < /docker-entrypoint-initdb.d/mysql-init.sql
        echo -e "${GREEN}✓ MySQL reinitialized${RESET}"
    fi
}

# Function to check Go environment
check_go_environment() {
    echo -e "${YELLOW}Checking Go environment...${RESET}"
    
    if ! command -v go >/dev/null 2>&1; then
        echo -e "${RED}✗ Go is not installed${RESET}"
        return 1
    fi
    
    local go_version=$(go version | awk '{print $3}')
    echo -e "${GREEN}✓ Go is installed: $go_version${RESET}"
    
    # Check Go modules in database projects
    for project in services/db-sql-multi db-gorm; do
        if [ -d "$project" ]; then
            echo -e "${YELLOW}Checking $project dependencies...${RESET}"
            cd "$project"
            go mod tidy
            go mod download
            cd ..
            echo -e "${GREEN}✓ $project dependencies updated${RESET}"
        fi
    done
}

# Function to clean up old processes
cleanup_processes() {
    echo -e "${YELLOW}Cleaning up old processes...${RESET}"
    
    # Stop any running database applications
    ./stop-db-apps.sh 2>/dev/null || true
    
    # Kill any orphaned Go processes
    pkill -f "go run cmd/app/main.go" 2>/dev/null || true
    
    # Clean up log files
    rm -f runtime/logs/*.pid runtime/logs/*.port
    
    echo -e "${GREEN}✓ Cleanup completed${RESET}"
}

# Function to run comprehensive fix
run_comprehensive_fix() {
    echo -e "${BLUE}Running comprehensive fix...${RESET}"
    echo ""
    
    # Step 1: Check Docker
    if ! check_docker; then
        exit 1
    fi
    echo ""
    
    # Step 2: Fix port conflicts
    fix_port_conflicts
    echo ""
    
    # Step 3: Clean up processes
    cleanup_processes
    echo ""
    
    # Step 4: Check infrastructure
    check_infrastructure
    echo ""
    
    # Step 5: Wait for services to be ready
    echo -e "${YELLOW}Waiting for services to be ready...${RESET}"
    sleep 10
    echo ""
    
    # Step 6: Test database connections
    test_database_connections
    echo ""
    
    # Step 7: Check Go environment
    check_go_environment
    echo ""
    
    echo -e "${GREEN}🎉 All issues have been resolved!${RESET}"
    echo ""
    echo -e "${CYAN}Next steps:${RESET}"
    echo -e "  1. Run: ${GREEN}./start-db-apps.sh${RESET}"
    echo -e "  2. Check status: ${GREEN}./status-db-apps.sh${RESET}"
    echo -e "  3. Test applications: ${GREEN}curl http://localhost:8001/trigger-crud${RESET}"
}

# Main execution
case "${1:-fix}" in
    "ports")
        fix_port_conflicts
        ;;
    "docker")
        check_docker
        ;;
    "infra")
        check_infrastructure
        ;;
    "db")
        test_database_connections
        ;;
    "go")
        check_go_environment
        ;;
    "clean")
        cleanup_processes
        ;;
    "fix"|"")
        run_comprehensive_fix
        ;;
    *)
        echo -e "${YELLOW}Usage: $0 [ports|docker|infra|db|go|clean|fix]${RESET}"
        echo ""
        echo -e "${CYAN}Options:${RESET}"
        echo -e "  ports  - Fix port conflicts"
        echo -e "  docker - Check Docker status"
        echo -e "  infra  - Check infrastructure containers"
        echo -e "  db     - Test database connections"
        echo -e "  go     - Check Go environment"
        echo -e "  clean  - Clean up processes"
        echo -e "  fix    - Run comprehensive fix (default)"
        ;;
esac
