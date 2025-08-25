# =============================================================================
# gRPC Service Dockerfile
# =============================================================================

# Build stage
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata protobuf-dev

# Install protoc plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Generate protobuf code
RUN protoc --go_out=. --go-grpc_out=. api/proto/*.proto

# Build the server application
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s -X main.version=$(git describe --tags --always --dirty 2>/dev/null || echo 'dev') -X main.buildTime=$(date -u '+%Y-%m-%d_%H:%M:%S') -X main.gitCommit=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    -o bin/grpc-server \
    ./cmd/server

# Build the client application
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s -X main.version=$(git describe --tags --always --dirty 2>/dev/null || echo 'dev') -X main.buildTime=$(date -u '+%Y-%m-%d_%H:%M:%S') -X main.gitCommit=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    -o bin/grpc-client \
    ./cmd/client

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates curl

# Install grpc_health_probe for health checks
RUN wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.4.19/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy binaries from builder stage
COPY --from=builder /app/bin/grpc-server .
COPY --from=builder /app/bin/grpc-client .

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 50051

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD grpc_health_probe -addr=localhost:50051 || exit 1

# Run the server by default
CMD ["./grpc-server"]
