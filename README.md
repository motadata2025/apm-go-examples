# 🚀 APM Examples - Complete Development Platform

[![Go Version](https://img.shields.io/badge/Go-1.24+-blue.svg)](https://golang.org)
[![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-Ready-blue.svg)](https://opentelemetry.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com/nikunj-katariya/apm-examples)

**A production-ready, zero-configuration development platform** featuring Go microservices with **Database**, **gRPC**, **HTTP/REST**, and **Kafka** integration. Perfect for testing **OpenTelemetry Auto-Instrumentation**, learning microservices architecture, or rapid prototyping.

> 📚 **New here?** Check out our **[Complete Documentation Index](./DOCUMENTATION-INDEX.md)** for guided navigation through all features and guides!

## ⚡ **30-Second Quick Start**

```bash
# 1. Clone and enter directory
git clone https://github.com/your-org/apm-examples.git
cd apm-examples

# 2. One command to rule them all! 🚀
./quick-start.sh

# 3. Test your endpoints
curl http://localhost:8001/trigger-crud    # Database operations
curl http://localhost:8002/trigger-produce # Kafka messaging
```

**That's it!** Your complete microservices platform is running with databases, message queues, and all services ready to use.

---

## 🎯 **What You Get**

### **🏗️ Complete Infrastructure**
- **PostgreSQL** & **MySQL** databases with sample data
- **Apache Kafka** message queue with auto-created topics
- **Adminer** web-based database admin interface
- **Zero configuration** - everything works out of the box

### **🚀 Production-Ready Services**
- **Database Service** - Multi-database CRUD operations
- **gRPC Service** - High-performance RPC communication
- **HTTP REST API** - RESTful web services
- **Kafka Services** - Event streaming and messaging

### **🛠️ Developer Tools**
- **Intelligent port management** - No more port conflicts
- **Health monitoring** - Real-time service status
- **Comprehensive logging** - Debug with ease
- **Public access ready** - Share your work instantly

---

## 📊 **Architecture Overview**

```
🌐 Public Access (Your Machine IP: 10.128.22.89)
│
├── 🔧 Database Operations    → http://10.128.22.89:8001/trigger-crud
├── 📨 Kafka Messaging       → http://10.128.22.89:8002/trigger-produce
├── 🚀 gRPC Services         → http://10.128.22.89:8003/health
└── 🌍 HTTP REST API         → http://10.128.22.89:8004/books

🏗️ Infrastructure (Internal)
├── 📊 PostgreSQL            → localhost:5432 (testuser/Test@1234/testdb)
├── 📊 MySQL                 → localhost:3306 (testuser/Test@1234/testdb)
├── 📨 Kafka Broker          → localhost:9092
└── 🔧 Database Admin        → http://localhost:8080
```
---

## � **Getting Started**

### **Prerequisites**
- **Go 1.21+** ([Download](https://golang.org/dl/))
- **Docker & Docker Compose** ([Install](https://docs.docker.com/get-docker/))
- **Git** (for cloning)

### **Option 1: Zero-Config Quick Start (Recommended)**

```bash
# 1. Clone the repository
git clone https://github.com/your-org/apm-examples.git
cd apm-examples

# 2. Run the magic script! ✨
./quick-start.sh
```

**What happens:**
- ✅ Automatically detects and fixes port conflicts
- ✅ Starts PostgreSQL, MySQL, and Kafka infrastructure
- ✅ Initializes databases with sample data
- ✅ Starts all applications with intelligent port allocation
- ✅ Provides you with working URLs

### **Option 2: Step-by-Step Setup**

```bash
# 1. Start infrastructure only
make infra-only

# 2. Start database applications
./start-db-apps.sh

# 3. Check status
./status-db-apps.sh
```

### **Option 3: Public Access Setup**

```bash
# Make your endpoints accessible from other devices
./setup-machine-ip-access.sh
./start-machine-ip-apps.sh

# Your endpoints will be available at:
# http://YOUR_MACHINE_IP:PORT/endpoint
```

---

## 🧪 **Testing Your Setup**

### **Quick Health Check**
```bash
# Check all services
./status-db-apps.sh

# Test database operations
curl http://localhost:8001/trigger-crud

# Test Kafka messaging
curl http://localhost:8002/trigger-produce
```

### **Detailed Testing**
```bash
# Comprehensive endpoint testing
./test-machine-ip-apps.sh

# Check infrastructure
make infra-status

# View logs
tail -f logs/*.log
```

---

## 📖 **Usage Examples**

### **🔧 Database Operations**
```bash
# Test multi-database CRUD operations
curl http://localhost:8001/trigger-crud

# Expected response:
# {"message":"Database operation completed successfully"}

# Check database content via Adminer
open http://localhost:8080
```

### **📨 Kafka Messaging**
```bash
# Produce messages to Kafka
curl http://localhost:8002/trigger-produce

# Check consumer logs
tail -f logs/kafka-consumer.log

# View Kafka topics
docker exec apm-kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### **🚀 gRPC Services**
```bash
# Check gRPC health
curl http://localhost:8003/health

# List gRPC services (requires grpcurl)
grpcurl -plaintext localhost:50051 list

# Call gRPC method
grpcurl -plaintext -d '{"msg":"Hello"}' localhost:50051 echo.v1.EchoService/Say
```

### **🌍 HTTP REST API**
```bash
# Test REST endpoints
curl http://localhost:8004/books

# Create a new book
curl -X POST http://localhost:8004/books \
  -H "Content-Type: application/json" \
  -d '{"title":"Go Microservices","author":"John Doe"}'
```

---

## 🛠️ **Management & Operations**

### **🎮 Service Management**
```bash
# Start all services
./start-db-apps.sh              # Database applications
./start-machine-ip-apps.sh      # Public access applications

# Check status
./status-db-apps.sh             # Detailed status with health checks
./status-machine-ip-apps.sh     # Public access status

# Stop services
./stop-db-apps.sh               # Stop applications
./stop-machine-ip-apps.sh       # Stop public applications

# Restart services
./restart-db-apps.sh            # Restart all applications
```

### **🔧 Infrastructure Management**
```bash
# Infrastructure only
make infra-only                 # Start PostgreSQL, MySQL, Kafka
make infra-stop                 # Stop infrastructure
make infra-clean                # Stop and remove all data

# Legacy full setup
make quick-start                # Full Docker setup
make host                       # Build and start everything
make clean-all                  # Complete cleanup
```

### **📊 Monitoring & Debugging**
```bash
# Real-time monitoring
./status-db-apps.sh             # Service status
tail -f logs/*.log              # Application logs
docker logs apm-postgres        # Database logs
docker logs apm-kafka           # Kafka logs

# Health checks
curl http://localhost:8001/health    # Database service
curl http://localhost:8002/health    # Kafka service
curl http://localhost:8003/health    # gRPC service

# Port information
lsof -i :8001                   # Check what's using port 8001
netstat -tlnp | grep 8001       # Alternative port check
```

---

## 🚨 **Troubleshooting**

### **Common Issues & Solutions**

#### **🔴 Port Conflicts**
```bash
# Problem: "address already in use"
# Solution: Use the automatic fix
./fix-db-issues.sh ports

# Or manually check what's using the port
lsof -i :8001
kill <PID>  # Kill the conflicting process
```

#### **🔴 Database Connection Issues**
```bash
# Problem: Database connection failed
# Solution: Comprehensive fix
./fix-db-issues.sh db

# Or restart infrastructure
make infra-clean
make infra-only
```

#### **🔴 Services Won't Start**
```bash
# Problem: Applications fail to start
# Solution: Complete diagnostic and fix
./fix-db-issues.sh

# Check logs for specific errors
tail -f logs/db-sql-multi.log
```

### **🆘 Emergency Recovery**
```bash
# Nuclear option - reset everything
./stop-db-apps.sh
make infra-clean
./fix-db-issues.sh
make infra-only
./start-db-apps.sh
```

---

## 🎯 **Advanced Usage**

### **🌐 Public Access Configuration**
```bash
# Make endpoints accessible from internet
./setup-public-endpoints.sh     # Configure for public access
./start-public-apps.sh          # Start with public bindings
./test-public-apps.sh           # Test public accessibility

# Machine IP access (same network)
./setup-machine-ip-access.sh    # Configure for network access
./start-machine-ip-apps.sh      # Start with machine IP
./test-machine-ip-apps.sh       # Test network accessibility
```

### **🔒 Security Setup**
```bash
# Add security measures
./secure-public-services.sh     # Install fail2ban, rate limiting
./monitor-public-access.sh      # Monitor access logs
```

### **🏗️ Development Workflow**
```bash
# Individual service development
cd db-sql-multi
make help                       # See all available commands
make run                        # Run locally
make test                       # Run tests
make build-dev                  # Development build

# Cross-platform builds
make cross-build                # All platforms
make dist                       # Distribution packages
```

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


