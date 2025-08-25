# =============================================================================
# Kafka Service Makefile
# =============================================================================

# Project configuration
PROJECT_NAME := kafka-segmentio
PRODUCER_BINARY := kafka-producer
CONSUMER_BINARY := kafka-consumer
PRODUCER_MAIN := ./cmd/producer
CONSUMER_MAIN := ./cmd/consumer
BIN_DIR := bin
LOGS_DIR := logs
PID_DIR := pids

# Build configuration
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Go build flags
LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.gitCommit=$(GIT_COMMIT) -w -s"
BUILD_FLAGS := -trimpath $(LDFLAGS)

# Cross-compilation targets
PLATFORMS := \
	linux/amd64 \
	linux/arm64 \
	darwin/amd64 \
	darwin/arm64 \
	windows/amd64 \
	windows/arm64

# Service configuration
PRODUCER_PORT := 8082
CONSUMER_PORT := 8083
PRODUCER_PID_FILE := $(PID_DIR)/$(PRODUCER_BINARY).pid
CONSUMER_PID_FILE := $(PID_DIR)/$(CONSUMER_BINARY).pid
PRODUCER_LOG_FILE := $(LOGS_DIR)/$(PRODUCER_BINARY).log
CONSUMER_LOG_FILE := $(LOGS_DIR)/$(CONSUMER_BINARY).log

# Kafka configuration
KAFKA_BROKER := localhost:9092
KAFKA_TOPICS := orders payments

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
	@echo "$(CYAN)$(PROJECT_NAME) - Available targets:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Build targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(build|cross|dist)"
	@echo ""
	@echo "$(YELLOW)Development targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(run|dev|test|fmt|lint)"
	@echo ""
	@echo "$(YELLOW)Deployment targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(host|start|stop|restart|status)"
	@echo ""
	@echo "$(YELLOW)Kafka targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(kafka|docker)"
	@echo ""
	@echo "$(YELLOW)Utility targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(clean|deps|mod|install)"
	@echo ""
	@echo "$(YELLOW)Cross-compilation platforms:$(RESET)"
	@echo "  $(MAGENTA)linux/amd64$(RESET)     $(MAGENTA)linux/arm64$(RESET)"
	@echo "  $(MAGENTA)darwin/amd64$(RESET)    $(MAGENTA)darwin/arm64$(RESET)"
	@echo "  $(MAGENTA)windows/amd64$(RESET)   $(MAGENTA)windows/arm64$(RESET)"

# =============================================================================
# Setup and Dependencies
# =============================================================================

.PHONY: setup
setup: ## Setup project directories and dependencies
	@echo "$(BLUE)Setting up project directories...$(RESET)"
	@mkdir -p $(BIN_DIR) $(LOGS_DIR) $(PID_DIR)
	@echo "$(GREEN)✓ Directories created$(RESET)"

.PHONY: deps
deps: ## Download and verify dependencies
	@echo "$(BLUE)Downloading dependencies...$(RESET)"
	@go mod download
	@go mod verify
	@echo "$(GREEN)✓ Dependencies ready$(RESET)"

.PHONY: mod-tidy
mod-tidy: ## Clean up go.mod and go.sum
	@echo "$(BLUE)Tidying go modules...$(RESET)"
	@go mod tidy
	@echo "$(GREEN)✓ Modules tidied$(RESET)"

# =============================================================================
# Docker/Kafka Infrastructure
# =============================================================================

.PHONY: docker-up
docker-up: ## Start Kafka infrastructure with Docker Compose
	@echo "$(BLUE)Starting Kafka infrastructure...$(RESET)"
	@if [ -f docker-compose.yml ]; then \
		docker compose up -d; \
		echo "$(GREEN)✓ Kafka infrastructure started$(RESET)"; \
		echo "$(YELLOW)Waiting for Kafka to be ready...$(RESET)"; \
		sleep 10; \
	else \
		echo "$(RED)docker-compose.yml not found$(RESET)"; \
		exit 1; \
	fi

.PHONY: docker-down
docker-down: ## Stop Kafka infrastructure
	@echo "$(BLUE)Stopping Kafka infrastructure...$(RESET)"
	@if [ -f docker-compose.yml ]; then \
		docker compose down; \
		echo "$(GREEN)✓ Kafka infrastructure stopped$(RESET)"; \
	else \
		echo "$(YELLOW)docker-compose.yml not found$(RESET)"; \
	fi

