#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="APM Examples"

echo -e "${CYAN}🚀 ${PROJECT_NAME} - Quick Start Setup${RESET}"
echo -e "${BLUE}================================================${RESET}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is available
port_available() {
    ! nc -z localhost "$1" 2>/dev/null
}

# Function to wait for service
wait_for_service() {
    local service="$1"
    local port="$2"
    local max_attempts=30
    local attempt=1
    
    echo -e "${YELLOW}Waiting for $service on port $port...${RESET}"
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost "$port" 2>/dev/null; then
            echo -e "${GREEN}✓ $service is ready!${RESET}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ $service failed to start within $((max_attempts * 2)) seconds${RESET}"
    return 1
}

# Check prerequisites
echo -e "${BLUE}Step 1: Checking prerequisites...${RESET}"

if ! command_exists docker; then
    echo -e "${RED}✗ Docker is not installed${RESET}"
    echo -e "${YELLOW}Please install Docker: https://docs.docker.com/get-docker/${RESET}"
    exit 1
fi

if ! command_exists docker || ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker Compose is not available${RESET}"
    echo -e "${YELLOW}Please install Docker with Compose: https://docs.docker.com/get-docker/${RESET}"
    exit 1
fi

if ! command_exists go; then
    echo -e "${RED}✗ Go is not installed${RESET}"
    echo -e "${YELLOW}Please install Go: https://golang.org/doc/install${RESET}"
    exit 1
fi

if ! command_exists nc; then
    echo -e "${YELLOW}⚠ netcat (nc) not found, installing...${RESET}"
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y netcat
    elif command_exists yum; then
        sudo yum install -y nc
    elif command_exists brew; then
        brew install netcat
    else
        echo -e "${RED}✗ Please install netcat manually${RESET}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ All prerequisites satisfied${RESET}"
echo ""

# Check for port conflicts
echo -e "${BLUE}Step 2: Checking for port conflicts...${RESET}"

REQUIRED_PORTS=(3306 5432 2181 9092)
CONFLICTS=()

for port in "${REQUIRED_PORTS[@]}"; do
    if ! port_available "$port"; then
        CONFLICTS+=("$port")
    fi
done

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Port conflicts detected: ${CONFLICTS[*]}${RESET}"
    echo -e "${YELLOW}Please stop services using these ports or run:${RESET}"
    echo -e "${CYAN}  sudo lsof -ti:${CONFLICTS[0]} | xargs sudo kill -9${RESET}"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ All required ports are available${RESET}"
fi
echo ""

# Start infrastructure
echo -e "${BLUE}Step 3: Starting infrastructure services...${RESET}"

cd "$SCRIPT_DIR"

# Stop any existing containers
echo -e "${YELLOW}Stopping any existing containers...${RESET}"
docker compose -f docker-compose.minimal.yml down --remove-orphans 2>/dev/null || true

# Start infrastructure
echo -e "${YELLOW}Starting PostgreSQL, MySQL, and Kafka...${RESET}"
docker compose -f docker-compose.minimal.yml up -d

# Wait for services to be ready
echo ""
echo -e "${BLUE}Step 4: Waiting for services to be ready...${RESET}"

wait_for_service "PostgreSQL" 5432
wait_for_service "MySQL" 3306
wait_for_service "Kafka" 9092

echo ""

# Create Kafka topics
echo -e "${BLUE}Step 5: Creating Kafka topics...${RESET}"
sleep 5  # Give Kafka a moment to fully initialize

docker exec apm-kafka kafka-topics --create --topic orders --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists
docker exec apm-kafka kafka-topics --create --topic payments --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists

echo -e "${GREEN}✓ Kafka topics created${RESET}"
echo ""

# Build Go applications
echo -e "${BLUE}Step 6: Building Go applications...${RESET}"

# Build each service
for service in db-sql-multi grpc-svc kafka-segmentio http-rest; do
    echo -e "${YELLOW}Building $service...${RESET}"
    cd "$SCRIPT_DIR/$service"
    make build 2>/dev/null || go mod tidy && go build -o bin/ ./cmd/...
    cd "$SCRIPT_DIR"
done

echo -e "${GREEN}✓ All Go applications built${RESET}"
echo ""

# Success message
echo -e "${GREEN}🎉 Setup Complete!${RESET}"
echo -e "${BLUE}================================================${RESET}"
echo ""
echo -e "${CYAN}Infrastructure Services Running:${RESET}"
echo -e "  📊 PostgreSQL:  ${GREEN}localhost:5432${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📊 MySQL:       ${GREEN}localhost:3306${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📨 Kafka:       ${GREEN}localhost:9092${RESET} (topics: orders, payments)"
echo -e "  🔧 Adminer:     ${GREEN}http://localhost:8080${RESET} (database admin)"
echo ""
echo -e "${CYAN}Next Steps:${RESET}"
echo -e "  1. Start your Go applications:"
echo -e "     ${GREEN}make host${RESET}                    # Start all services"
echo -e "     ${GREEN}cd multi-set-build && make run-800${RESET}  # Or use multi-set build"
echo ""
echo -e "  2. Test the services:"
echo -e "     ${GREEN}curl http://localhost:8081/trigger-crud${RESET}"
echo -e "     ${GREEN}curl http://localhost:8082/trigger-produce${RESET}"
echo -e "     ${GREEN}curl http://localhost:8084/trigger/allservices${RESET}"
echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}docker-compose -f docker-compose.minimal.yml logs${RESET}     # View logs"
echo -e "  ${GREEN}docker-compose -f docker-compose.minimal.yml stop${RESET}     # Stop infrastructure"
echo -e "  ${GREEN}docker-compose -f docker-compose.minimal.yml down${RESET}     # Stop and remove"
echo ""
echo -e "${YELLOW}Happy coding! 🚀${RESET}"
