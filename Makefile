# APM Examples - Simple Branch
# Simple commands for quick setup and deployment

.PHONY: help setup build build-dev build-cross build-all build-static build-dynamic build-cgo build-ldflags build-comprehensive run run-dev run-cross run-all run-static run-dynamic run-cgo run-debug run-optimized run-profile run-comprehensive stop stop-dev stop-cross stop-all stop-static stop-dynamic stop-cgo stop-debug stop-optimized stop-profile stop-comprehensive clean ip binaries

help:
	@echo "APM Examples - Simple Commands"
	@echo "=============================="
	@echo ""
	@echo "Quick Start:"
	@echo "  make setup       - Setup Docker infrastructure"
	@echo "  make build       - Build all services (production)"
	@echo "  make run         - Run all services in background"
	@echo "  make ip          - Show machine IPs and access URLs"
	@echo "  make stop        - Stop all services"
	@echo "  make clean       - Clean everything"
	@echo ""
	@echo "Build Options:"
	@echo "  make build        - Production builds (current platform)"
	@echo "  make build-dev    - Development builds with race detection"
	@echo "  make build-cross  - Cross-platform builds (all architectures)"
	@echo "  make build-all    - All build types (dev + cross-platform)"
	@echo ""
	@echo "Advanced Build Options:"
	@echo "  make build-static      - Static builds (no external dependencies)"
	@echo "  make build-dynamic     - Dynamic builds (with shared libraries)"
	@echo "  make build-cgo         - CGO-enabled builds (C interop)"
	@echo "  make build-ldflags     - Custom LDFLAGS builds (optimized/debug)"
	@echo "  make build-comprehensive - ALL compilation variants (testing suite)"
	@echo ""
	@echo "Run Options (by build variant):"
	@echo "  make run               - Run production builds"
	@echo "  make run-dev           - Run development builds (race detection)"
	@echo "  make run-cross         - Run cross-platform builds (current OS)"
	@echo "  make run-all           - Run all builds (dev + cross)"
	@echo "  make run-static        - Run static builds (no dependencies)"
	@echo "  make run-dynamic       - Run dynamic builds (shared libraries)"
	@echo "  make run-cgo           - Run CGO builds (C interop)"
	@echo "  make run-debug         - Run debug builds (full symbols)"
	@echo "  make run-optimized     - Run optimized builds (performance)"
	@echo "  make run-profile       - Run profile builds (profiling enabled)"
	@echo "  make run-comprehensive - Run comprehensive test suite"
	@echo ""
	@echo "Stop Options (by build variant):"
	@echo "  make stop               - Stop production builds"
	@echo "  make stop-dev           - Stop development builds"
	@echo "  make stop-cross         - Stop cross-platform builds"
	@echo "  make stop-all           - Stop all builds (dev + cross)"
	@echo "  make stop-static        - Stop static builds"
	@echo "  make stop-dynamic       - Stop dynamic builds"
	@echo "  make stop-cgo           - Stop CGO builds"
	@echo "  make stop-debug         - Stop debug builds"
	@echo "  make stop-optimized     - Stop optimized builds"
	@echo "  make stop-profile       - Stop profile builds"
	@echo "  make stop-comprehensive - Stop comprehensive test suite"
	@echo ""
	@echo "Utilities:"
	@echo "  make binaries     - Show all built binaries"
	@echo ""
	@echo "Quick Start: make setup build run ip"
	@echo "Testing:     make build-comprehensive run-static ip"

setup:
	@echo "Setting up Docker infrastructure..."
	docker compose -f docker-compose-simple.yml up -d
	@echo "Waiting for services to be ready..."
	@sleep 15
	@echo "Infrastructure ready!"

# Build all services (production)
build:
	@echo "Building all services (production)..."
	@cd db-sql-multi && make build
	@cd grpc-svc && make build
	@cd http-rest && make build
	@cd kafka-segmentio && make build
	@echo "All services built!"

# Build all services (development with race detection)
build-dev:
	@echo "Building all services (development with race detection)..."
	@cd db-sql-multi && make build-dev
	@cd grpc-svc && make build-dev
	@cd http-rest && make build-dev
	@cd kafka-segmentio && make build-dev
	@echo "All development builds complete!"

