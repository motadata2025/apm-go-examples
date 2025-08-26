# =============================================================================
# gRPC Service Makefile
# =============================================================================

# Project configuration
PROJECT_NAME := grpc-svc
SERVER_BINARY := grpc-server
CLIENT_BINARY := grpc-client
SERVER_MAIN := ./cmd/server
CLIENT_MAIN := ./cmd/client
BIN_DIR := bin
LOGS_DIR := logs
PID_DIR := pids
PROTO_DIR := api/proto

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
SERVER_PORT := 50051
SERVER_PID_FILE := $(PID_DIR)/$(SERVER_BINARY).pid
SERVER_LOG_FILE := $(LOGS_DIR)/$(SERVER_BINARY).log

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
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(build|cross|dist|proto)"
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

.PHONY: proto-deps
proto-deps: ## Install protobuf dependencies
	@echo "$(BLUE)Installing protobuf dependencies...$(RESET)"
	@if ! command -v protoc >/dev/null 2>&1; then \
		echo "$(RED)protoc not found. Please install Protocol Buffers compiler$(RESET)"; \
		exit 1; \
	fi
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	@echo "$(GREEN)✓ Protobuf dependencies installed$(RESET)"

# =============================================================================
# Protocol Buffers
# =============================================================================

.PHONY: proto
proto: proto-deps ## Generate Go code from protobuf files
	@echo "$(BLUE)Generating protobuf code...$(RESET)"
	@if [ -d "$(PROTO_DIR)" ]; then \
		protoc --go_out=. --go-grpc_out=. $(PROTO_DIR)/*.proto; \
		echo "$(GREEN)✓ Protobuf code generated$(RESET)"; \
	else \
		echo "$(YELLOW)No proto directory found, skipping...$(RESET)"; \
	fi

.PHONY: proto-clean
proto-clean: ## Clean generated protobuf files
	@echo "$(BLUE)Cleaning generated protobuf files...$(RESET)"
	@find . -name "*.pb.go" -delete
	@echo "$(GREEN)✓ Generated protobuf files cleaned$(RESET)"

# =============================================================================
# Build Targets
# =============================================================================

.PHONY: build
build: setup deps proto ## Build both server and client binaries (production standards)
	@echo "$(BLUE)Building $(PROJECT_NAME) binaries...$(RESET)"
	@echo "$(YELLOW)Version: $(VERSION)$(RESET)"
	@echo "$(YELLOW)Build Time: $(BUILD_TIME)$(RESET)"
	@echo "$(YELLOW)Git Commit: $(GIT_COMMIT)$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(SERVER_BINARY) $(SERVER_MAIN)
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(CLIENT_BINARY) $(CLIENT_MAIN)
	@echo "$(GREEN)✓ Build complete:$(RESET)"
	@echo "  $(GREEN)$(BIN_DIR)/$(SERVER_BINARY)$(RESET)"
	@echo "  $(GREEN)$(BIN_DIR)/$(CLIENT_BINARY)$(RESET)"

.PHONY: build-server
build-server: setup deps proto ## Build only the server binary
	@echo "$(BLUE)Building $(SERVER_BINARY)...$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(SERVER_BINARY) $(SERVER_MAIN)
	@echo "$(GREEN)✓ Server build complete: $(BIN_DIR)/$(SERVER_BINARY)$(RESET)"

.PHONY: build-client
build-client: setup deps proto ## Build only the client binary
	@echo "$(BLUE)Building $(CLIENT_BINARY)...$(RESET)"
	@CGO_ENABLED=0 go build $(BUILD_FLAGS) -o $(BIN_DIR)/$(CLIENT_BINARY) $(CLIENT_MAIN)
	@echo "$(GREEN)✓ Client build complete: $(BIN_DIR)/$(CLIENT_BINARY)$(RESET)"

.PHONY: build-dev
build-dev: setup proto ## Build binaries for development (with debug info)
	@echo "$(BLUE)Building $(PROJECT_NAME) for development...$(RESET)"
	@go build -race -o $(BIN_DIR)/$(SERVER_BINARY)-dev $(SERVER_MAIN)
	@go build -race -o $(BIN_DIR)/$(CLIENT_BINARY)-dev $(CLIENT_MAIN)
	@echo "$(GREEN)✓ Development builds complete$(RESET)"

# =============================================================================
# Cross-compilation
# =============================================================================

.PHONY: cross-build
cross-build: setup deps proto ## Build for all supported platforms
	@echo "$(BLUE)Building for all platforms...$(RESET)"
	@for platform in $(PLATFORMS); do \
		os=$$(echo $$platform | cut -d'/' -f1); \
		arch=$$(echo $$platform | cut -d'/' -f2); \
		server_output=$(BIN_DIR)/$(SERVER_BINARY)-$$os-$$arch; \
		client_output=$(BIN_DIR)/$(CLIENT_BINARY)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then \
			server_output=$$server_output.exe; \
			client_output=$$client_output.exe; \
		fi; \
		echo "$(YELLOW)Building for $$os/$$arch...$(RESET)"; \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build $(BUILD_FLAGS) -o $$server_output $(SERVER_MAIN); \
		CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch go build $(BUILD_FLAGS) -o $$client_output $(CLIENT_MAIN); \
		if [ $$? -eq 0 ]; then \
			echo "$(GREEN)✓ $$server_output$(RESET)"; \
			echo "$(GREEN)✓ $$client_output$(RESET)"; \
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
		server_binary=$(SERVER_BINARY)-$$os-$$arch; \
		client_binary=$(CLIENT_BINARY)-$$os-$$arch; \
		if [ "$$os" = "windows" ]; then \
			server_binary=$$server_binary.exe; \
			client_binary=$$client_binary.exe; \
		fi; \
		if [ -f "$(BIN_DIR)/$$server_binary" ] && [ -f "$(BIN_DIR)/$$client_binary" ]; then \
			package_name=$(PROJECT_NAME)-$(VERSION)-$$os-$$arch; \
			mkdir -p dist/$$package_name; \
			cp $(BIN_DIR)/$$server_binary dist/$$package_name/$(SERVER_BINARY)$$(if [ "$$os" = "windows" ]; then echo ".exe"; fi); \
			cp $(BIN_DIR)/$$client_binary dist/$$package_name/$(CLIENT_BINARY)$$(if [ "$$os" = "windows" ]; then echo ".exe"; fi); \
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
run: ## Run the gRPC server locally
	@echo "$(BLUE)Running $(SERVER_BINARY) locally...$(RESET)"
	@echo "$(YELLOW)Server will be available on port $(SERVER_PORT)$(RESET)"
	@go run $(SERVER_MAIN)

.PHONY: run-bg
run-bg: build ## Run gRPC server and client in background
	@echo "$(BLUE)Starting gRPC services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY) > $(LOGS_DIR)/$(SERVER_BINARY).log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY).pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY) > $(LOGS_DIR)/$(CLIENT_BINARY).log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY).pid
	@echo "$(GREEN)✓ gRPC server started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY).pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY).pid))$(RESET)"
	@echo "$(YELLOW)Server available on port $(SERVER_PORT), Client on port $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-dev
run-bg-dev: build-dev ## Run development gRPC services in background
	@echo "$(BLUE)Starting gRPC development services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY)-dev > $(LOGS_DIR)/$(SERVER_BINARY)-dev.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-dev.pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-dev > $(LOGS_DIR)/$(CLIENT_BINARY)-dev.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-dev.pid
	@echo "$(GREEN)✓ gRPC server-dev started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-dev.pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client-dev started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-dev.pid))$(RESET)"
	@echo "$(YELLOW)Development services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-static
run-bg-static: ## Run static gRPC services in background
	@echo "$(BLUE)Starting gRPC static services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY)-static > $(LOGS_DIR)/$(SERVER_BINARY)-static.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-static.pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-static > $(LOGS_DIR)/$(CLIENT_BINARY)-static.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-static.pid
	@echo "$(GREEN)✓ gRPC server-static started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-static.pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client-static started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-static.pid))$(RESET)"
	@echo "$(YELLOW)Static services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-dynamic
run-bg-dynamic: ## Run dynamic gRPC services in background
	@echo "$(BLUE)Starting gRPC dynamic services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY)-dynamic > $(LOGS_DIR)/$(SERVER_BINARY)-dynamic.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-dynamic.pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-dynamic > $(LOGS_DIR)/$(CLIENT_BINARY)-dynamic.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-dynamic.pid
	@echo "$(GREEN)✓ gRPC server-dynamic started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-dynamic.pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client-dynamic started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-dynamic.pid))$(RESET)"
	@echo "$(YELLOW)Dynamic services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-cgo
run-bg-cgo: ## Run CGO gRPC services in background
	@echo "$(BLUE)Starting gRPC CGO services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY)-cgo > $(LOGS_DIR)/$(SERVER_BINARY)-cgo.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-cgo.pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-cgo > $(LOGS_DIR)/$(CLIENT_BINARY)-cgo.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-cgo.pid
	@echo "$(GREEN)✓ gRPC server-cgo started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-cgo.pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client-cgo started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-cgo.pid))$(RESET)"
	@echo "$(YELLOW)CGO services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-debug
run-bg-debug: ## Run debug gRPC services in background
	@echo "$(BLUE)Starting gRPC debug services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY)-debug > $(LOGS_DIR)/$(SERVER_BINARY)-debug.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-debug.pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-debug > $(LOGS_DIR)/$(CLIENT_BINARY)-debug.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-debug.pid
	@echo "$(GREEN)✓ gRPC server-debug started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-debug.pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client-debug started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-debug.pid))$(RESET)"
	@echo "$(YELLOW)Debug services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-optimized
run-bg-optimized: ## Run optimized gRPC services in background
	@echo "$(BLUE)Starting gRPC optimized services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@nohup ./$(BIN_DIR)/$(SERVER_BINARY)-optimized > $(LOGS_DIR)/$(SERVER_BINARY)-optimized.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-optimized.pid
	@nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-optimized > $(LOGS_DIR)/$(CLIENT_BINARY)-optimized.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-optimized.pid
	@echo "$(GREEN)✓ gRPC server-optimized started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-optimized.pid))$(RESET)"
	@echo "$(GREEN)✓ gRPC client-optimized started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-optimized.pid))$(RESET)"
	@echo "$(YELLOW)Optimized services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-profile
run-bg-profile: ## Run profile gRPC services in background (requires build-ldflags)
	@echo "$(BLUE)Starting gRPC profile services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@if [ -f $(BIN_DIR)/$(SERVER_BINARY)-profile ]; then \
		nohup ./$(BIN_DIR)/$(SERVER_BINARY)-profile > $(LOGS_DIR)/$(SERVER_BINARY)-profile.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-profile.pid; \
		echo "$(GREEN)✓ gRPC server-profile started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-profile.pid))$(RESET)"; \
	else \
		echo "$(YELLOW)Profile server binary not found, skipping...$(RESET)"; \
	fi
	@if [ -f $(BIN_DIR)/$(CLIENT_BINARY)-profile ]; then \
		nohup ./$(BIN_DIR)/$(CLIENT_BINARY)-profile > $(LOGS_DIR)/$(CLIENT_BINARY)-profile.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-profile.pid; \
		echo "$(GREEN)✓ gRPC client-profile started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-profile.pid))$(RESET)"; \
	else \
		echo "$(YELLOW)Profile client binary not found, skipping...$(RESET)"; \
	fi
	@echo "$(YELLOW)Profile services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-cross
run-bg-cross: ## Run cross-platform gRPC services for current OS/arch
	@echo "$(BLUE)Starting gRPC cross-platform services in background...$(RESET)"
	@mkdir -p $(LOGS_DIR) $(PID_DIR)
	@OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
	ARCH=$$(uname -m); \
	if [ "$$ARCH" = "x86_64" ]; then ARCH="amd64"; fi; \
	if [ "$$ARCH" = "aarch64" ]; then ARCH="arm64"; fi; \
	SERVER_PATH="./$(BIN_DIR)/$(SERVER_BINARY)-$$OS-$$ARCH"; \
	CLIENT_PATH="./$(BIN_DIR)/$(CLIENT_BINARY)-$$OS-$$ARCH"; \
	if [ -f "$$SERVER_PATH" ]; then \
		nohup $$SERVER_PATH > $(LOGS_DIR)/$(SERVER_BINARY)-cross.log 2>&1 & echo $$! > $(PID_DIR)/$(SERVER_BINARY)-cross.pid; \
		echo "$(GREEN)✓ gRPC server-cross started (PID: $$(cat $(PID_DIR)/$(SERVER_BINARY)-cross.pid))$(RESET)"; \
	else \
		echo "$(RED)✗ Cross-platform server binary not found: $$SERVER_PATH$(RESET)"; \
	fi; \
	if [ -f "$$CLIENT_PATH" ]; then \
		nohup $$CLIENT_PATH > $(LOGS_DIR)/$(CLIENT_BINARY)-cross.log 2>&1 & echo $$! > $(PID_DIR)/$(CLIENT_BINARY)-cross.pid; \
		echo "$(GREEN)✓ gRPC client-cross started (PID: $$(cat $(PID_DIR)/$(CLIENT_BINARY)-cross.pid))$(RESET)"; \
	else \
		echo "$(RED)✗ Cross-platform client binary not found: $$CLIENT_PATH$(RESET)"; \
	fi
	@echo "$(YELLOW)Cross-platform services available on ports $(SERVER_PORT), $(CLIENT_PORT)$(RESET)"

.PHONY: run-bg-all
run-bg-all: ## Run all gRPC build variants (dev + cross)
	@echo "$(BLUE)Starting all gRPC build variants...$(RESET)"
	@make run-bg-dev
	@make run-bg-cross
	@echo "$(GREEN)✓ All gRPC build variants running$(RESET)"

.PHONY: run-bg-comprehensive
run-bg-comprehensive: ## Run comprehensive gRPC test suite (all compilation variants)
	@echo "$(BLUE)Starting comprehensive gRPC test suite...$(RESET)"
	@make run-bg
	@make run-bg-dev
	@make run-bg-static
	@make run-bg-dynamic
	@make run-bg-cgo
	@make run-bg-debug
	@make run-bg-optimized
	@make run-bg-profile
	@echo "$(GREEN)✓ Comprehensive gRPC test suite running$(RESET)"

.PHONY: run-server
run-server: build-server ## Run the built server
	@echo "$(BLUE)Running built $(SERVER_BINARY)...$(RESET)"
	@$(BIN_DIR)/$(SERVER_BINARY)

.PHONY: run-client
run-client: build-client ## Run the built client
	@echo "$(BLUE)Running built $(CLIENT_BINARY)...$(RESET)"
	@$(BIN_DIR)/$(CLIENT_BINARY)

.PHONY: run-dev
run-dev: build-dev ## Run development builds
	@echo "$(BLUE)Running development server...$(RESET)"
	@$(BIN_DIR)/$(SERVER_BINARY)-dev

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
host: build-server start ## Build and start gRPC server in background (crash-safe)
	@echo "$(GREEN)✓ gRPC server hosted successfully$(RESET)"

.PHONY: start
start: setup ## Start gRPC server in background
	@if [ -f $(SERVER_PID_FILE) ] && kill -0 $$(cat $(SERVER_PID_FILE)) 2>/dev/null; then \
		echo "$(YELLOW)gRPC server already running (PID: $$(cat $(SERVER_PID_FILE)))$(RESET)"; \
	else \
		echo "$(BLUE)Starting $(SERVER_BINARY) in background...$(RESET)"; \
		nohup $(BIN_DIR)/$(SERVER_BINARY) > $(SERVER_LOG_FILE) 2>&1 & \
		echo $$! > $(SERVER_PID_FILE); \
		sleep 2; \
		if kill -0 $$(cat $(SERVER_PID_FILE)) 2>/dev/null; then \
			echo "$(GREEN)✓ gRPC server started (PID: $$(cat $(SERVER_PID_FILE)))$(RESET)"; \
			echo "$(YELLOW)Logs: $(SERVER_LOG_FILE)$(RESET)"; \
			echo "$(YELLOW)Port: $(SERVER_PORT)$(RESET)"; \
		else \
			echo "$(RED)✗ Failed to start gRPC server$(RESET)"; \
			rm -f $(SERVER_PID_FILE); \
			exit 1; \
		fi; \
	fi

.PHONY: stop
stop: ## Stop the background gRPC server
	@if [ -f $(SERVER_PID_FILE) ]; then \
		PID=$$(cat $(SERVER_PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(BLUE)Stopping $(SERVER_BINARY) (PID: $$PID)...$(RESET)"; \
			kill $$PID; \
			sleep 2; \
			if kill -0 $$PID 2>/dev/null; then \
				echo "$(YELLOW)Force killing...$(RESET)"; \
				kill -9 $$PID; \
			fi; \
			rm -f $(SERVER_PID_FILE); \
			echo "$(GREEN)✓ gRPC server stopped$(RESET)"; \
		else \
			echo "$(YELLOW)gRPC server not running$(RESET)"; \
			rm -f $(SERVER_PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)No PID file found$(RESET)"; \
	fi

.PHONY: stop-dev
stop-dev: ## Stop development gRPC services
	@echo "$(BLUE)Stopping gRPC development services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-dev.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-dev.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-dev.pid; \
			echo "$(GREEN)✓ gRPC server-dev stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-dev.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-dev.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-dev.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-dev.pid; \
			echo "$(GREEN)✓ gRPC client-dev stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-dev.pid; \
		fi; \
	fi

.PHONY: stop-static
stop-static: ## Stop static gRPC services
	@echo "$(BLUE)Stopping gRPC static services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-static.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-static.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-static.pid; \
			echo "$(GREEN)✓ gRPC server-static stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-static.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-static.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-static.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-static.pid; \
			echo "$(GREEN)✓ gRPC client-static stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-static.pid; \
		fi; \
	fi

.PHONY: stop-dynamic
stop-dynamic: ## Stop dynamic gRPC services
	@echo "$(BLUE)Stopping gRPC dynamic services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-dynamic.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-dynamic.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-dynamic.pid; \
			echo "$(GREEN)✓ gRPC server-dynamic stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-dynamic.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-dynamic.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-dynamic.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-dynamic.pid; \
			echo "$(GREEN)✓ gRPC client-dynamic stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-dynamic.pid; \
		fi; \
	fi

.PHONY: stop-cgo
stop-cgo: ## Stop CGO gRPC services
	@echo "$(BLUE)Stopping gRPC CGO services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-cgo.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-cgo.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-cgo.pid; \
			echo "$(GREEN)✓ gRPC server-cgo stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-cgo.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-cgo.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-cgo.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-cgo.pid; \
			echo "$(GREEN)✓ gRPC client-cgo stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-cgo.pid; \
		fi; \
	fi

.PHONY: stop-debug
stop-debug: ## Stop debug gRPC services
	@echo "$(BLUE)Stopping gRPC debug services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-debug.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-debug.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-debug.pid; \
			echo "$(GREEN)✓ gRPC server-debug stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-debug.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-debug.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-debug.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-debug.pid; \
			echo "$(GREEN)✓ gRPC client-debug stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-debug.pid; \
		fi; \
	fi

.PHONY: stop-optimized
stop-optimized: ## Stop optimized gRPC services
	@echo "$(BLUE)Stopping gRPC optimized services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-optimized.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-optimized.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-optimized.pid; \
			echo "$(GREEN)✓ gRPC server-optimized stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-optimized.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-optimized.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-optimized.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-optimized.pid; \
			echo "$(GREEN)✓ gRPC client-optimized stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-optimized.pid; \
		fi; \
	fi

.PHONY: stop-profile
stop-profile: ## Stop profile gRPC services
	@echo "$(BLUE)Stopping gRPC profile services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-profile.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-profile.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-profile.pid; \
			echo "$(GREEN)✓ gRPC server-profile stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-profile.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-profile.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-profile.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-profile.pid; \
			echo "$(GREEN)✓ gRPC client-profile stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-profile.pid; \
		fi; \
	fi

.PHONY: stop-cross
stop-cross: ## Stop cross-platform gRPC services
	@echo "$(BLUE)Stopping gRPC cross-platform services...$(RESET)"
	@if [ -f $(PID_DIR)/$(SERVER_BINARY)-cross.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(SERVER_BINARY)-cross.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(SERVER_BINARY)-cross.pid; \
			echo "$(GREEN)✓ gRPC server-cross stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(SERVER_BINARY)-cross.pid; \
		fi; \
	fi
	@if [ -f $(PID_DIR)/$(CLIENT_BINARY)-cross.pid ]; then \
		PID=$$(cat $(PID_DIR)/$(CLIENT_BINARY)-cross.pid); \
		if kill -0 $$PID 2>/dev/null; then \
			kill $$PID && rm -f $(PID_DIR)/$(CLIENT_BINARY)-cross.pid; \
			echo "$(GREEN)✓ gRPC client-cross stopped$(RESET)"; \
		else \
			rm -f $(PID_DIR)/$(CLIENT_BINARY)-cross.pid; \
		fi; \
	fi

.PHONY: stop-all
stop-all: ## Stop all gRPC build variants (dev + cross)
	@echo "$(BLUE)Stopping all gRPC build variants...$(RESET)"
	@make stop-dev 2>/dev/null || true
	@make stop-cross 2>/dev/null || true
	@echo "$(GREEN)✓ All gRPC build variants stopped$(RESET)"

.PHONY: stop-comprehensive
stop-comprehensive: ## Stop comprehensive gRPC test suite (all compilation variants)
	@echo "$(BLUE)Stopping comprehensive gRPC test suite...$(RESET)"
	@make stop 2>/dev/null || true
	@make stop-dev 2>/dev/null || true
	@make stop-static 2>/dev/null || true
	@make stop-dynamic 2>/dev/null || true
	@make stop-cgo 2>/dev/null || true
	@make stop-debug 2>/dev/null || true
	@make stop-optimized 2>/dev/null || true
	@make stop-profile 2>/dev/null || true
	@echo "$(GREEN)✓ Comprehensive gRPC test suite stopped$(RESET)"

.PHONY: restart
restart: stop start ## Restart the gRPC server
	@echo "$(GREEN)✓ gRPC server restarted$(RESET)"

.PHONY: status
status: ## Check gRPC server status
	@if [ -f $(SERVER_PID_FILE) ]; then \
		PID=$$(cat $(SERVER_PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "$(GREEN)✓ gRPC server running (PID: $$PID)$(RESET)"; \
			echo "$(YELLOW)Port: $(SERVER_PORT)$(RESET)"; \
			echo "$(YELLOW)Logs: $(SERVER_LOG_FILE)$(RESET)"; \
			echo "$(YELLOW)Memory usage:$(RESET)"; \
			ps -o pid,ppid,rss,vsz,pcpu,pmem,comm -p $$PID 2>/dev/null || true; \
		else \
			echo "$(RED)✗ gRPC server not running (stale PID file)$(RESET)"; \
			rm -f $(SERVER_PID_FILE); \
		fi; \
	else \
		echo "$(YELLOW)gRPC server not running$(RESET)"; \
	fi

.PHONY: logs
logs: ## Show gRPC server logs
	@if [ -f $(SERVER_LOG_FILE) ]; then \
		echo "$(BLUE)Showing logs from $(SERVER_LOG_FILE):$(RESET)"; \
		tail -f $(SERVER_LOG_FILE); \
	else \
		echo "$(YELLOW)No log file found$(RESET)"; \
	fi

.PHONY: logs-tail
logs-tail: ## Tail gRPC server logs
	@if [ -f $(SERVER_LOG_FILE) ]; then \
		tail -n 50 $(SERVER_LOG_FILE); \
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
clean-all: stop clean proto-clean ## Stop server and clean everything
	@echo "$(GREEN)✓ Complete cleanup finished$(RESET)"

.PHONY: install
install: build ## Install binaries to GOPATH/bin
	@echo "$(BLUE)Installing $(PROJECT_NAME) binaries...$(RESET)"
	@cp $(BIN_DIR)/$(SERVER_BINARY) $(GOPATH)/bin/
	@cp $(BIN_DIR)/$(CLIENT_BINARY) $(GOPATH)/bin/
	@echo "$(GREEN)✓ Installed to $(GOPATH)/bin/$(RESET)"

.PHONY: uninstall
uninstall: ## Remove binaries from GOPATH/bin
	@echo "$(BLUE)Uninstalling $(PROJECT_NAME) binaries...$(RESET)"
	@rm -f $(GOPATH)/bin/$(SERVER_BINARY)
	@rm -f $(GOPATH)/bin/$(CLIENT_BINARY)
	@echo "$(GREEN)✓ Uninstalled$(RESET)"

.PHONY: health
health: ## Check gRPC server health
	@echo "$(BLUE)Checking gRPC server health...$(RESET)"
	@if command -v grpcurl >/dev/null 2>&1; then \
		if grpcurl -plaintext localhost:$(SERVER_PORT) list >/dev/null 2>&1; then \
			echo "$(GREEN)✓ gRPC server is healthy$(RESET)"; \
		else \
			echo "$(RED)✗ gRPC server health check failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)grpcurl not installed, checking port only$(RESET)"; \
		if nc -z localhost $(SERVER_PORT) 2>/dev/null; then \
			echo "$(GREEN)✓ gRPC server port is open$(RESET)"; \
		else \
			echo "$(RED)✗ gRPC server port is not accessible$(RESET)"; \
			exit 1; \
		fi; \
	fi

.PHONY: grpcurl-install
grpcurl-install: ## Install grpcurl for testing
	@echo "$(BLUE)Installing grpcurl...$(RESET)"
	@go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
	@echo "$(GREEN)✓ grpcurl installed$(RESET)"

# Default target
.DEFAULT_GOAL := help
