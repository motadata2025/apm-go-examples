# OpenTelemetry Zero-Code Instrumentation Testing Platform

[![Go Version](https://img.shields.io/badge/Go-1.24+-blue.svg)](https://golang.org)
[![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-Auto--Instrumentation-blue.svg)](https://opentelemetry.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/nikunj-katariya/otel-zero-code-go-testing)

A comprehensive testing platform for **OpenTelemetry Zero-Code Auto Instrumentation** in Go applications. This project demonstrates the four core libraries currently supported by OpenTelemetry's automatic instrumentation: **Database/SQL**, **gRPC**, **HTTP/REST**, and **Kafka** - providing a complete testing environment for observability without code changes.

## � **Purpose: OpenTelemetry Zero-Code Testing**

This platform is specifically designed to test **OpenTelemetry's Zero-Code Auto Instrumentation** capabilities in Go. It covers all four libraries currently supported by OpenTelemetry automatic instrumentation:

1. **Database/SQL** - PostgreSQL & MySQL operations
2. **gRPC** - High-performance RPC communication
3. **HTTP/REST** - Web API interactions
4. **Kafka** - Event streaming and messaging

## �🏗️ **Architecture Overview**

This platform consists of four interconnected microservices that demonstrate OpenTelemetry auto-instrumentation across different communication patterns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP REST     │    │   gRPC Service  │    │  Database SQL   │
│   Gateway       │◄──►│   gRPC: 50051   │    │  (PostgreSQL +  │
│   Port: 8084    │    │   HTTP: 8083    │    │   MySQL)        │
│                 │    │                 │    │   Port: 8081    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────►│ Kafka Platform  │◄─────────────┘
                        │ Producer: 8082  │
                        │ Broker: 9092    │
                        └─────────────────┘
```

## 🚀 **Services**

| Service | Port | Description | Tech Stack |
|---------|------|-------------|------------|
| **[HTTP REST](./http-rest/)** | 8084 | API Gateway & Control Plane | Go, HTTP/JSON, Middleware |
| **[gRPC Service](./grpc-svc/)** | 50051/8083 | High-performance RPC | Go, gRPC, Protocol Buffers |
| **[Database SQL](./db-sql-multi/)** | 8081 | Multi-database operations | Go, PostgreSQL, MySQL |
| **[Kafka Platform](./kafka-segmentio/)** | 8082 | Event streaming & messaging | Go, Apache Kafka, Docker |

## 🎯 **Key Features**

- **🔄 Microservices Architecture**: Loosely coupled, independently deployable services
- **📊 Multi-Database Support**: PostgreSQL and MySQL integration with connection pooling
- **🚀 High-Performance RPC**: gRPC with Protocol Buffers for efficient communication
- **📨 Event-Driven Architecture**: Apache Kafka for asynchronous messaging
- **🔍 OpenTelemetry Ready**: Zero-code auto instrumentation testing platform
- **🐳 Container Support**: Docker Compose for local development
- **⚡ Production Ready**: Comprehensive Makefiles with cross-platform builds
- **🛡️ Crash-Safe Deployment**: Background service management with auto-restart

## 🚀 **Quick Start**

### Prerequisites

- **Go 1.24+** - [Download](https://golang.org/dl/)
- **Docker & Docker Compose** - [Install](https://docs.docker.com/get-docker/)
- **Make** - Build automation tool
- **PostgreSQL** - Database server
- **MySQL** - Database server

### One-Command Setup

```bash
# Clone the repository
git clone https://github.com/your-org/apm-examples.git
cd apm-examples

# Start everything (infrastructure + build + deploy)
make quick-start
```

This will:
1. 🐳 Start Kafka infrastructure with Docker
2. 🔨 Build all services for your platform
3. 🚀 Deploy all services in background (crash-safe)
4. ✅ Verify health of all components

### Verify Installation

```bash
# Check all services status
make status

# Test the platform
curl http://localhost:8084/books                    # HTTP REST API
curl http://localhost:8082/trigger-produce          # Kafka Producer
curl http://localhost:8081/trigger-crud             # Database Operations
grpcurl -plaintext localhost:50051 list             # gRPC Service
curl http://localhost:8083/health                   # gRPC HTTP Interface
```

## 📖 **Usage Examples**

### API Gateway (HTTP REST)
```bash
# Create a book
curl -X POST http://localhost:8084/books \
  -H "Content-Type: application/json" \
  -d '{"title":"Go Microservices","author":"John Doe"}'

# Trigger all services
curl http://localhost:8084/trigger/allservices
```

### Event Streaming (Kafka)
```bash
# Produce messages
curl http://localhost:8082/trigger-produce

# Check consumer logs
make -C kafka-segmentio logs-consumer
```

### Database Operations
```bash
# Trigger CRUD operations on both PostgreSQL and MySQL
curl http://localhost:8081/trigger-crud
```

### gRPC Communication
```bash
# List available services
grpcurl -plaintext localhost:50051 list

# Call unary RPC
grpcurl -plaintext -d '{"msg":"Hello"}' localhost:50051 echo.v1.EchoService/Say
```

## 🛠️ **Development**

### Individual Service Development
```bash
# Work on a specific service
cd http-rest
make help                    # See all available commands
make run                     # Run locally
make test                    # Run tests
make build-dev              # Development build
```

### Cross-Platform Builds
```bash
# Build for all platforms (Linux, macOS, Windows - amd64/arm64)
make cross-build

# Create distribution packages
make dist
```

### Infrastructure Management
```bash
# Start only infrastructure
make infra-up

# Stop everything
make clean-all

# View logs from all services
make logs
```

## 🔧 **Configuration**

Each service supports environment-based configuration. Copy the example files and customize:

```bash
# Database service
cp db-sql-multi/.env.example db-sql-multi/.env

# Kafka service
cp kafka-segmentio/.env.example kafka-segmentio/.env

# HTTP REST service
cp http-rest/.env.example http-rest/.env

# gRPC service
cp grpc-svc/.env.example grpc-svc/.env
```

See individual service READMEs for detailed configuration options.

## 📊 **Monitoring & Observability**

### Health Checks
```bash
# Check health of all services
make health

# Individual service health
curl http://localhost:8084/health    # HTTP REST
curl http://localhost:8081/health    # Database
```

### Logs & Debugging
```bash
# View all service logs
make logs

# Individual service logs
make -C db-sql-multi logs
make -C grpc-svc logs
make -C http-rest logs
make -C kafka-segmentio logs
```

### Process Management
```bash
# Check running processes
make ps

# Service status
make status

# Restart all services
make restart-all
```

## 🏗️ **Project Structure**

```
apm-examples/
├── 📁 db-sql-multi/          # Database service (PostgreSQL + MySQL)
│   ├── cmd/app/              # Application entry point
│   ├── internal/             # Private application code
│   │   ├── config/           # Configuration management
│   │   ├── db/               # Database connections
│   │   ├── model/            # Data models
│   │   ├── repo/             # Repository pattern
│   │   └── service/          # Business logic
│   ├── .env.example          # Environment template
│   ├── Makefile              # Build automation
│   └── README.md             # Service documentation
├── 📁 grpc-svc/              # gRPC service (server + client)
│   ├── api/proto/            # Protocol Buffer definitions
│   ├── cmd/                  # Server and client entry points
│   ├── internal/             # Private application code
│   ├── .env.example          # Environment template
│   ├── Makefile              # Build automation
│   └── README.md             # Service documentation
├── 📁 http-rest/             # HTTP REST API gateway
│   ├── cmd/api/              # API server entry point
│   ├── internal/             # Private application code
│   │   ├── handlers/         # HTTP handlers
│   │   ├── router/           # Routing and middleware
│   │   └── types/            # Type definitions
│   ├── .env.example          # Environment template
│   ├── Makefile              # Build automation
│   └── README.md             # Service documentation
├── 📁 kafka-segmentio/       # Kafka event streaming
│   ├── cmd/                  # Producer and consumer entry points
│   ├── internal/             # Private application code
│   │   ├── config/           # Configuration management
│   │   ├── kafkautil/        # Kafka utilities
│   │   └── model/            # Event models
│   ├── docker-compose.yml    # Kafka infrastructure
│   ├── .env.example          # Environment template
│   ├── Makefile              # Build automation
│   └── README.md             # Service documentation
├── 📁 scripts/               # Setup and utility scripts
├── 📁 docs/                  # Additional documentation
├── Makefile                  # Master build automation
├── README.md                 # This file
├── docker-compose.yml        # Complete infrastructure
└── .env.example              # Global environment template
```

## 🔐 **Security & Production Considerations**

### Environment Variables
- All sensitive data is externalized via environment variables
- Default values are provided for development
- Production deployments should use secure secret management

### Database Security
- Connection pooling with configurable limits
- Prepared statements to prevent SQL injection
- SSL/TLS support for database connections

### Network Security
- Services communicate over defined ports
- gRPC supports TLS encryption
- HTTP services support HTTPS termination

### Monitoring Integration
- Structured logging throughout all services
- Health check endpoints for load balancers
- Metrics collection points for APM tools

## 🚀 **Deployment**

### Local Development
```bash
# Development with hot reload
make run

# Background services for integration testing
make host
```

### Docker Deployment
```bash
# Build Docker images
docker-compose build

# Deploy complete stack
docker-compose up -d
```

### Production Deployment
```bash
# Build production binaries
make build

# Cross-platform distribution
make dist

# Deploy to target environment
# (Copy binaries and use systemd/supervisor for process management)
```

## 🧪 **Testing**

### Unit Tests
```bash
# Run tests for all services
make test

# Individual service tests
make -C db-sql-multi test
make -C grpc-svc test
```

### Integration Tests
```bash
# Start all services
make host

# Run integration test suite
make test-integration

# API testing
make -C http-rest test-api
```

### Load Testing
```bash
# Kafka load testing
make -C kafka-segmentio test-produce

# HTTP API load testing
ab -n 1000 -c 10 http://localhost:8084/books
```

## 🤝 **Contributing**

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** following the coding standards
4. **Add tests** for new functionality
5. **Run the test suite**: `make test`
6. **Commit your changes**: `git commit -m 'Add amazing feature'`
7. **Push to the branch**: `git push origin feature/amazing-feature`
8. **Open a Pull Request**

### Development Guidelines
- Follow Go best practices and idioms
- Add comprehensive tests for new features
- Update documentation for API changes
- Use conventional commit messages
- Ensure all services pass health checks

## 📚 **Documentation**

- **[Database Service](./db-sql-multi/README.md)** - PostgreSQL & MySQL operations
- **[gRPC Service](./grpc-svc/README.md)** - High-performance RPC communication
- **[HTTP REST Service](./http-rest/README.md)** - API gateway and control plane
- **[Kafka Service](./kafka-segmentio/README.md)** - Event streaming and messaging
- **[API Documentation](./docs/api.md)** - Complete API reference
- **[Deployment Guide](./docs/deployment.md)** - Production deployment instructions

## 🆘 **Troubleshooting**

### Common Issues

**Services won't start:**
```bash
# Check port conflicts
make ps
netstat -tulpn | grep -E "8081|8082|8083|8084|50051|9092"

# Check logs
make logs
```

**Database connection issues:**
```bash
# Verify database servers are running
systemctl status postgresql
systemctl status mysql

# Test connections
make -C db-sql-multi health
```

**Kafka issues:**
```bash
# Restart Kafka infrastructure
make -C kafka-segmentio docker-down
make -C kafka-segmentio docker-up

# Check Kafka status
make -C kafka-segmentio kafka-status
```

### Getting Help

- 📖 Check individual service READMEs
- 🐛 [Report bugs](https://github.com/your-org/apm-examples/issues)
- 💬 [Discussions](https://github.com/your-org/apm-examples/discussions)
- 📧 Contact: [your-email@domain.com](mailto:your-email@domain.com)

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- Go community for excellent tooling and libraries
- Apache Kafka for robust event streaming
- gRPC team for high-performance RPC framework
- Docker for containerization platform

---

**⭐ If this project helps you, please give it a star!**