# Build all services for multiple platforms
build-cross:
	@echo "Building all services for multiple platforms..."
	@echo "This will create binaries for Linux, macOS, and Windows (AMD64 & ARM64)"
	@cd db-sql-multi && make cross-build
	@cd grpc-svc && make cross-build
	@cd http-rest && make cross-build
	@cd kafka-segmentio && make cross-build
	@echo "Cross-platform builds complete!"
	@echo ""
	@echo "Built binaries are available in each service's bin/ directory:"
	@echo "  db-sql-multi/bin/     - Database service binaries"
	@echo "  grpc-svc/bin/         - gRPC server & client binaries"
	@echo "  http-rest/bin/        - HTTP REST API binaries"
	@echo "  kafka-segmentio/bin/  - Kafka producer & consumer binaries"

# Build all variants (dev + cross-platform)
build-all: build-dev build-cross
	@echo "All build variants complete!"
	@echo ""
	@echo "Available builds:"
	@echo "  Production:     bin/<service>"
	@echo "  Development:    bin/<service>-dev"
	@echo "  Cross-platform: bin/<service>-<os>-<arch>"

# Build static binaries (no external dependencies)
build-static:
	@echo "Building all services (static linking)..."
	@echo "These binaries will have no external dependencies"
	@cd db-sql-multi && CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static" -s -w' -o bin/db-sql-multi-static ./cmd/app
	@cd grpc-svc && CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static" -s -w' -o bin/grpc-server-static ./cmd/server && \
		CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static" -s -w' -o bin/grpc-client-static ./cmd/client
	@cd http-rest && CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static" -s -w' -o bin/http-rest-api-static ./cmd/api
	@cd kafka-segmentio && CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static" -s -w' -o bin/kafka-producer-static ./cmd/producer && \
		CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static" -s -w' -o bin/kafka-consumer-static ./cmd/consumer
	@echo "Static builds complete! (suffix: -static)"

# Build dynamic binaries (with shared libraries)
build-dynamic:
	@echo "Building all services (dynamic linking)..."
	@echo "These binaries will use shared system libraries"
	@cd db-sql-multi && CGO_ENABLED=1 go build -ldflags '-linkmode external' -o bin/db-sql-multi-dynamic ./cmd/app
	@cd grpc-svc && CGO_ENABLED=1 go build -ldflags '-linkmode external' -o bin/grpc-server-dynamic ./cmd/server && \
		CGO_ENABLED=1 go build -ldflags '-linkmode external' -o bin/grpc-client-dynamic ./cmd/client
	@cd http-rest && CGO_ENABLED=1 go build -ldflags '-linkmode external' -o bin/http-rest-api-dynamic ./cmd/api
	@cd kafka-segmentio && CGO_ENABLED=1 go build -ldflags '-linkmode external' -o bin/kafka-producer-dynamic ./cmd/producer && \
		CGO_ENABLED=1 go build -ldflags '-linkmode external' -o bin/kafka-consumer-dynamic ./cmd/consumer
	@echo "Dynamic builds complete! (suffix: -dynamic)"

# Build CGO-enabled binaries (C interoperability)
build-cgo:
	@echo "Building all services (CGO enabled)..."
	@echo "These binaries can interoperate with C libraries"
	@cd db-sql-multi && CGO_ENABLED=1 go build -race -o bin/db-sql-multi-cgo ./cmd/app
	@cd grpc-svc && CGO_ENABLED=1 go build -race -o bin/grpc-server-cgo ./cmd/server && \
		CGO_ENABLED=1 go build -race -o bin/grpc-client-cgo ./cmd/client
	@cd http-rest && CGO_ENABLED=1 go build -race -o bin/http-rest-api-cgo ./cmd/api
	@cd kafka-segmentio && CGO_ENABLED=1 go build -race -o bin/kafka-producer-cgo ./cmd/producer && \
		CGO_ENABLED=1 go build -race -o bin/kafka-consumer-cgo ./cmd/consumer
	@echo "CGO builds complete! (suffix: -cgo)"