.PHONY: docker-logs
docker-logs: ## Show Kafka Docker logs
	@echo "$(BLUE)Showing Kafka Docker logs...$(RESET)"
	@docker compose logs -f

.PHONY: kafka-topics-create
kafka-topics-create: ## Create Kafka topics
	@echo "$(BLUE)Creating Kafka topics...$(RESET)"
	@for topic in $(KAFKA_TOPICS); do \
		echo "$(YELLOW)Creating topic: $$topic$(RESET)"; \
		docker exec $$(docker compose ps -q kafka) kafka-topics --create --topic $$topic --bootstrap-server $(KAFKA_BROKER) --partitions 3 --replication-factor 1 2>/dev/null || true; \
	done
	@echo "$(GREEN)✓ Kafka topics created$(RESET)"

.PHONY: kafka-topics-list
kafka-topics-list: ## List Kafka topics
	@echo "$(BLUE)Listing Kafka topics...$(RESET)"
	@docker exec $$(docker compose ps -q kafka) kafka-topics --list --bootstrap-server $(KAFKA_BROKER)

.PHONY: kafka-status
kafka-status: ## Check Kafka status
	@echo "$(BLUE)Checking Kafka status...$(RESET)"
	@docker compose ps

# =============================================================================
# Build Targets
# =============================================================================

.PHONY: build
build: setup deps ## Build both producer and consumer binaries (production standards)
	@echo "$(BLUE)Building $(PROJECT_NAME) binaries...$(RESET)"
	@echo "$(YELLOW)Version: $(VERSION)$(RESET)"
	@echo "$(YELLOW)Build Time: $(BUILD_TIME)$(RESET)"
	@echo "$(YELLOW)Git Commit: $(GIT_COMMIT)$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(PRODUCER_BINARY) $(PRODUCER_MAIN)
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(CONSUMER_BINARY) $(CONSUMER_MAIN)
	@echo "$(GREEN)✓ Build complete:$(RESET)"
	@echo "  $(GREEN)$(BIN_DIR)/$(PRODUCER_BINARY)$(RESET)"
	@echo "  $(GREEN)$(BIN_DIR)/$(CONSUMER_BINARY)$(RESET)"

.PHONY: build-producer
build-producer: setup deps ## Build only the producer binary
	@echo "$(BLUE)Building $(PRODUCER_BINARY)...$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(PRODUCER_BINARY) $(PRODUCER_MAIN)
	@echo "$(GREEN)✓ Producer build complete: $(BIN_DIR)/$(PRODUCER_BINARY)$(RESET)"

.PHONY: build-consumer
build-consumer: setup deps ## Build only the consumer binary
	@echo "$(BLUE)Building $(CONSUMER_BINARY)...$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(CONSUMER_BINARY) $(CONSUMER_MAIN)
	@echo "$(GREEN)✓ Consumer build complete: $(BIN_DIR)/$(CONSUMER_BINARY)$(RESET)"

.PHONY: build-dev
build-dev: setup ## Build binaries for development (with debug info)
	@echo "$(BLUE)Building $(PROJECT_NAME) for development...$(RESET)"
	@go build -race -o $(BIN_DIR)/$(PRODUCER_BINARY)-dev $(PRODUCER_MAIN)
	@go build -race -o $(BIN_DIR)/$(CONSUMER_BINARY)-dev $(CONSUMER_MAIN)
	@echo "$(GREEN)✓ Development builds complete$(RESET)"

# =============================================================================
# Cross-compilation
# =============================================================================

