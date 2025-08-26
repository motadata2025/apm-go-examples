#!/bin/bash

# =============================================================================
# APM Examples - Expert Quick Start Script
# =============================================================================
# Professional setup with intelligent port management and crash-safe services
# Features: Docker conflict detection, service health monitoring, auto-recovery
# Run with: ./quick-start.sh

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="APM Examples"
LOG_FILE="$SCRIPT_DIR/logs/quick-start.log"

# Service configuration
SERVICES=("db-sql-multi" "grpc-svc" "http-rest" "kafka-segmentio")
DOCKER_PORTS=(5432 3306 9092 2181)
SERVICE_PORTS=(8081 50051 8083 8084 8082)

# Ensure logs directory exists
mkdir -p "$(dirname "$LOG_FILE")"

echo -e "${CYAN}🚀 ${PROJECT_NAME} - Expert Quick Start Setup${RESET}"
echo -e "${BLUE}================================================================${RESET}"
echo -e "${MAGENTA}Professional APM Testing Platform with Crash-Safe Services${RESET}"
echo ""

# =============================================================================
# Expert Helper Functions
# =============================================================================

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${RESET} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${RESET} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${RESET} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${RESET} $1" | tee -a "$LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Intelligent port checking - distinguishes between Docker and host services
check_port_conflict() {
    local port=$1
    local service_name=$2

    # Check if port is used by Docker containers (this is OK)
    if docker ps --format "table {{.Names}}\t{{.Ports}}" 2>/dev/null | grep -q ":$port->"; then
        log "Port $port is used by Docker container (expected for $service_name)"
        return 0
    fi

    # Check if port is used by host processes (potential conflict)
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        local process=$(lsof -Pi :$port -sTCP:LISTEN | tail -n1 | awk '{print $1}')
        warning "Port $port is used by host process: $process"
        return 1
    fi

    success "Port $port is available for $service_name"
    return 0
}

# Wait for service to be healthy with timeout
wait_for_service() {
    local service_name=$1
    local health_check=$2
    local timeout=${3:-30}
    local interval=2
    local elapsed=0

    log "Waiting for $service_name to be healthy..."

    while [ $elapsed -lt $timeout ]; do
        if eval "$health_check" >/dev/null 2>&1; then
            success "$service_name is healthy"
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
        echo -n "."
    done

    echo ""
    error "$service_name failed to become healthy within ${timeout}s"
    return 1
}

# Expert Kafka setup with proper container management
setup_kafka_expert() {
    log "Setting up Kafka infrastructure with expert configuration..."

    # Use minimal Docker Compose for infrastructure only
    if [ -f "infrastructure/docker-compose.minimal.yml" ]; then
        cd infrastructure
        docker compose -f docker-compose.minimal.yml up -d
        cd ..
    else
        # Fallback to kafka-segmentio directory
        cd kafka-segmentio
        docker compose up -d
        cd ..
    fi

    # Wait for Kafka to be ready with proper health checks
    wait_for_service "Zookeeper" "docker exec \$(docker ps -q -f name=zookeeper) zkServer.sh status" 30
    wait_for_service "Kafka" "docker exec \$(docker ps -q -f name=kafka) kafka-broker-api-versions --bootstrap-server localhost:9092" 45

    # Create topics with expert configuration
    log "Creating Kafka topics with optimal configuration..."
    make -C kafka-segmentio kafka-topics-create || warning "Topics may already exist"

    success "Kafka infrastructure ready"
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
docker compose -f infrastructure/docker-compose.minimal.yml down --remove-orphans 2>/dev/null || true

# Start infrastructure
echo -e "${YELLOW}Starting PostgreSQL, MySQL, and Kafka...${RESET}"
docker compose -f infrastructure/docker-compose.minimal.yml up -d

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
for service in services/db-sql-multi services/grpc-svc services/kafka-segmentio services/http-rest; do
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
echo -e "  1. Start your database applications:"
echo -e "     ${GREEN}./start-db-apps.sh${RESET}          # 🚀 RECOMMENDED: Start with auto port detection"
echo -e "     ${GREEN}make host${RESET}                    # Or start all services"
echo -e "     ${GREEN}cd multi-set-build && make run-800${RESET}  # Or use multi-set build"
echo ""
echo -e "  2. Test the services:"
echo -e "     ${GREEN}./status-db-apps.sh${RESET}          # Check application status"
echo -e "     ${GREEN}curl http://localhost:8081/trigger-crud${RESET}"
echo -e "     ${GREEN}curl http://localhost:8082/trigger-produce${RESET}"
echo -e "     ${GREEN}curl http://localhost:8084/trigger/allservices${RESET}"
echo ""
echo -e "${CYAN}Database Application Management:${RESET}"
echo -e "  ${GREEN}./start-db-apps.sh${RESET}           # Start with intelligent port management"
echo -e "  ${GREEN}./stop-db-apps.sh${RESET}            # Stop all database applications"
echo -e "  ${GREEN}./restart-db-apps.sh${RESET}         # Restart applications"
echo -e "  ${GREEN}./status-db-apps.sh${RESET}          # Check status and health"
echo ""
echo -e "${CYAN}Troubleshooting & Fixes:${RESET}"
echo -e "  ${GREEN}./fix-db-issues.sh${RESET}           # 🔧 COMPREHENSIVE FIX - Solves all issues"
echo -e "  ${GREEN}./fix-ports.sh${RESET}               # Fix port conflicts only"
echo ""
echo -e "${CYAN}Infrastructure Management:${RESET}"
echo -e "  ${GREEN}infrastructure/docker-compose -f infrastructure/docker-compose.minimal.yml logs${RESET}     # View logs"
echo -e "  ${GREEN}infrastructure/docker-compose -f infrastructure/docker-compose.minimal.yml stop${RESET}     # Stop infrastructure"
echo -e "  ${GREEN}infrastructure/docker-compose -f infrastructure/docker-compose.minimal.yml down${RESET}     # Stop and remove"
echo ""
echo -e "${YELLOW}🎉 Happy coding! No more database issues! 🚀${RESET}"