# Build with custom LDFLAGS (optimized/debug variants)
build-ldflags:
	@echo "Building all services with custom LDFLAGS..."
	@echo "Creating optimized, debug, and profiling variants"
	@cd db-sql-multi && \
		go build -ldflags '-s -w -X main.buildType=optimized' -o bin/db-sql-multi-optimized ./cmd/app && \
		go build -ldflags '-X main.buildType=debug' -gcflags='-N -l' -o bin/db-sql-multi-debug ./cmd/app && \
		go build -ldflags '-X main.buildType=profile' -o bin/db-sql-multi-profile ./cmd/app
	@cd grpc-svc && \
		go build -ldflags '-s -w -X main.buildType=optimized' -o bin/grpc-server-optimized ./cmd/server && \
		go build -ldflags '-s -w -X main.buildType=optimized' -o bin/grpc-client-optimized ./cmd/client && \
		go build -ldflags '-X main.buildType=debug' -gcflags='-N -l' -o bin/grpc-server-debug ./cmd/server && \
		go build -ldflags '-X main.buildType=debug' -gcflags='-N -l' -o bin/grpc-client-debug ./cmd/client
	@cd http-rest && \
		go build -ldflags '-s -w -X main.buildType=optimized' -o bin/http-rest-api-optimized ./cmd/api && \
		go build -ldflags '-X main.buildType=debug' -gcflags='-N -l' -o bin/http-rest-api-debug ./cmd/api
	@cd kafka-segmentio && \
		go build -ldflags '-s -w -X main.buildType=optimized' -o bin/kafka-producer-optimized ./cmd/producer && \
		go build -ldflags '-s -w -X main.buildType=optimized' -o bin/kafka-consumer-optimized ./cmd/consumer && \
		go build -ldflags '-X main.buildType=debug' -gcflags='-N -l' -o bin/kafka-producer-debug ./cmd/producer && \
		go build -ldflags '-X main.buildType=debug' -gcflags='-N -l' -o bin/kafka-consumer-debug ./cmd/consumer
	@echo "LDFLAGS builds complete! (suffixes: -optimized, -debug, -profile)"

# Build comprehensive test suite (all compilation variants)
build-comprehensive: build build-dev build-static build-dynamic build-cgo build-ldflags
	@echo ""
	@echo "🎯 COMPREHENSIVE BUILD COMPLETE!"
	@echo "================================="
	@echo ""
	@echo "All compilation variants built for OpenTelemetry testing:"
	@echo "  ✅ Production builds     (standard)"
	@echo "  ✅ Development builds    (race detection)"
	@echo "  ✅ Static builds         (no dependencies)"
	@echo "  ✅ Dynamic builds        (shared libraries)"
	@echo "  ✅ CGO builds            (C interop)"
	@echo "  ✅ LDFLAGS builds        (optimized/debug)"
	@echo ""
	@echo "Use 'make binaries' to see all available binaries"
	@echo "Perfect for testing OpenTelemetry auto-instrumentation across different compilation scenarios!"

run:
	@echo "Starting all services (production builds)..."
	@cd db-sql-multi && make run-bg
	@cd grpc-svc && make run-bg
	@cd http-rest && make run-bg
	@cd kafka-segmentio && make run-bg
	@echo "All services running!"

# Run development builds (with race detection)
run-dev: build-dev
	@echo "Starting all services (development builds with race detection)..."
	@cd db-sql-multi && make run-bg-dev
	@cd grpc-svc && make run-bg-dev
	@cd http-rest && make run-bg-dev
	@cd kafka-segmentio && make run-bg-dev
	@echo "All development services running!"

# Run static builds (no external dependencies)
run-static: build-static
	@echo "Starting all services (static builds - no dependencies)..."
	@cd db-sql-multi && make run-bg-static
	@cd grpc-svc && make run-bg-static
	@cd http-rest && make run-bg-static
	@cd kafka-segmentio && make run-bg-static
	@echo "All static services running!"

# Run dynamic builds (with shared libraries)
run-dynamic: build-dynamic
	@echo "Starting all services (dynamic builds - shared libraries)..."
	@cd db-sql-multi && make run-bg-dynamic
	@cd grpc-svc && make run-bg-dynamic
	@cd http-rest && make run-bg-dynamic
	@cd kafka-segmentio && make run-bg-dynamic
	@echo "All dynamic services running!"

# Run CGO builds (C interoperability)
run-cgo: build-cgo
	@echo "Starting all services (CGO builds - C interop)..."
	@cd db-sql-multi && make run-bg-cgo
	@cd grpc-svc && make run-bg-cgo
	@cd http-rest && make run-bg-cgo
	@cd kafka-segmentio && make run-bg-cgo
	@echo "All CGO services running!"

# Run debug builds (full debugging symbols)
run-debug: build-ldflags
	@echo "Starting all services (debug builds - full symbols)..."
	@cd db-sql-multi && make run-bg-debug
	@cd grpc-svc && make run-bg-debug
	@cd http-rest && make run-bg-debug
	@cd kafka-segmentio && make run-bg-debug
	@echo "All debug services running!"