.PHONY: cross-build
cross-build: setup deps ## Build for all supported platforms
	@echo "$(BLUE)Building for all platforms...$(RESET)"
	@for platform in $(PLATFORMS); do \
		os=$$(echo $$platform | cut -d'/' -f1); \
		arch=$$(echo $$platform | cut -d'/' -f2); \
		producer_output=$(BIN_DIR)/$(PRODUCER_BINARY)-$$os-$$arch; \
		consumer_output=$(BIN_DIR)/$(CONSUMER_BINARY)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then \
			producer_output=$$producer_output.exe; \
			consumer_output=$$consumer_output.exe; \
		fi; \
		echo "$(YELLOW)Building for $$os/$$arch...$(RESET)"; \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build $(BUILD_FLAGS) -o $$producer_output $(PRODUCER_MAIN); \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build $(BUILD_FLAGS) -o $$consumer_output $(CONSUMER_MAIN); \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ $$producer_output$(RESET)"; \
			echo "$(GREEN)✓ $$consumer_output$(RESET)"; \
		else \
			echo "$(RED)✗ Failed to build for $$os/$$arch$(RESET)"; \
		fi; \
	done
	@echo "$(GREEN)✓ Cross-compilation complete$(RESET)"

.PHONY: dist
dist: cross-build ## Create distribution packages
	@echo "$(BLUE)Creating distribution packages...$(RESET)"
	@mkdir -p dist
	@for platform in $(PLATFORMS); do \
		os=$$(echo $$platform | cut -d'/' -f1); \
		arch=$$(echo $$platform | cut -d'/' -f2); \
		producer_binary=$(PRODUCER_BINARY)-$$os-$$arch; \
		consumer_binary=$(CONSUMER_BINARY)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then \
			producer_binary=$$producer_binary.exe; \
			consumer_binary=$$consumer_binary.exe; \
		fi; \
		if [ -f "$(BIN_DIR)/$$producer_binary" ] && [ -f "$(BIN_DIR)/$$consumer_binary" ]; then \
			package_name=$(PROJECT_NAME)-$(VERSION)-$$os-$$arch; \
			mkdir -p dist/$$package_name; \
			cp $(BIN_DIR)/$$producer_binary dist/$$package_name/$(PRODUCER_BINARY)$$(if [ "$$os" = "windows" ]; then echo ".exe"; fi); \
			cp $(BIN_DIR)/$$consumer_binary dist/$$package_name/$(CONSUMER_BINARY)$$(if [ "$$os" = "windows" ]; then echo ".exe"; fi); \
			cp README.md dist/$$package_name/ 2>/dev/null || true; \
			cp docker-compose.yml dist/$$package_name/ 2>/dev/null || true; \
			cd dist && tar -czf $$package_name.tar.gz $$package_name && rm -rf $$package_name; \
			echo "$(GREEN)✓ dist/$$package_name.tar.gz$(RESET)"; \
		fi; \
	done
	@echo "$(GREEN)✓ Distribution packages created$(RESET)"

# =============================================================================
# Development Targets
# =============================================================================

.PHONY: run
run: ## Run both producer and consumer locally (requires Kafka)
	@echo "$(BLUE)Running $(PROJECT_NAME) services...$(RESET)"
	@echo "$(YELLOW)Starting consumer in background...$(RESET)"
	@go run $(CONSUMER_MAIN) &
	@sleep 2
	@echo "$(YELLOW)Starting producer...$(RESET)"
	@echo "$(YELLOW)Producer will be available on port $(PRODUCER_PORT)$(RESET)"
	@go run $(PRODUCER_MAIN)

.PHONY: run-producer
run-producer: ## Run only the producer locally
	@echo "$(BLUE)Running $(PRODUCER_BINARY) locally...$(RESET)"
	@echo "$(YELLOW)Producer will be available on port $(PRODUCER_PORT)$(RESET)"
	@go run $(PRODUCER_MAIN)

.PHONY: run-consumer
run-consumer: ## Run only the consumer locally
	@echo "$(BLUE)Running $(CONSUMER_BINARY) locally...$(RESET)"
	@go run $(CONSUMER_MAIN)

.PHONY: run-dev
run-dev: build-dev ## Run development builds
	@echo "$(BLUE)Running development builds...$(RESET)"
	@echo "$(YELLOW)Starting consumer in background...$(RESET)"
	@$(BIN_DIR)/$(CONSUMER_BINARY)-dev &
	@sleep 2
	@echo "$(YELLOW)Starting producer...$(RESET)"
	@$(BIN_DIR)/$(PRODUCER_BINARY)-dev

.PHONY: test
test: ## Run tests
	@echo "$(BLUE)Running tests...$(RESET)"
	@go test -v -race -coverprofile=coverage.out ./...
	@echo "$(GREEN)✓ Tests completed$(RESET)"

