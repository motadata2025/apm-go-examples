# =============================================================================
# DB-SQL-Multi Service Makefile
# =============================================================================

# Project configuration
PROJECT_NAME := db-sql-multi
BINARY_NAME := db-sql-multi
MAIN_PATH := ./cmd/app
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
SERVICE_NAME := $(BINARY_NAME)
SERVICE_PORT := 8081
PID_FILE := $(PID_DIR)/$(SERVICE_NAME).pid
LOG_FILE := $(LOGS_DIR)/$(SERVICE_NAME).log

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
# Build Targets
# =============================================================================

.PHONY: build
build: setup deps ## Build binary for current platform (production standards)
	@echo "$(BLUE)Building $(BINARY_NAME) for current platform...$(RESET)"
	@echo "$(YELLOW)Version: $(VERSION)$(RESET)"
	@echo "$(YELLOW)Build Time: $(BUILD_TIME)$(RESET)"
	@echo "$(YELLOW)Git Commit: $(GIT_COMMIT)$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "$(GREEN)✓ Build complete: $(BIN_DIR)/$(BINARY_NAME)$(RESET)"

.PHONY: build-dev
build-dev: setup ## Build binary for development (with debug info)
	@echo "$(BLUE)Building $(BINARY_NAME) for development...$(RESET)"
	@go build -race -o $(BIN_DIR)/$(BINARY_NAME)-dev $(MAIN_PATH)
	@echo "$(GREEN)✓ Development build complete: $(BIN_DIR)/$(BINARY_NAME)-dev$(RESET)"

.PHONY: cross-build
cross-build: setup deps ## Build for all supported platforms
	@echo "$(BLUE)Building for all platforms...$(RESET)"
	@for platform in $(PLATFORMS); do \
		os=$$(echo $$platform | cut -d'/' -f1); \
		arch=$$(echo $$platform | cut -d'/' -f2); \
		output_name=$(BIN_DIR)/$(BINARY_NAME)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then output_name=$$output_name.exe; fi; \
		echo "$(YELLOW)Building for $$os/$$arch...$(RESET)"; \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build $(BUILD_FLAGS) -o $$output_name $(MAIN_PATH); \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ $$output_name$(RESET)"; \
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
		binary_name=$(BINARY_NAME)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then binary_name=$$binary_name.exe; fi; \
		if [ -f "$(BIN_DIR)/$$binary_name" ]; then \
			package_name=$(BINARY_NAME)-$(VERSION)-$$os-$$arch; \
			mkdir -p dist/$$package_name; \
			cp $(BIN_DIR)/$$binary_name dist/$$package_name/$(BINARY_NAME)$$(if [ "$$os" = "windows" ]; then echo ".exe"; fi); \
			cp README.md dist/$$package_name/ 2>/dev/null || true; \
			cd dist && tar -czf $$package_name.tar.gz $$package_name && rm -rf $$package_name; \
			echo "$(GREEN)✓ dist/$$package_name.tar.gz$(RESET)"; \
		fi; \
	done
	@echo "$(GREEN)✓ Distribution packages created$(RESET)"

# =============================================================================
# Development Targets
# =============================================================================

.PHONY: run
run: ## Run the application locally
	@echo "$(BLUE)Running $(BINARY_NAME) locally...$(RESET)"
	@echo "$(YELLOW)Service will be available on port $(SERVICE_PORT)$(RESET)"
	@go run $(MAIN_PATH)

.PHONY: run-dev
run-dev: build-dev ## Run development build
	@echo "$(BLUE)Running development build...$(RESET)"
	@$(BIN_DIR)/$(BINARY_NAME)-dev

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
host: build start ## Build and start service in background (crash-safe)
	@echo "$(GREEN)✓ Service hosted successfully$(RESET)"

.PHONY: start
start: setup ## Start service in background
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "$(YELLOW)Service already running (PID: $$(cat $(PID_FILE)))$(RESET)"; \
	else \
		echo "$(BLUE)Starting $(SERVICE_NAME) in background...$(RESET)"; \
		nohup $(BIN_DIR)/$(BINARY_NAME) > $(LOG_FILE) 2>&1 & \
		echo $$! > $(PID_FILE); \
		sleep 2; \
		if kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
			echo "$(GREEN)✓ Service started (PID: $$(cat $(PID_FILE)))$(RESET)"; \
			echo "$(YELLOW)Logs: $(LOG_FILE)$(RESET)"; \
			echo "$(YELLOW)Port: $(SERVICE_PORT)$(RESET)"; \
		else \
			echo "$(RED)✗ Failed to start service$(RESET)"; \
			rm -f $(PID_FILE); \
			exit 1; \
		fi; \
	fi

