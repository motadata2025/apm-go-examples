#!/bin/bash

# =============================================================================
# APM Examples - Setup Verification Script
# =============================================================================
# This script verifies that the project setup is complete and ready for use

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

# =============================================================================
# Helper Functions
# =============================================================================

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_file() {
    if [ -f "$1" ]; then
        success "Found: $1"
        return 0
    else
        error "Missing: $1"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        success "Found: $1/"
        return 0
    else
        error "Missing: $1/"
        return 1
    fi
}

# =============================================================================
# Verification Functions
# =============================================================================

verify_project_structure() {
    echo -e "${CYAN}Checking project structure...${NC}"
    
    local missing=0
    
    # Root files
    check_file "$PROJECT_ROOT/README.md" || ((missing++))
    check_file "$PROJECT_ROOT/.env.example" || ((missing++))
    check_file "$PROJECT_ROOT/docker-compose.yml" || ((missing++))
    check_file "$PROJECT_ROOT/Makefile" || ((missing++))
    check_file "$PROJECT_ROOT/AUDIT_REPORT.md" || ((missing++))
    
    # Service directories
    for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do
        check_dir "$PROJECT_ROOT/$service" || ((missing++))
        check_file "$PROJECT_ROOT/$service/Makefile" || ((missing++))
        check_file "$PROJECT_ROOT/$service/.env.example" || ((missing++))
        check_file "$PROJECT_ROOT/$service/go.mod" || ((missing++))
    done
    
    # Scripts directory
    check_dir "$PROJECT_ROOT/scripts" || ((missing++))
    check_file "$PROJECT_ROOT/scripts/setup.sh" || ((missing++))
    
    if [ $missing -eq 0 ]; then
        success "Project structure is complete"
    else
        error "$missing files/directories are missing"
    fi
    
    return $missing
}

verify_dockerfiles() {
    echo -e "${CYAN}Checking Docker configuration...${NC}"
    
    local missing=0
    
    # Service Dockerfiles
    check_file "$PROJECT_ROOT/db-sql-multi/Dockerfile" || ((missing++))
    check_file "$PROJECT_ROOT/grpc-svc/Dockerfile" || ((missing++))
    check_file "$PROJECT_ROOT/http-rest/Dockerfile" || ((missing++))
    check_file "$PROJECT_ROOT/kafka-segmentio/Dockerfile.producer" || ((missing++))
    check_file "$PROJECT_ROOT/kafka-segmentio/Dockerfile.consumer" || ((missing++))
    
    # Kafka Docker Compose
    check_file "$PROJECT_ROOT/kafka-segmentio/docker-compose.yml" || ((missing++))
    
    if [ $missing -eq 0 ]; then
        success "Docker configuration is complete"
    else
        error "$missing Docker files are missing"
    fi
    
    return $missing
}

verify_makefiles() {
    echo -e "${CYAN}Checking Makefile functionality...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Test root Makefile
    if make help >/dev/null 2>&1; then
        success "Root Makefile is functional"
    else
        error "Root Makefile has issues"
        return 1
    fi
    
    # Test service Makefiles
    for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do
        if make -C "$service" help >/dev/null 2>&1; then
            success "$service Makefile is functional"
        else
            error "$service Makefile has issues"
            return 1
        fi
    done
    
    return 0
}

verify_environment_files() {
    echo -e "${CYAN}Checking environment configuration...${NC}"
    
    local missing=0
    
    # Check if .env.example files exist and have content
    for env_file in \
        ".env.example" \
        "db-sql-multi/.env.example" \
        "grpc-svc/.env.example" \
        "http-rest/.env.example" \
        "kafka-segmentio/.env.example"; do
        
        if [ -f "$PROJECT_ROOT/$env_file" ] && [ -s "$PROJECT_ROOT/$env_file" ]; then
            success "Environment file: $env_file"
        else
            error "Missing or empty: $env_file"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        success "Environment configuration is complete"
    else
        error "$missing environment files are missing or empty"
    fi
    
    return $missing
}

verify_documentation() {
    echo -e "${CYAN}Checking documentation...${NC}"
    
    local missing=0
    
    # Check README files
    if [ -f "$PROJECT_ROOT/README.md" ] && [ -s "$PROJECT_ROOT/README.md" ]; then
        local readme_size=$(wc -l < "$PROJECT_ROOT/README.md")
        if [ $readme_size -gt 50 ]; then
            success "Root README.md is comprehensive ($readme_size lines)"
        else
            warning "Root README.md seems short ($readme_size lines)"
        fi
    else
        error "Root README.md is missing or empty"
        ((missing++))
    fi
    
    # Check service READMEs
    for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do
        if [ -f "$PROJECT_ROOT/$service/README.md" ] && [ -s "$PROJECT_ROOT/$service/README.md" ]; then
            success "$service README.md exists"
        else
            warning "$service README.md is missing or empty"
        fi
    done
    
    return $missing
}

verify_go_modules() {
    echo -e "${CYAN}Checking Go modules...${NC}"
    
    local issues=0
    
    for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do
        cd "$PROJECT_ROOT/$service"
        
        if [ -f "go.mod" ]; then
            if go mod verify >/dev/null 2>&1; then
                success "$service: Go modules are valid"
            else
                error "$service: Go modules have issues"
                ((issues++))
            fi
        else
            error "$service: go.mod is missing"
            ((issues++))
        fi
    done
    
    cd "$PROJECT_ROOT"
    return $issues
}

# =============================================================================
# Main Verification
# =============================================================================

main() {
    echo -e "${CYAN}APM Examples - Setup Verification${NC}"
    echo "========================================"
    echo ""
    
    local total_issues=0
    
    # Run all verification checks
    verify_project_structure || ((total_issues+=$?))
    echo ""
    
    verify_dockerfiles || ((total_issues+=$?))
    echo ""
    
    verify_makefiles || ((total_issues+=$?))
    echo ""
    
    verify_environment_files || ((total_issues+=$?))
    echo ""
    
    verify_documentation || ((total_issues+=$?))
    echo ""
    
    verify_go_modules || ((total_issues+=$?))
    echo ""
    
    # Summary
    echo "========================================"
    if [ $total_issues -eq 0 ]; then
        echo -e "${GREEN}✅ VERIFICATION PASSED${NC}"
        echo ""
        echo -e "${CYAN}Project is ready for:${NC}"
        echo "  • Git operations"
        echo "  • Docker deployment"
        echo "  • Multi-environment setup"
        echo "  • Team collaboration"
        echo ""
        echo -e "${CYAN}Next steps:${NC}"
        echo "  1. Run: ./scripts/setup.sh"
        echo "  2. Test: make quick-start"
        echo "  3. Verify: make health"
        echo ""
    else
        echo -e "${RED}❌ VERIFICATION FAILED${NC}"
        echo ""
        echo -e "${YELLOW}Found $total_issues issues that need attention${NC}"
        echo ""
        echo -e "${CYAN}Please fix the issues above and run verification again${NC}"
        echo ""
        exit 1
    fi
}

# =============================================================================
# Script Execution
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