.PHONY: test-coverage
test-coverage: test ## Run tests with coverage report
	@echo "$(BLUE)Generating coverage report...$(RESET)"
	@go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)✓ Coverage report: coverage.html$(RESET)"

.PHONY: bench
bench: ## Run benchmarks
	@echo "$(BLUE)Running benchmarks...$(RESET)"
	@go test -bench=. -benchmem ./...

.PHONY: fmt
fmt: ## Format code
	@echo "$(BLUE)Formatting code...$(RESET)"
	@go fmt ./...
	@echo "$(GREEN)✓ Code formatted$(RESET)"

.PHONY: lint
lint: ## Run linter
	@echo "$(BLUE)Running linter...$(RESET)"
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "$(YELLOW)golangci-lint not installed, running go vet instead$(RESET)"; \
		go vet ./...; \
	fi
	@echo "$(GREEN)✓ Linting completed$(RESET)"

.PHONY: vet
vet: ## Run go vet
	@echo "$(BLUE)Running go vet...$(RESET)"
	@go vet ./...
	@echo "$(GREEN)✓ Vet completed$(RESET)"

# =============================================================================
# Service Management (Host) Targets
# =============================================================================

.PHONY: host
host: build start-all ## Build and start both services in background (crash-safe)
	@echo "$(GREEN)✓ Kafka services hosted successfully$(RESET)"

.PHONY: start-all
start-all: start-consumer start-producer ## Start both producer and consumer in background
	@echo "$(GREEN)✓ All Kafka services started$(RESET)"

.PHONY: start-producer
start-producer: setup ## Start producer in background
	@if [ -f $(PRODUCER_PID_FILE) ] && kill -0 $$(cat $(PRODUCER_PID_FILE)) 2>/dev/null; then \
		echo "$(YELLOW)Kafka producer already running (PID: $$(cat $(PRODUCER_PID_FILE)))$(RESET)"; \
	else \
		echo "$(BLUE)Starting $(PRODUCER_BINARY) in background...$(RESET)"; \
		nohup $(BIN_DIR)/$(PRODUCER_BINARY) > $(PRODUCER_LOG_FILE) 2>&1 & \
		echo $$! > $(PRODUCER_PID_FILE); \
		sleep 2; \
		if kill -0 $$(cat $(PRODUCER_PID_FILE)) 2>/dev/null; then \
			echo "$(GREEN)✓ Kafka producer started (PID: $$(cat $(PRODUCER_PID_FILE)))$(RESET)"; \
			echo "$(YELLOW)Logs: $(PRODUCER_LOG_FILE)$(RESET)"; \
			echo "$(YELLOW)Port: $(PRODUCER_PORT)$(RESET)"; \
		else \
			echo "$(RED)✗ Failed to start Kafka producer$(RESET)"; \
			rm -f $(PRODUCER_PID_FILE); \
			exit 1; \
		fi; \
	fi

.PHONY: start-consumer
start-consumer: setup ## Start consumer in background
	@if [ -f $(CONSUMER_PID_FILE) ] && kill -0 $$(cat $(CONSUMER_PID_FILE)) 2>/dev/null; then \
		echo "$(YELLOW)Kafka consumer already running (PID: $$(cat $(CONSUMER_PID_FILE)))$(RESET)"; \
	else \
		echo "$(BLUE)Starting $(CONSUMER_BINARY) in background...$(RESET)"; \
		nohup $(BIN_DIR)/$(CONSUMER_BINARY) > $(CONSUMER_LOG_FILE) 2>&1 & \
		echo $$! > $(CONSUMER_PID_FILE); \
		sleep 2; \
		if kill -0 $$(cat $(CONSUMER_PID_FILE)) 2>/dev/null; then \
			echo "$(GREEN)✓ Kafka consumer started (PID: $$(cat $(CONSUMER_PID_FILE)))$(RESET)"; \
			echo "$(YELLOW)Logs: $(CONSUMER_LOG_FILE)$(RESET)"; \
		else \
			echo "$(RED)✗ Failed to start Kafka consumer$(RESET)"; \
			rm -f $(CONSUMER_PID_FILE); \
			exit 1; \
		fi; \
	fi

.PHONY: stop
stop: stop-producer stop-consumer ## Stop both services
	@echo "$(GREEN)✓ All Kafka services stopped$(RESET)"