.PHONY: stop
stop: ## Stop the background service
	@if [ -f $(PID_FILE) ]; then \
		PID=$$(cat $(PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(BLUE)Stopping $(SERVICE_NAME) (PID: $$PID)...$(RESET)"; \
			kill $$PID; \
			sleep 2; \
			if kill -0 $$PID 2>/dev/null; then \
				echo "$(YELLOW)Force killing...$(RESET)"; \
				kill -9 $$PID; \
			fi; \
			rm -f $(PID_FILE); \
			echo "$(GREEN)✓ Service stopped$(RESET)"; \
		else \
			echo "$(YELLOW)Service not running$(RESET)"; \
			rm -f $(PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)No PID file found$(RESET)"; \
	fi

.PHONY: restart
restart: stop start ## Restart the service
	@echo "$(GREEN)✓ Service restarted$(RESET)"

.PHONY: status
status: ## Check service status
	@if [ -f $(PID_FILE) ]; then \
		PID=$$(cat $(PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(GREEN)✓ Service running (PID: $$PID)$(RESET)"; \
			echo "$(YELLOW)Port: $(SERVICE_PORT)$(RESET)"; \
			echo "$(YELLOW)Logs: $(LOG_FILE)$(RESET)"; \
			echo "$(YELLOW)Memory usage:$(RESET)"; \
			ps -o pid,ppid,rss,vsz,pcpu,pmem,comm -p $$PID 2>/dev/null || true; \
		else \
			echo "$(RED)✗ Service not running (stale PID file)$(RESET)"; \
			rm -f $(PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)Service not running$(RESET)"; \
	fi

.PHONY: logs
logs: ## Show service logs
	@if [ -f $(LOG_FILE) ]; then \
		echo "$(BLUE)Showing logs from $(LOG_FILE):$(RESET)"; \
		tail -f $(LOG_FILE); \
	else \
		echo "$(YELLOW)No log file found$(RESET)"; \
	fi

.PHONY: logs-tail
logs-tail: ## Tail service logs
	@if [ -f $(LOG_FILE) ]; then \
		tail -n 50 $(LOG_FILE); \
	else \
		echo "$(YELLOW)No log file found$(RESET)"; \
	fi

# =============================================================================
# Utility Targets
# =============================================================================

.PHONY: clean
clean: ## Clean build artifacts and logs
	@echo "$(BLUE)Cleaning build artifacts...$(RESET)"
	@rm -rf $(BIN_DIR) $(LOGS_DIR) $(PID_DIR) dist coverage.out coverage.html
	@echo "$(GREEN)✓ Clean completed$(RESET)"

.PHONY: clean-all
clean-all: stop clean ## Stop service and clean everything
	@echo "$(GREEN)✓ Complete cleanup finished$(RESET)"

.PHONY: install
install: build ## Install binary to GOPATH/bin
	@echo "$(BLUE)Installing $(BINARY_NAME)...$(RESET)"
	@cp $(BIN_DIR)/$(BINARY_NAME) $(GOPATH)/bin/
	@echo "$(GREEN)✓ Installed to $(GOPATH)/bin/$(BINARY_NAME)$(RESET)"

.PHONY: uninstall
uninstall: ## Remove binary from GOPATH/bin
	@echo "$(BLUE)Uninstalling $(BINARY_NAME)...$(RESET)"
	@rm -f $(GOPATH)/bin/$(BINARY_NAME)
	@echo "$(GREEN)✓ Uninstalled$(RESET)"

.PHONY: health
health: ## Check service health
	@echo "$(BLUE)Checking service health...$(RESET)"
	@if curl -f -s http://localhost:$(SERVICE_PORT)/health >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Service is healthy$(RESET)"; \
	else \
		echo "$(RED)✗ Service health check failed$(RESET)"; \
		exit 1; \
	fi

# Default target
.DEFAULT_GOAL := help