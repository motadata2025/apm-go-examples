# =============================================================================
# Multi-Set Build System for APM Examples
# =============================================================================

# Configuration
GO ?= go
CGO_ENABLED ?= 0
BASES ?= 800 801 802 803
PROJECT_ROOT := $(shell cd .. && pwd)

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
CYAN := \033[36m
RESET := \033[0m

# Service paths relative to project root
DB_SQL_PATH := $(PROJECT_ROOT)/db-sql-multi/cmd/app
GRPC_CLIENT_PATH := $(PROJECT_ROOT)/grpc-svc/cmd/client
GRPC_SERVER_PATH := $(PROJECT_ROOT)/grpc-svc/cmd/server
KAFKA_PRODUCER_PATH := $(PROJECT_ROOT)/kafka-segmentio/cmd/producer
KAFKA_CONSUMER_PATH := $(PROJECT_ROOT)/kafka-segmentio/cmd/consumer
HTTP_REST_PATH := $(PROJECT_ROOT)/http-rest/cmd/api

# Default target
.PHONY: all
all: build-all-sets
	@echo "$(GREEN)✓ All sets built successfully$(RESET)"

# Build all sets
.PHONY: build-all-sets
build-all-sets:
	@echo "$(BLUE)Building all sets...$(RESET)"
	@./scripts/build_sets.sh

# Individual set targets
.PHONY: build-800 static-801 race-802 xcompile-803
build-800:
	@echo "$(BLUE)Building set 800...$(RESET)"
	@BASE=800 ./scripts/build_sets.sh

static-801:
	@echo "$(BLUE)Building static set 801...$(RESET)"
	@BASE=801 ./scripts/build_sets.sh

race-802:
	@echo "$(BLUE)Building race set 802...$(RESET)"
	@BASE=802 ./scripts/build_sets.sh

xcompile-803:
	@echo "$(BLUE)Building cross-compile set 803...$(RESET)"
	@BASE=803 ./scripts/build_sets.sh

# Run set 800 in background
.PHONY: run-800
run-800:
	@echo "$(BLUE)Starting set 800 in background...$(RESET)"
	@./scripts/run_set_bg.sh build-800

# Stop set 800
.PHONY: stop-800
stop-800:
	@echo "$(BLUE)Stopping set 800...$(RESET)"
	@./scripts/stop_set.sh build-800

# Status check
.PHONY: status-800
status-800:
	@echo "$(BLUE)Checking status of set 800...$(RESET)"
	@./scripts/check_status.sh build-800

# Clean all build artifacts
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning all build artifacts...$(RESET)"
	@rm -rf build-*/bin build-*/logs static-*/bin static-*/logs race-*/bin race-*/logs xcompile-*/bin xcompile-*/logs
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@echo "$(GREEN)✓ All artifacts cleaned$(RESET)"

# Setup directories
.PHONY: setup
setup:
	@echo "$(BLUE)Setting up directories...$(RESET)"
	@for base in $(BASES); do \
		case $$base in \
			800) set_name="build-800" ;; \
			801) set_name="static-801" ;; \
			802) set_name="race-802" ;; \
			803) set_name="xcompile-803" ;; \
		esac; \
		mkdir -p $$set_name/{bin,logs,env}; \
	done
	@mkdir -p scripts
	@echo "$(GREEN)✓ Directories created$(RESET)"

# Test endpoints for set 800
.PHONY: test-800
test-800:
	@echo "$(BLUE)Testing endpoints for set 800...$(RESET)"
	@echo "$(YELLOW)Database service:$(RESET)"
	@curl -s http://localhost:8001/trigger-crud || echo "$(RED)✗ DB service not responding$(RESET)"
	@echo ""
	@echo "$(YELLOW)Kafka producer:$(RESET)"
	@curl -s http://localhost:8002/trigger-produce || echo "$(RED)✗ Kafka producer not responding$(RESET)"
	@echo ""
	@echo "$(YELLOW)gRPC client:$(RESET)"
	@curl -s http://localhost:8003/trigger-simple || echo "$(RED)✗ gRPC client not responding$(RESET)"
	@echo ""
	@echo "$(YELLOW)HTTP REST:$(RESET)"
	@curl -s http://localhost:8004/trigger/allservices || echo "$(RED)✗ HTTP REST not responding$(RESET)"

# Show service map
.PHONY: endpoints
endpoints:
	@echo "$(CYAN)Service Endpoints by Set:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Set 800 (build-800):$(RESET)"
	@echo "  Database:     http://localhost:8001/trigger-crud"
	@echo "  Kafka:        http://localhost:8002/trigger-produce"
	@echo "  gRPC Client:  http://localhost:8003/trigger-simple"
	@echo "  gRPC Client:  http://localhost:8003/trigger-stream"
	@echo "  HTTP REST:    http://localhost:8004/trigger/allservices"
	@echo ""
	@echo "$(YELLOW)Set 801 (static-801):$(RESET)"
	@echo "  Database:     http://localhost:8011/trigger-crud"
	@echo "  Kafka:        http://localhost:8012/trigger-produce"
	@echo "  gRPC Client:  http://localhost:8013/trigger-simple"
	@echo "  HTTP REST:    http://localhost:8014/trigger/allservices"
	@echo ""
	@echo "$(YELLOW)Set 802 (race-802):$(RESET)"
	@echo "  Database:     http://localhost:8021/trigger-crud"
	@echo "  Kafka:        http://localhost:8022/trigger-produce"
	@echo "  gRPC Client:  http://localhost:8023/trigger-simple"
	@echo "  HTTP REST:    http://localhost:8024/trigger/allservices"

# Help target
.PHONY: help
help:
	@echo "$(CYAN)Multi-Set Build System$(RESET)"
	@echo ""
	@echo "$(YELLOW)Build targets:$(RESET)"
	@echo "  $(GREEN)all$(RESET)              Build all sets (800, 801, 802, 803)"
	@echo "  $(GREEN)build-800$(RESET)        Build set 800 (includes server/consumer)"
	@echo "  $(GREEN)static-801$(RESET)       Build static set 801"
	@echo "  $(GREEN)race-802$(RESET)         Build race set 802"
	@echo "  $(GREEN)xcompile-803$(RESET)     Build cross-compile set 803"
	@echo ""
	@echo "$(YELLOW)Runtime targets:$(RESET)"
	@echo "  $(GREEN)run-800$(RESET)          Run set 800 in background"
	@echo "  $(GREEN)stop-800$(RESET)         Stop set 800"
	@echo "  $(GREEN)status-800$(RESET)       Check status of set 800"
	@echo "  $(GREEN)test-800$(RESET)         Test endpoints for set 800"
	@echo ""
	@echo "$(YELLOW)Utility targets:$(RESET)"
	@echo "  $(GREEN)setup$(RESET)            Setup directories"
	@echo "  $(GREEN)clean$(RESET)            Clean all build artifacts"
	@echo "  $(GREEN)endpoints$(RESET)        Show service endpoints"
	@echo "  $(GREEN)help$(RESET)             Show this help"

# Default goal
.DEFAULT_GOAL := help