# Run optimized builds (performance optimized)
run-optimized: build-ldflags
	@echo "Starting all services (optimized builds - performance)..."
	@cd db-sql-multi && make run-bg-optimized
	@cd grpc-svc && make run-bg-optimized
	@cd http-rest && make run-bg-optimized
	@cd kafka-segmentio && make run-bg-optimized
	@echo "All optimized services running!"

# Run profile builds (profiling enabled)
run-profile: build-ldflags
	@echo "Starting all services (profile builds - profiling enabled)..."
	@cd db-sql-multi && make run-bg-profile
	@cd grpc-svc && make run-bg-profile
	@cd http-rest && make run-bg-profile
	@cd kafka-segmentio && make run-bg-profile
	@echo "All profile services running!"

# Run cross-platform builds (current OS/arch)
run-cross: build-cross
	@echo "Starting all services (cross-platform builds for current OS)..."
	@cd db-sql-multi && make run-bg-cross
	@cd grpc-svc && make run-bg-cross
	@cd http-rest && make run-bg-cross
	@cd kafka-segmentio && make run-bg-cross
	@echo "All cross-platform services running!"

# Run all builds (dev + cross-platform)
run-all: build-all
	@echo "Starting all services (all build variants)..."
	@cd db-sql-multi && make run-bg-all
	@cd grpc-svc && make run-bg-all
	@cd http-rest && make run-bg-all
	@cd kafka-segmentio && make run-bg-all
	@echo "All build variant services running!"

# Run comprehensive test suite (all compilation variants)
run-comprehensive: build-comprehensive
	@echo "Starting comprehensive test suite (all compilation variants)..."
	@echo "This will run ALL build variants for complete OpenTelemetry testing"
	@cd db-sql-multi && make run-bg-comprehensive
	@cd grpc-svc && make run-bg-comprehensive
	@cd http-rest && make run-bg-comprehensive
	@cd kafka-segmentio && make run-bg-comprehensive
	@echo "Comprehensive test suite running!"

ip:
	@echo "Machine IP Addresses & Access URLs"
	@echo "=================================="
	@echo ""
	@echo "Your Machine IPs:"
	@LOCAL_IP=$$(ip route get 8.8.8.8 | awk '{print $$7; exit}' 2>/dev/null || echo "127.0.0.1"); \
	PUBLIC_IP=$$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo "Not available"); \
	echo "  Local IP:  $$LOCAL_IP"; \
	echo "  Public IP: $$PUBLIC_IP"; \
	echo ""; \
	echo "Service URLs (use Local IP for external access):"; \
	echo "  Database:    http://$$LOCAL_IP:8081/trigger-crud"; \
	echo "  Kafka:       http://$$LOCAL_IP:8082/trigger-produce"; \
	echo "  gRPC Client: http://$$LOCAL_IP:8083/trigger-stream"; \
	echo "  HTTP REST:   http://$$LOCAL_IP:8084/trigger/allservices"; \
	echo "  gRPC Server: grpc://$$LOCAL_IP:50051"; \
	echo ""; \
	echo "Test Commands:"; \
	echo "  curl http://$$LOCAL_IP:8081/trigger-crud"; \
	echo "  curl http://$$LOCAL_IP:8082/trigger-produce"; \
	echo "  curl http://$$LOCAL_IP:8083/trigger-stream"; \
	echo "  curl http://$$LOCAL_IP:8084/trigger/allservices"

# Show all built binaries
binaries:
	@echo "Available Binaries"
	@echo "=================="
	@echo ""
	@for service in db-sql-multi grpc-svc http-rest kafka-segmentio; do \
		echo "$$service/bin/:"; \
		if [ -d "$$service/bin" ]; then \
			ls -la $$service/bin/ | grep -E '^-' | awk '{printf "  %-30s %s %s %s\n", $$9, $$5, $$6, $$7}' || echo "  (no binaries found)"; \
		else \
			echo "  (bin directory not found)"; \
		fi; \
		echo ""; \
	done

stop:
	@echo "Stopping all services (production builds)..."
	@cd db-sql-multi && make stop 2>/dev/null || true
	@cd grpc-svc && make stop 2>/dev/null || true
	@cd http-rest && make stop 2>/dev/null || true
	@cd kafka-segmentio && make stop 2>/dev/null || true
	@docker compose -f docker-compose-simple.yml down
	@echo "All services stopped!"

# Stop development builds
stop-dev:
	@echo "Stopping all services (development builds)..."
	@cd db-sql-multi && make stop-dev 2>/dev/null || true
	@cd grpc-svc && make stop-dev 2>/dev/null || true
	@cd http-rest && make stop-dev 2>/dev/null || true
	@cd kafka-segmentio && make stop-dev 2>/dev/null || true
	@echo "All development services stopped!"

