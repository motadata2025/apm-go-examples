#!/bin/bash

# =============================================================================
# APM Examples - Complete Setup Script
# =============================================================================
# This script sets up the complete development environment for APM Examples
# Run with: ./scripts/setup.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/setup.log"

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        success "$1 is installed"
        return 0
    else
        error "$1 is not installed"
        return 1
    fi
}

check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        warning "Port $1 is already in use"
        return 1
    else
        success "Port $1 is available"
        return 0
    fi
}

# =============================================================================
# Main Setup Function
# =============================================================================

main() {
    log "Starting APM Examples setup..."
    echo "Setup log: $LOG_FILE"
    echo ""

    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "APM Examples Setup Log - $(date)" > "$LOG_FILE"

    # Check prerequisites
    check_prerequisites

    # Setup environment files
    setup_environment_files

    # Setup databases
    setup_databases

    # Setup Kafka infrastructure
    setup_kafka

    # Build all services
    build_services

    # Setup systemd services (optional)
    setup_systemd_services

    # Final verification
    verify_setup

    success "Setup completed successfully!"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Start all services: make quick-start"
    echo "2. Check status: make status"
    echo "3. View logs: make logs"
    echo "4. Test APIs: make health"
    echo ""
    echo -e "${CYAN}Documentation:${NC}"
    echo "- Project README: ./README.md"
    echo "- Service docs: ./*/README.md"
    echo "- API examples: make -C http-rest curl-examples"
}

# =============================================================================
# Prerequisites Check
# =============================================================================

check_prerequisites() {
    log "Checking prerequisites..."

    local missing_deps=()

    # Check required commands
    if ! check_command "go"; then
        missing_deps+=("go")
    fi

    if ! check_command "make"; then
        missing_deps+=("make")
    fi

    if ! check_command "docker"; then
        missing_deps+=("docker")
    fi

    if ! check_command "docker-compose" && ! check_command "docker compose"; then
        missing_deps+=("docker-compose")
    fi

    if ! check_command "curl"; then
        missing_deps+=("curl")
    fi

    # Check Go version
    if command -v go >/dev/null 2>&1; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        if [[ $(echo "$GO_VERSION 1.21" | tr " " "\n" | sort -V | head -n1) != "1.21" ]]; then
            success "Go version $GO_VERSION is compatible"
        else
            warning "Go version $GO_VERSION may be too old (recommended: 1.21+)"
        fi
    fi

    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            success "Docker is running"
        else
            warning "Docker is installed but not running"
            echo "Please start Docker and run this script again"
        fi
    fi

    # Report missing dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the missing dependencies and run this script again."
        echo ""
        echo "Installation guides:"
        echo "- Go: https://golang.org/dl/"
        echo "- Docker: https://docs.docker.com/get-docker/"
        echo "- Make: Usually available via package manager (apt, yum, brew)"
        exit 1
    fi

    success "All prerequisites are satisfied"
}

# =============================================================================
# Environment Files Setup
# =============================================================================

setup_environment_files() {
    log "Setting up environment files..."

    cd "$PROJECT_ROOT"

    # Copy root environment file
    if [ ! -f ".env" ]; then
        cp ".env.example" ".env"
        success "Created root .env file"
    else
        warning "Root .env file already exists"
    fi

    # Copy service environment files
    for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do
        if [ ! -f "$service/.env" ]; then
            cp "$service/.env.example" "$service/.env"
            success "Created $service/.env file"
        else
            warning "$service/.env file already exists"
        fi
    done
}

# =============================================================================
# Database Setup
# =============================================================================

setup_databases() {
    log "Setting up databases..."

    # Check if PostgreSQL is available
    if command -v psql >/dev/null 2>&1; then
        success "PostgreSQL client is available"
    else
        warning "PostgreSQL client not found - will use Docker"
        setup_postgres_docker
    fi

    # Check if MySQL is available
    if command -v mysql >/dev/null 2>&1; then
        success "MySQL client is available"
    else
        warning "MySQL client not found - will use Docker"
        setup_mysql_docker
    fi
}

setup_postgres_docker() {
    log "Setting up PostgreSQL with Docker..."
    
    if ! docker ps | grep -q postgres-apm; then
        docker run --name postgres-apm \
            -e POSTGRES_USER=testuser \
            -e POSTGRES_PASSWORD=Test@1234 \
            -e POSTGRES_DB=testdb \
            -p 5432:5432 \
            -d postgres:15
        
        success "PostgreSQL container started"
        sleep 5  # Wait for PostgreSQL to start
    else
        success "PostgreSQL container already running"
    fi
}

setup_mysql_docker() {
    log "Setting up MySQL with Docker..."
    
    if ! docker ps | grep -q mysql-apm; then
        docker run --name mysql-apm \
            -e MYSQL_ROOT_PASSWORD=rootpass \
            -e MYSQL_DATABASE=testdb \
            -p 3306:3306 \
            -d mysql:8
        
        success "MySQL container started"
        sleep 10  # Wait for MySQL to start
    else
        success "MySQL container already running"
    fi
}

# =============================================================================
# Kafka Setup
# =============================================================================

setup_kafka() {
    log "Setting up Kafka infrastructure..."

    cd "$PROJECT_ROOT/kafka-segmentio"

    # Start Kafka with Docker Compose
    if docker-compose ps | grep -q kafka; then
        success "Kafka is already running"
    else
        docker-compose up -d
        success "Kafka infrastructure started"
        sleep 15  # Wait for Kafka to be ready
    fi

    # Create topics
    make kafka-topics-create || warning "Failed to create Kafka topics (may already exist)"
}

# =============================================================================
# Build Services
# =============================================================================

build_services() {
    log "Building all services..."

    cd "$PROJECT_ROOT"

    # Build all services
    make build

    success "All services built successfully"
}

# =============================================================================
# Systemd Services Setup (Optional)
# =============================================================================

setup_systemd_services() {
    if [ "$EUID" -eq 0 ]; then
        log "Setting up systemd services..."
        # This would set up systemd services for production deployment
        warning "Systemd setup skipped (run as non-root user)"
    else
        log "Skipping systemd setup (requires root privileges)"
    fi
}

# =============================================================================
# Verification
# =============================================================================

verify_setup() {
    log "Verifying setup..."

    # Check ports
    local ports=(5432 3306 9092 2181)
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            success "Port $port is listening"
        else
            warning "Port $port is not listening"
        fi
    done

    # Check if binaries were built
    for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do
        if [ -d "$PROJECT_ROOT/$service/bin" ] && [ "$(ls -A "$PROJECT_ROOT/$service/bin")" ]; then
            success "$service binary built"
        else
            warning "$service binary not found"
        fi
    done
}

# =============================================================================
# Script Execution
# =============================================================================

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
