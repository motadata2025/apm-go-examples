# =============================================================================
# APM Examples - Master Makefile
# =============================================================================

# Project configuration
PROJECT_NAME := apm-examples
SERVICES := services/db-sql-multi services/grpc-svc services/http-rest services/kafka-segmentio

# Service directories and ports
DB_SQL_DIR := services/db-sql-multi
GRPC_DIR := services/grpc-svc
HTTP_DIR := services/http-rest
KAFKA_DIR := services/kafka-segmentio

# Service ports
DB_SQL_PORT := 8081
GRPC_PORT := 50051
HTTP_PORT := 8084
KAFKA_PRODUCER_PORT := 8082
KAFKA_CONSUMER_PORT := 8083

# Build configuration
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m
RESET := \033[0m

# =============================================================================
# Help Target
# =============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(CYAN)🚀 APM Examples - Complete Development Platform$(RESET)"
	@echo ""
	@echo "$(BLUE)🎯 QUICK START (Recommended):$(RESET)"
	@echo "  $(GREEN)./quick-start.sh$(RESET)         🚀 Zero-config setup - Run this first!"
	@echo "  $(GREEN)./start-db-apps.sh$(RESET)       Start database applications"
	@echo "  $(GREEN)./status-db-apps.sh$(RESET)      Check application status"
	@echo ""
	@echo "$(BLUE)🌐 PUBLIC ACCESS:$(RESET)"
	@echo "  $(GREEN)./setup-machine-ip-access.sh$(RESET)  Configure for network access"
	@echo "  $(GREEN)./start-machine-ip-apps.sh$(RESET)    Start with machine IP"
	@echo "  $(GREEN)./test-machine-ip-apps.sh$(RESET)     Test network accessibility"
	@echo ""
	@echo "$(BLUE)🔧 INFRASTRUCTURE:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-25s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(infra|docker)"
	@echo ""
	@echo "$(BLUE)🛠️ BUILD & DEVELOPMENT:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-25s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(build|cross|dist|test|fmt|lint)"
	@echo ""
	@echo "$(BLUE)🎮 SERVICE MANAGEMENT:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-25s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(host|start|stop|restart|status|health)"
	@echo ""
	@echo "$(BLUE)🧹 UTILITIES:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-25s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(clean|deps|mod|install|fix)"
	@echo ""
	@echo "$(YELLOW)📊 CURRENT SERVICES:$(RESET)"
	@echo "  $(MAGENTA)Database Service$(RESET)     Multi-database operations (PostgreSQL & MySQL)"
	@echo "  $(MAGENTA)gRPC Service$(RESET)         High-performance RPC communication"
	@echo "  $(MAGENTA)HTTP REST API$(RESET)        RESTful web services"
	@echo "  $(MAGENTA)Kafka Services$(RESET)       Event streaming and messaging"
	@echo ""
	@echo "$(CYAN)💡 TIPS:$(RESET)"
	@echo "  • Start with: $(GREEN)./quick-start.sh$(RESET)"
	@echo "  • For network access: $(GREEN)./setup-machine-ip-access.sh$(RESET)"
	@echo "  • Troubleshooting: $(GREEN)./fix-db-issues.sh$(RESET)"
	@echo "  • Individual service help: $(GREEN)make -C <service> help$(RESET)"

# =============================================================================
# Setup and Dependencies
# =============================================================================

.PHONY: setup
setup: ## Setup all project directories and dependencies
	@echo "$(BLUE)Setting up all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Setting up $$service...$(RESET)"; \
		$(MAKE) -C $$service setup; \
	done
	@echo "$(GREEN)✓ All services setup complete$(RESET)"

.PHONY: deps
deps: ## Download and verify dependencies for all services
	@echo "$(BLUE)Downloading dependencies for all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Dependencies for $$service...$(RESET)"; \
		$(MAKE) -C $$service deps; \
	done
	@echo "$(GREEN)✓ All dependencies ready$(RESET)"

.PHONY: mod-tidy
mod-tidy: ## Clean up go.mod and go.sum for all services
	@echo "$(BLUE)Tidying modules for all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Tidying $$service...$(RESET)"; \
		$(MAKE) -C $$service mod-tidy; \
	done
	@echo "$(GREEN)✓ All modules tidied$(RESET)"

# =============================================================================
# Build Targets
# =============================================================================

.PHONY: build
build: ## Build all services (production standards)
	@echo "$(BLUE)Building all services...$(RESET)"
	@echo "$(YELLOW)Version: $(VERSION)$(RESET)"
	@echo "$(YELLOW)Build Time: $(BUILD_TIME)$(RESET)"
	@echo "$(YELLOW)Git Commit: $(GIT_COMMIT)$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service...$(RESET)"; \
		$(MAKE) -C $$service build; \
	done
	@echo "$(GREEN)✓ All services built successfully$(RESET)"

.PHONY: build-dev
build-dev: ## Build all services for development
	@echo "$(BLUE)Building all services for development...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service (dev)...$(RESET)"; \
		$(MAKE) -C $$service build-dev; \
	done
	@echo "$(GREEN)✓ All development builds complete$(RESET)"

.PHONY: cross-build
cross-build: ## Build all services for all supported platforms
	@echo "$(BLUE)Cross-compiling all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Cross-building $$service...$(RESET)"; \
		$(MAKE) -C $$service cross-build; \
	done
	@echo "$(GREEN)✓ Cross-compilation complete for all services$(RESET)"

.PHONY: dist
dist: ## Create distribution packages for all services
	@echo "$(BLUE)Creating distribution packages...$(RESET)"
	@mkdir -p dist
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Creating packages for $$service...$(RESET)"; \
		$(MAKE) -C $$service dist; \
		if [ -d "$$service/dist" ]; then \
			cp -r $$service/dist/* dist/ 2>/dev/null || true; \
		fi; \
	done
	@echo "$(GREEN)✓ All distribution packages created in ./dist/$(RESET)"

# =============================================================================
# Infrastructure Management
# =============================================================================

.PHONY: infra-up
infra-up: ## Start all infrastructure (Kafka, databases, etc.)
	@echo "$(BLUE)Starting infrastructure...$(RESET)"
	@echo "$(YELLOW)Starting Kafka infrastructure...$(RESET)"
	@$(MAKE) -C $(KAFKA_DIR) docker-up
	@$(MAKE) -C $(KAFKA_DIR) kafka-topics-create
	@echo "$(GREEN)✓ Infrastructure started$(RESET)"

.PHONY: infra-down
infra-down: ## Stop all infrastructure
	@echo "$(BLUE)Stopping infrastructure...$(RESET)"
	@$(MAKE) -C $(KAFKA_DIR) docker-down
	@echo "$(GREEN)✓ Infrastructure stopped$(RESET)"

.PHONY: infra-status
infra-status: ## Check infrastructure status
	@echo "$(BLUE)Checking infrastructure status...$(RESET)"
	@$(MAKE) -C $(KAFKA_DIR) kafka-status

# =============================================================================
# Service Management (Host) Targets
# =============================================================================

.PHONY: host
host: build infra-up start-all ## Build and start all services in background (crash-safe)
	@echo "$(GREEN)✓ All services hosted successfully$(RESET)"
	@echo ""
	@echo "$(CYAN)Services Status:$(RESET)"
	@$(MAKE) status

.PHONY: start-all
start-all: ## Start all services in background
	@echo "$(BLUE)Starting all services...$(RESET)"
	@echo "$(YELLOW)Starting database service...$(RESET)"
	@$(MAKE) -C $(DB_SQL_DIR) start
	@echo "$(YELLOW)Starting gRPC service...$(RESET)"
	@$(MAKE) -C $(GRPC_DIR) start
	@echo "$(YELLOW)Starting Kafka services...$(RESET)"
	@$(MAKE) -C $(KAFKA_DIR) start-all
	@echo "$(YELLOW)Starting HTTP REST service...$(RESET)"
	@$(MAKE) -C $(HTTP_DIR) start
	@echo "$(GREEN)✓ All services started$(RESET)"

.PHONY: stop-all
stop-all: ## Stop all services
	@echo "$(BLUE)Stopping all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Stopping $$service...$(RESET)"; \
		$(MAKE) -C $$service stop; \
	done
	@echo "$(GREEN)✓ All services stopped$(RESET)"

.PHONY: restart-all
restart-all: stop-all start-all ## Restart all services
	@echo "$(GREEN)✓ All services restarted$(RESET)"

.PHONY: status
status: ## Check status of all services
	@echo "$(BLUE)Checking status of all services...$(RESET)"
	@echo ""
	@for service in $(SERVICES); do \
		echo "$(CYAN)=== $$service ===$(RESET)"; \
		$(MAKE) -C $$service status; \
		echo ""; \
	done

# =============================================================================
# Development Targets
# =============================================================================

.PHONY: run
run: ## Run all services locally (foreground, requires multiple terminals)
	@echo "$(BLUE)To run all services locally, use multiple terminals:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Terminal 1 - Database Service:$(RESET)"
	@echo "  make -C $(DB_SQL_DIR) run"
	@echo ""
	@echo "$(YELLOW)Terminal 2 - gRPC Service:$(RESET)"
	@echo "  make -C $(GRPC_DIR) run"
	@echo ""
	@echo "$(YELLOW)Terminal 3 - Kafka Consumer:$(RESET)"
	@echo "  make -C $(KAFKA_DIR) run-consumer"
	@echo ""
	@echo "$(YELLOW)Terminal 4 - Kafka Producer:$(RESET)"
	@echo "  make -C $(KAFKA_DIR) run-producer"
	@echo ""
	@echo "$(YELLOW)Terminal 5 - HTTP REST Service:$(RESET)"
	@echo "  make -C $(HTTP_DIR) run"
	@echo ""
	@echo "$(CYAN)Or use 'make host' to run all in background$(RESET)"

.PHONY: test
test: ## Run tests for all services
	@echo "$(BLUE)Running tests for all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Testing $$service...$(RESET)"; \
		$(MAKE) -C $$service test; \
	done
	@echo "$(GREEN)✓ All tests completed$(RESET)"

.PHONY: fmt
fmt: ## Format code for all services
	@echo "$(BLUE)Formatting code for all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Formatting $$service...$(RESET)"; \
		$(MAKE) -C $$service fmt; \
	done
	@echo "$(GREEN)✓ All code formatted$(RESET)"

.PHONY: lint
lint: ## Run linter for all services
	@echo "$(BLUE)Running linter for all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Linting $$service...$(RESET)"; \
		$(MAKE) -C $$service lint; \
	done
	@echo "$(GREEN)✓ All linting completed$(RESET)"

# =============================================================================
# Monitoring and Health Checks
# =============================================================================

.PHONY: health
health: ## Check health of all services
	@echo "$(BLUE)Checking health of all services...$(RESET)"
	@echo ""
	@echo "$(YELLOW)Database Service ($(DB_SQL_PORT)):$(RESET)"
	@$(MAKE) -C $(DB_SQL_DIR) health || echo "$(RED)✗ Database service unhealthy$(RESET)"
	@echo ""
	@echo "$(YELLOW)gRPC Service ($(GRPC_PORT)):$(RESET)"
	@$(MAKE) -C $(GRPC_DIR) health || echo "$(RED)✗ gRPC service unhealthy$(RESET)"
	@echo ""
	@echo "$(YELLOW)HTTP REST Service ($(HTTP_PORT)):$(RESET)"
	@$(MAKE) -C $(HTTP_DIR) health || echo "$(RED)✗ HTTP service unhealthy$(RESET)"
	@echo ""
	@echo "$(YELLOW)Kafka Services:$(RESET)"
	@$(MAKE) -C $(KAFKA_DIR) health || echo "$(RED)✗ Kafka services unhealthy$(RESET)"

.PHONY: logs
logs: ## Show logs from all services
	@echo "$(BLUE)Showing logs from all services...$(RESET)"
	@echo "$(YELLOW)Use Ctrl+C to stop$(RESET)"
	@echo ""
	@tail -f \
		$(DB_SQL_DIR)/logs/*.log \
		$(GRPC_DIR)/logs/*.log \
		$(HTTP_DIR)/logs/*.log \
		$(KAFKA_DIR)/logs/*.log \
		2>/dev/null || echo "$(YELLOW)Some log files may not exist yet$(RESET)"

.PHONY: ports
ports: ## Show all service ports and endpoints
	@echo "$(CYAN)Service Ports and Endpoints:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Database Service:$(RESET)"
	@echo "  Port: $(DB_SQL_PORT)"
	@echo "  Health: http://localhost:$(DB_SQL_PORT)/health"
	@echo ""
	@echo "$(YELLOW)gRPC Service:$(RESET)"
	@echo "  Port: $(GRPC_PORT)"
	@echo "  Test: grpcurl -plaintext localhost:$(GRPC_PORT) list"
	@echo ""
	@echo "$(YELLOW)HTTP REST Service:$(RESET)"
	@echo "  Port: $(HTTP_PORT)"
	@echo "  Health: http://localhost:$(HTTP_PORT)/health"
	@echo "  API: http://localhost:$(HTTP_PORT)/books"
	@echo ""
	@echo "$(YELLOW)Kafka Producer:$(RESET)"
	@echo "  Port: $(KAFKA_PRODUCER_PORT)"
	@echo "  Trigger: http://localhost:$(KAFKA_PRODUCER_PORT)/trigger-produce"
	@echo ""
	@echo "$(YELLOW)Kafka Consumer:$(RESET)"
	@echo "  Running in background (check logs)"

.PHONY: ps
ps: ## Show running processes for all services
	@echo "$(BLUE)Checking running processes...$(RESET)"
	@echo ""
	@./check-services.sh 2>/dev/null || echo "$(YELLOW)check-services.sh not found or not executable$(RESET)"

# =============================================================================
# Utility Targets
# =============================================================================

.PHONY: clean
clean: ## Clean build artifacts for all services
	@echo "$(BLUE)Cleaning all services...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Cleaning $$service...$(RESET)"; \
		$(MAKE) -C $$service clean; \
	done
	@rm -rf dist
	@echo "$(GREEN)✓ All services cleaned$(RESET)"

.PHONY: clean-all
clean-all: stop-all infra-down clean ## Stop everything and clean all artifacts
	@echo "$(GREEN)✓ Complete cleanup finished$(RESET)"

.PHONY: install
install: ## Install all service binaries to GOPATH/bin
	@echo "$(BLUE)Installing all service binaries...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Installing $$service...$(RESET)"; \
		$(MAKE) -C $$service install; \
	done
	@echo "$(GREEN)✓ All binaries installed$(RESET)"

.PHONY: uninstall
uninstall: ## Remove all service binaries from GOPATH/bin
	@echo "$(BLUE)Uninstalling all service binaries...$(RESET)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Uninstalling $$service...$(RESET)"; \
		$(MAKE) -C $$service uninstall; \
	done
	@echo "$(GREEN)✓ All binaries uninstalled$(RESET)"

# =============================================================================
# Quick Start Targets
# =============================================================================

# =============================================================================
# Quick Start and Management Targets
# =============================================================================

.PHONY: quick-start
quick-start: ## 🚀 ZERO-CONFIG SETUP: Run this for instant setup!
	@echo "$(CYAN)🚀 APM Examples - Zero-Config Quick Start$(RESET)"
	@echo ""
	@./quick-start.sh

.PHONY: start-apps
start-apps: ## Start database applications with intelligent port management
	@echo "$(BLUE)Starting database applications...$(RESET)"
	@./start-db-apps.sh

.PHONY: stop-apps
stop-apps: ## Stop all database applications
	@echo "$(BLUE)Stopping database applications...$(RESET)"
	@./stop-db-apps.sh

.PHONY: restart-apps
restart-apps: ## Restart all database applications
	@echo "$(BLUE)Restarting database applications...$(RESET)"
	@./restart-db-apps.sh

.PHONY: status-apps
status-apps: ## Check status of all database applications
	@./status-db-apps.sh

.PHONY: setup-public
setup-public: ## Setup public access for endpoints
	@echo "$(BLUE)Setting up public access...$(RESET)"
	@./setup-machine-ip-access.sh

.PHONY: start-public
start-public: ## Start applications with public/network access
	@echo "$(BLUE)Starting applications with public access...$(RESET)"
	@./start-machine-ip-apps.sh

.PHONY: test-public
test-public: ## Test public endpoint accessibility
	@./test-machine-ip-apps.sh

.PHONY: fix-issues
fix-issues: ## 🔧 Comprehensive fix for all common issues
	@./fix-db-issues.sh

.PHONY: fix-ports
fix-ports: ## 🔧 Fix port conflicts only
	@./fix-db-issues.sh ports

.PHONY: infra-only
infra-only: ## Start only infrastructure (PostgreSQL, MySQL, Kafka)
	@echo "$(BLUE)Starting minimal infrastructure...$(RESET)"
	@docker compose -f infrastructure/docker-compose.minimal.yml up -d
	@echo "$(GREEN)✓ Infrastructure started$(RESET)"
	@echo ""
	@echo "$(CYAN)Services available:$(RESET)"
	@echo "  PostgreSQL: localhost:5432 (testuser/Test@1234/testdb)"
	@echo "  MySQL:      localhost:3306 (testuser/Test@1234/testdb)"
	@echo "  Kafka:      localhost:9092"
	@echo "  Adminer:    http://localhost:8080"

.PHONY: infra-stop
infra-stop: ## Stop infrastructure services
	@echo "$(BLUE)Stopping infrastructure...$(RESET)"
	@docker compose -f infrastructure/docker-compose.minimal.yml stop
	@echo "$(GREEN)✓ Infrastructure stopped$(RESET)"

.PHONY: infra-clean
infra-clean: ## Stop and remove infrastructure
	@echo "$(BLUE)Cleaning infrastructure...$(RESET)"
	@docker compose -f infrastructure/docker-compose.minimal.yml down --volumes
	@echo "$(GREEN)✓ Infrastructure cleaned$(RESET)"

.PHONY: legacy-quick-start
legacy-quick-start: ## Legacy quick start with full Docker setup
	@echo "$(CYAN)Legacy Quick Start - APM Examples$(RESET)"
	@echo ""
	@echo "$(BLUE)Step 1: Setting up infrastructure...$(RESET)"
	@$(MAKE) infra-up
	@echo ""
	@echo "$(BLUE)Step 2: Building all services...$(RESET)"
	@$(MAKE) build
	@echo ""
	@echo "$(BLUE)Step 3: Starting all services...$(RESET)"
	@$(MAKE) start-all
	@echo ""
	@echo "$(GREEN)✓ Quick start completed!$(RESET)"
	@echo ""
	@$(MAKE) ports
	@echo ""
	@echo "$(CYAN)Next steps:$(RESET)"
	@echo "  $(GREEN)make health$(RESET)     - Check service health"
	@echo "  $(GREEN)make status$(RESET)     - Check service status"
	@echo "  $(GREEN)make logs$(RESET)       - View service logs"
	@echo "  $(GREEN)make stop-all$(RESET)   - Stop all services"

.PHONY: demo
demo: quick-start ## Run quick start and show demo commands
	@echo ""
	@echo "$(CYAN)Demo Commands:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Test HTTP REST API:$(RESET)"
	@echo "  curl http://localhost:$(HTTP_PORT)/books"
	@echo ""
	@echo "$(YELLOW)Test Kafka Producer:$(RESET)"
	@echo "  curl http://localhost:$(KAFKA_PRODUCER_PORT)/trigger-produce"
	@echo ""
	@echo "$(YELLOW)Test gRPC Service:$(RESET)"
	@echo "  grpcurl -plaintext localhost:$(GRPC_PORT) list"
	@echo ""
	@echo "$(YELLOW)Check Database Service:$(RESET)"
	@echo "  curl http://localhost:$(DB_SQL_PORT)/health"

# =============================================================================
# Documentation
# =============================================================================

.PHONY: readme
readme: ## Show project README information
	@if [ -f README.md ]; then \
		echo "$(BLUE)Project README:$(RESET)"; \
		head -20 README.md; \
		echo "$(YELLOW)...$(RESET)"; \
		echo "$(CYAN)See README.md for complete documentation$(RESET)"; \
	else \
		echo "$(YELLOW)README.md not found$(RESET)"; \
	fi

# Default target
.DEFAULT_GOAL := help
