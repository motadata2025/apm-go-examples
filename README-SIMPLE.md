# 🚀 APM Examples - Simple Branch

**Ultra-simple setup for quick deployment and testing**

## ⚡ Quick Start (4 Commands)

```bash
# 1. Setup infrastructure
make setup

# 2. Build all services  
make build

# 3. Run all services in background
make run

# 4. Get your machine IPs and test URLs
make ip
```

**That's it! All services are running with production binaries.**

## 🎯 What You Get

### **Services Running:**
- **Database Service** (PostgreSQL + MySQL) - Port 8081
- **gRPC Service** (Server + Client) - Ports 50051, 8083  
- **HTTP REST API** (Gateway) - Port 8084
- **Kafka Service** (Producer + Consumer) - Port 8082

### **All Built as Production Binaries:**
- `db-sql-multi/bin/db-sql-multi`
- `grpc-svc/bin/grpc-server` + `grpc-svc/bin/grpc-client`
- `http-rest/bin/http-rest-api`
- `kafka-segmentio/bin/kafka-producer` + `kafka-segmentio/bin/kafka-consumer`

### **External Access Ready:**
- Shows your machine's local IP (e.g., `10.20.41.77`)
- Shows your public IP (if available)
- Provides test URLs for external access

## 🌐 External Access URLs

After running `make ip`, you'll get URLs like:
```
Database:    http://YOUR_IP:8081/trigger-crud
Kafka:       http://YOUR_IP:8082/trigger-produce  
gRPC Client: http://YOUR_IP:8083/trigger-stream
HTTP REST:   http://YOUR_IP:8084/trigger/allservices
gRPC Server: grpc://YOUR_IP:50051
```

## 🧪 Test Commands

```bash
# Test all endpoints
curl http://YOUR_IP:8081/trigger-crud
curl http://YOUR_IP:8082/trigger-produce
curl http://YOUR_IP:8083/trigger-stream
curl http://YOUR_IP:8084/trigger/allservices

# Test gRPC
grpcurl -plaintext YOUR_IP:50051 list
```

## 🛠️ Available Commands

```bash
make help     # Show all commands
make setup    # Setup Docker infrastructure  
make build    # Build all services to bin/ directories
make run      # Run all services in background
make ip       # Show machine IPs and access URLs
make stop     # Stop all services
make clean    # Clean everything
```

## 📦 Deployment Ready

This branch is designed for:
- ✅ **Quick deployment** to any machine
- ✅ **Minimal configuration** required
- ✅ **Production binaries** (not source code)
- ✅ **External access** ready
- ✅ **Cross-platform** builds available

## 🔧 Requirements

- **Docker & Docker Compose** (for infrastructure)
- **Go 1.21+** (for building)
- **Make** (for automation)

## 🎯 Perfect For

- **Testing OpenTelemetry** auto-instrumentation
- **Demo deployments** on new machines
- **External access** testing
- **Production-like** environments
- **Quick prototyping** and validation

---

**Simple. Clean. Production-ready.** 🚀