# Stop static builds
stop-static:
	@echo "Stopping all services (static builds)..."
	@cd db-sql-multi && make stop-static 2>/dev/null || true
	@cd grpc-svc && make stop-static 2>/dev/null || true
	@cd http-rest && make stop-static 2>/dev/null || true
	@cd kafka-segmentio && make stop-static 2>/dev/null || true
	@echo "All static services stopped!"

# Stop dynamic builds
stop-dynamic:
	@echo "Stopping all services (dynamic builds)..."
	@cd db-sql-multi && make stop-dynamic 2>/dev/null || true
	@cd grpc-svc && make stop-dynamic 2>/dev/null || true
	@cd http-rest && make stop-dynamic 2>/dev/null || true
	@cd kafka-segmentio && make stop-dynamic 2>/dev/null || true
	@echo "All dynamic services stopped!"

# Stop CGO builds
stop-cgo:
	@echo "Stopping all services (CGO builds)..."
	@cd db-sql-multi && make stop-cgo 2>/dev/null || true
	@cd grpc-svc && make stop-cgo 2>/dev/null || true
	@cd http-rest && make stop-cgo 2>/dev/null || true
	@cd kafka-segmentio && make stop-cgo 2>/dev/null || true
	@echo "All CGO services stopped!"

# Stop debug builds
stop-debug:
	@echo "Stopping all services (debug builds)..."
	@cd db-sql-multi && make stop-debug 2>/dev/null || true
	@cd grpc-svc && make stop-debug 2>/dev/null || true
	@cd http-rest && make stop-debug 2>/dev/null || true
	@cd kafka-segmentio && make stop-debug 2>/dev/null || true
	@echo "All debug services stopped!"

# Stop optimized builds
stop-optimized:
	@echo "Stopping all services (optimized builds)..."
	@cd db-sql-multi && make stop-optimized 2>/dev/null || true
	@cd grpc-svc && make stop-optimized 2>/dev/null || true
	@cd http-rest && make stop-optimized 2>/dev/null || true
	@cd kafka-segmentio && make stop-optimized 2>/dev/null || true
	@echo "All optimized services stopped!"

# Stop profile builds
stop-profile:
	@echo "Stopping all services (profile builds)..."
	@cd db-sql-multi && make stop-profile 2>/dev/null || true
	@cd grpc-svc && make stop-profile 2>/dev/null || true
	@cd http-rest && make stop-profile 2>/dev/null || true
	@cd kafka-segmentio && make stop-profile 2>/dev/null || true
	@echo "All profile services stopped!"

# Stop cross-platform builds
stop-cross:
	@echo "Stopping all services (cross-platform builds)..."
	@cd db-sql-multi && make stop-cross 2>/dev/null || true
	@cd grpc-svc && make stop-cross 2>/dev/null || true
	@cd http-rest && make stop-cross 2>/dev/null || true
	@cd kafka-segmentio && make stop-cross 2>/dev/null || true
	@echo "All cross-platform services stopped!"

# Stop all builds (dev + cross-platform)
stop-all:
	@echo "Stopping all services (all build variants)..."
	@cd db-sql-multi && make stop-all 2>/dev/null || true
	@cd grpc-svc && make stop-all 2>/dev/null || true
	@cd http-rest && make stop-all 2>/dev/null || true
	@cd kafka-segmentio && make stop-all 2>/dev/null || true
	@echo "All build variant services stopped!"

# Stop comprehensive test suite
stop-comprehensive:
	@echo "Stopping comprehensive test suite (all compilation variants)..."
	@cd db-sql-multi && make stop-comprehensive 2>/dev/null || true
	@cd grpc-svc && make stop-comprehensive 2>/dev/null || true
	@cd http-rest && make stop-comprehensive 2>/dev/null || true
	@cd kafka-segmentio && make stop-comprehensive 2>/dev/null || true
	@echo "Comprehensive test suite stopped!"

clean: stop
	@echo "Cleaning everything..."
	@cd db-sql-multi && make clean 2>/dev/null || true
	@cd grpc-svc && make clean 2>/dev/null || true
	@cd http-rest && make clean 2>/dev/null || true
	@cd kafka-segmentio && make clean 2>/dev/null || true
	@docker compose -f docker-compose-simple.yml down -v
	@echo "Everything cleaned!"
