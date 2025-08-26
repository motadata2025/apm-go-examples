#!/bin/bash

# =============================================================================
# APM Examples - Expert Quick Start Script
# =============================================================================
# Professional setup with intelligent port management and crash-safe services
# Features: Docker conflict detection, service health monitoring, auto-recovery
# Run with: ./quick-start-expert.sh

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
    if command_exists lsof && lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
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
    wait_for_service "Zookeeper" "nc -z localhost 2181" 30
    wait_for_service "Kafka" "nc -z localhost 9092" 45
    
    # Create topics with expert configuration
    log "Creating Kafka topics with optimal configuration..."
    if [ -d "services/kafka-segmentio" ]; then
        make -C services/kafka-segmentio kafka-topics-create || warning "Topics may already exist"
    else
        # Create topics directly
        docker exec apm-kafka kafka-topics --create --topic orders --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists || true
        docker exec apm-kafka kafka-topics --create --topic payments --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists || true
    fi
    
    success "Kafka infrastructure ready"
}

# =============================================================================
# Expert Prerequisites Check
# =============================================================================

log "Step 1: Expert prerequisites validation..."

# Check Docker
if ! command_exists docker; then
    error "Docker is not installed. Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    error "Docker daemon is not running. Please start Docker and retry"
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    error "Docker Compose is not available. Please install Docker with Compose support"
    exit 1
fi

# Check Go
if ! command_exists go; then
    error "Go is not installed. Install from: https://golang.org/dl/"
    exit 1
fi

GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
log "Go version: $GO_VERSION"

# Check Make
if ! command_exists make; then
    error "Make is not installed. Install via package manager (apt install make / brew install make)"
    exit 1
fi

# System resource check
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}' 2>/dev/null || echo "unknown")
if [ "$MEMORY_GB" != "unknown" ] && [ "$MEMORY_GB" -lt 4 ]; then
    warning "Low memory detected (${MEMORY_GB}GB). Recommend 4GB+ for optimal performance"
fi

success "All prerequisites satisfied"
echo ""

# =============================================================================
# Expert Port Management
# =============================================================================

log "Step 2: Intelligent port conflict detection..."

# Only check for actual conflicts (not Docker containers)
CONFLICTS=()
for port in "${SERVICE_PORTS[@]}"; do
    if command_exists lsof && lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        # Check if it's our own service
        process=$(lsof -Pi :$port -sTCP:LISTEN | tail -n1 | awk '{print $1}')
        if [[ ! "$process" =~ (db-sql-multi|grpc-server|http-rest|kafka-producer) ]]; then
            CONFLICTS+=("$port:$process")
        fi
    fi
done

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    warning "Host process conflicts detected:"
    for conflict in "${CONFLICTS[@]}"; do
        echo -e "  ${YELLOW}Port ${conflict%:*} used by ${conflict#*:}${RESET}"
    done
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    success "No port conflicts detected"
fi
echo ""

# =============================================================================
# Expert Infrastructure Setup
# =============================================================================

log "Step 3: Setting up infrastructure with expert configuration..."

# Setup Kafka infrastructure
setup_kafka_expert

# Wait for infrastructure to be stable
sleep 5

success "Infrastructure setup complete"
echo ""

# =============================================================================
# Expert Service Build & Deployment
# =============================================================================

log "Step 4: Building services with expert configuration..."

# Build all services
make build

success "All services built successfully"
echo ""

log "Step 5: Deploying services with crash-safe management..."

# Deploy services in optimal order with health checks
for service in "${SERVICES[@]}"; do
    log "Starting $service with crash-safe management..."
    if [ -d "services/$service" ]; then
        make -C "services/$service" host

        # Verify service health
        case $service in
            "db-sql-multi")
                wait_for_service "$service" "curl -f -s http://localhost:8081/health" 30
                ;;
            "grpc-svc")
                wait_for_service "$service gRPC" "nc -z localhost 50051" 30
                wait_for_service "$service HTTP" "curl -f -s http://localhost:8083/health" 30
                ;;
            "http-rest")
                wait_for_service "$service" "curl -f -s http://localhost:8084/health" 30
                ;;
            "kafka-segmentio")
                wait_for_service "$service" "curl -f -s http://localhost:8082/health" 30
                ;;
        esac

        success "$service deployed and healthy"
    else
        warning "Service directory services/$service not found, skipping..."
    fi
done

echo ""

# =============================================================================
# Expert Verification & Status
# =============================================================================

log "Step 6: Expert verification and status check..."

# Run comprehensive health checks
make health

# Show service status
make status

echo ""
echo -e "${CYAN}🎉 Expert Setup Complete!${RESET}"
echo -e "${GREEN}================================================================${RESET}"
echo ""
echo -e "${YELLOW}Services Status:${RESET}"
echo -e "  ${GREEN}✓ Database Service:${RESET}     http://localhost:8081/health"
echo -e "  ${GREEN}✓ gRPC Service:${RESET}         grpcurl -plaintext localhost:50051 list"
echo -e "  ${GREEN}✓ gRPC HTTP Interface:${RESET}  http://localhost:8083/health"
echo -e "  ${GREEN}✓ HTTP REST API:${RESET}        http://localhost:8084/health"
echo -e "  ${GREEN}✓ Kafka Producer:${RESET}       http://localhost:8082/health"
echo ""
echo -e "${YELLOW}Management Commands:${RESET}"
echo -e "  ${CYAN}make status${RESET}             - Check all services"
echo -e "  ${CYAN}make logs${RESET}               - View all service logs"
echo -e "  ${CYAN}make health${RESET}             - Run health checks"
echo -e "  ${CYAN}make stop-all${RESET}           - Stop all services"
echo -e "  ${CYAN}make restart-all${RESET}        - Restart all services"
echo ""
echo -e "${MAGENTA}All services are running in crash-safe background mode!${RESET}"
echo -e "${BLUE}Log file: $LOG_FILE${RESET}"