.PHONY: stop-producer
stop-producer: ## Stop the producer
	@if [ -f $(PRODUCER_PID_FILE) ]; then \
		PID=$$(cat $(PRODUCER_PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(BLUE)Stopping $(PRODUCER_BINARY) (PID: $$PID)...$(RESET)"; \
			kill $$PID; \
			sleep 2; \
			if kill -0 $$PID 2>/dev/null; then \
				echo "$(YELLOW)Force killing...$(RESET)"; \
				kill -9 $$PID; \
			fi; \
			rm -f $(PRODUCER_PID_FILE); \
			echo "$(GREEN)✓ Kafka producer stopped$(RESET)"; \
		else \
			echo "$(YELLOW)Kafka producer not running$(RESET)"; \
			rm -f $(PRODUCER_PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)No producer PID file found$(RESET)"; \
	fi

.PHONY: stop-consumer
stop-consumer: ## Stop the consumer
	@if [ -f $(CONSUMER_PID_FILE) ]; then \
		PID=$$(cat $(CONSUMER_PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(BLUE)Stopping $(CONSUMER_BINARY) (PID: $$PID)...$(RESET)"; \
			kill $$PID; \
			sleep 2; \
			if kill -0 $$PID 2>/dev/null; then \
				echo "$(YELLOW)Force killing...$(RESET)"; \
				kill -9 $$PID; \
			fi; \
			rm -f $(CONSUMER_PID_FILE); \
			echo "$(GREEN)✓ Kafka consumer stopped$(RESET)"; \
		else \
			echo "$(YELLOW)Kafka consumer not running$(RESET)"; \
			rm -f $(CONSUMER_PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)No consumer PID file found$(RESET)"; \
	fi

.PHONY: restart
restart: stop start-all ## Restart both services
	@echo "$(GREEN)✓ Kafka services restarted$(RESET)"

.PHONY: status
status: ## Check services status
	@echo "$(BLUE)Checking Kafka services status...$(RESET)"
	@echo "$(YELLOW)Producer Status:$(RESET)"
	@if [ -f $(PRODUCER_PID_FILE) ]; then \
		PID=$$(cat $(PRODUCER_PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(GREEN)✓ Producer running (PID: $$PID)$(RESET)"; \
			echo "$(YELLOW)  Port: $(PRODUCER_PORT)$(RESET)"; \
			echo "$(YELLOW)  Logs: $(PRODUCER_LOG_FILE)$(RESET)"; \
		else \
			echo "$(RED)✗ Producer not running (stale PID file)$(RESET)"; \
			rm -f $(PRODUCER_PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)Producer not running$(RESET)"; \
	fi
	@echo "$(YELLOW)Consumer Status:$(RESET)"
	@if [ -f $(CONSUMER_PID_FILE) ]; then \
		PID=$$(cat $(CONSUMER_PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(GREEN)✓ Consumer running (PID: $$PID)$(RESET)"; \
			echo "$(YELLOW)  Logs: $(CONSUMER_LOG_FILE)$(RESET)"; \
		else \
			echo "$(RED)✗ Consumer not running (stale PID file)$(RESET)"; \
			rm -f $(CONSUMER_PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)Consumer not running$(RESET)"; \
	fi

.PHONY: logs-producer
logs-producer: ## Show producer logs
	@if [ -f $(PRODUCER_LOG_FILE) ]; then \
		echo "$(BLUE)Showing producer logs from $(PRODUCER_LOG_FILE):$(RESET)"; \
		tail -f $(PRODUCER_LOG_FILE); \
	else \
		echo "$(YELLOW)No producer log file found$(RESET)"; \
	fi

.PHONY: logs-consumer
logs-consumer: ## Show consumer logs
	@if [ -f $(CONSUMER_LOG_FILE) ]; then \
		echo "$(BLUE)Showing consumer logs from $(CONSUMER_LOG_FILE):$(RESET)"; \
		tail -f $(CONSUMER_LOG_FILE); \
	else \
		echo "$(YELLOW)No consumer log file found$(RESET)"; \
	fi

.PHONY: logs
logs: ## Show both producer and consumer logs
	@echo "$(BLUE)Showing all Kafka service logs...$(RESET)"
	@if [ -f $(PRODUCER_LOG_FILE) ] && [ -f $(CONSUMER_LOG_FILE) ]; then \
		tail -f $(PRODUCER_LOG_FILE) $(CONSUMER_LOG_FILE); \
	elif [ -f $(PRODUCER_LOG_FILE) ]; then \
		tail -f $(PRODUCER_LOG_FILE); \
	elif [ -f $(CONSUMER_LOG_FILE) ]; then \
		tail -f $(CONSUMER_LOG_FILE); \
	else \
		echo "$(YELLOW)No log files found$(RESET)"; \
	fi

# =============================================================================
# Testing Targets
# =============================================================================

.PHONY: test-produce
test-produce: ## Test message production
	@echo "$(BLUE)Testing message production...$(RESET)"
	@if curl -f -s http://localhost:$(PRODUCER_PORT)/trigger-produce >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Message production test successful$(RESET)"; \
	else \
		echo "$(RED)✗ Message production test failed$(RESET)"; \
		exit 1; \
	fi

.PHONY: curl-examples
curl-examples: ## Show curl examples for testing
	@echo "$(CYAN)Kafka Testing Examples:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Trigger Message Production:$(RESET)"
	@echo "  curl http://localhost:$(PRODUCER_PORT)/trigger-produce"
	@echo ""
	@echo "$(YELLOW)Check Producer Health:$(RESET)"
	@echo "  curl http://localhost:$(PRODUCER_PORT)/health"

# =============================================================================
# Utility Targets
# =============================================================================

.PHONY: clean
clean: ## Clean build artifacts and logs
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	@rm -rf $(BIN_DIR) $(LOGS_DIR) $(PID_DIR) dist coverage.out coverage.html
	@echo "$(GREEN)✓ Clean completed$(RESET)"

.PHONY: clean-all
clean-all: stop clean docker-down ## Stop services, clean everything, and stop Docker
	@echo "$(GREEN)✓ Complete cleanup finished$(RESET)"

.PHONY: install
install: build ## Install binaries to GOPATH/bin
	@echo "$(BLUE)Installing $(PROJECT_NAME) binaries...$(RESET)"
	@cp $(BIN_DIR)/$(PRODUCER_BINARY) $(GOPATH)/bin/
	@cp $(BIN_DIR)/$(CONSUMER_BINARY) $(GOPATH)/bin/
	@echo "$(GREEN)✓ Installed to $(GOPATH)/bin/$(RESET)"

.PHONY: uninstall
uninstall: ## Remove binaries from GOPATH/bin
	@echo "$(BLUE)Uninstalling $(PROJECT_NAME) binaries...$(RESET)"
	@rm -f $(GOPATH)/bin/$(PRODUCER_BINARY)
	@rm -f $(GOPATH)/bin/$(CONSUMER_BINARY)
	@echo "$(GREEN)✓ Uninstalled$(RESET)"

.PHONY: health
health: ## Check services health
	@echo "$(BLUE)Checking Kafka services health...$(RESET)"
	@if curl -f -s http://localhost:$(PRODUCER_PORT)/health >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Producer is healthy$(RESET)"; \
	else \
		echo "$(RED)✗ Producer health check failed$(RESET)"; \
	fi

# =============================================================================
# Complete Infrastructure Setup
# =============================================================================

.PHONY: infra-up
infra-up: docker-up kafka-topics-create ## Start complete Kafka infrastructure
	@echo "$(GREEN)✓ Complete Kafka infrastructure is ready$(RESET)"

.PHONY: infra-down
infra-down: stop docker-down ## Stop all services and infrastructure
	@echo "$(GREEN)✓ Complete infrastructure stopped$(RESET)"

.PHONY: full-setup
full-setup: infra-up build host ## Complete setup: infrastructure + build + host services
	@echo "$(GREEN)✓ Full Kafka setup completed$(RESET)"
	@echo "$(CYAN)Services running:$(RESET)"
	@echo "  $(YELLOW)Producer: http://localhost:$(PRODUCER_PORT)$(RESET)"
	@echo "  $(YELLOW)Consumer: running in background$(RESET)"
	@echo "  $(YELLOW)Kafka: $(KAFKA_BROKER)$(RESET)"

# Default target
.DEFAULT_GOAL := help
