# APM Examples - Simple Branch
# Simple commands for quick setup and deployment

.PHONY: help setup build build-dev build-cross build-all build-static build-dynamic build-cgo build-ldflags build-comprehensive run stop clean ip binaries

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
	@echo "Utilities:"
	@echo "  make binaries    - Show all built binaries"
	@echo ""
	@echo "One-liner: make setup build run ip"

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
	@echo "Starting all services..."
	@cd db-sql-multi && make run-bg
	@cd grpc-svc && make run-bg
	@cd http-rest && make run-bg  
	@cd kafka-segmentio && make run-bg
	@echo "All services running!"

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
	@echo "Stopping all services..."
	@cd db-sql-multi && make stop 2>/dev/null || true
	@cd grpc-svc && make stop 2>/dev/null || true
	@cd http-rest && make stop 2>/dev/null || true
	@cd kafka-segmentio && make stop 2>/dev/null || true
	@docker compose -f docker-compose-simple.yml down
	@echo "All services stopped!"

clean: stop
	@echo "Cleaning everything..."
	@cd db-sql-multi && make clean 2>/dev/null || true
	@cd grpc-svc && make clean 2>/dev/null || true
	@cd http-rest && make clean 2>/dev/null || true
	@cd kafka-segmentio && make clean 2>/dev/null || true
	@docker compose -f docker-compose-simple.yml down -v
	@echo "Everything cleaned!"
