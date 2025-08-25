# 🚀 Quick Start Guide - APM Examples

**Get your complete microservices platform running in under 2 minutes!**

## ⚡ 30-Second Setup

```bash
# 1. Clone and enter
git clone https://github.com/your-org/apm-examples.git
cd apm-examples

# 2. One magic command! ✨
./quick-start.sh

# 3. Test it works
curl http://localhost:8001/trigger-crud
```

**Done!** Your platform is running with databases, message queues, and all services ready.

---

## 🎯 What You Get Instantly

### **🏗️ Complete Infrastructure**
- ✅ **PostgreSQL** database with sample data
- ✅ **MySQL** database with sample data  
- ✅ **Apache Kafka** message queue
- ✅ **Adminer** database admin interface

### **🚀 Working Applications**
- ✅ **Database Service** - Multi-database operations
- ✅ **Kafka Service** - Event streaming
- ✅ **gRPC Service** - High-performance RPC
- ✅ **HTTP REST API** - Web services

### **🛠️ Developer Tools**
- ✅ **Intelligent port management** - No conflicts
- ✅ **Health monitoring** - Real-time status
- ✅ **Comprehensive logging** - Easy debugging
- ✅ **Public access ready** - Network sharing

---

## 🧪 Verify Everything Works

### **Quick Health Check**
```bash
# Check all services
./status-db-apps.sh

# Should show all services running with ✓ status
```

### **Test Each Service**
```bash
# Database operations
curl http://localhost:8001/trigger-crud
# Expected: {"message":"Database operation completed successfully"}

# Kafka messaging
curl http://localhost:8002/trigger-produce  
# Expected: {"message":"Message produced successfully"}

# gRPC health
curl http://localhost:8003/health
# Expected: {"status":"ok"}

# HTTP REST API
curl http://localhost:8004/books
# Expected: JSON array of books
```

### **Check Infrastructure**
```bash
# Database admin interface
open http://localhost:8080

# PostgreSQL: Server=apm-postgres, User=testuser, Password=Test@1234, Database=testdb
# MySQL: Server=apm-mysql, User=testuser, Password=Test@1234, Database=testdb
```

---

## 🌐 Enable Network Access

**Make your endpoints accessible from other devices:**

```bash
# Setup network access
./setup-machine-ip-access.sh

# Start with network binding
./start-machine-ip-apps.sh

# Test network accessibility
./test-machine-ip-apps.sh

# Your endpoints will be available at:
# http://YOUR_MACHINE_IP:PORT/endpoint
```

---

## 🛠️ Management Commands

### **Application Management**
```bash
./start-db-apps.sh          # Start applications
./stop-db-apps.sh           # Stop applications  
./restart-db-apps.sh        # Restart applications
./status-db-apps.sh         # Check status
```

### **Infrastructure Management**
```bash
make infra-only             # Start infrastructure only
make infra-stop             # Stop infrastructure
make infra-clean            # Clean infrastructure
```

### **Troubleshooting**
```bash
./fix-db-issues.sh          # Fix all common issues
./fix-db-issues.sh ports    # Fix port conflicts only
./fix-db-issues.sh db       # Fix database issues only
```

---

## 🚨 Common Issues & Solutions

### **🔴 "Port already in use"**
```bash
# Automatic fix
./fix-db-issues.sh ports

# Manual check
lsof -i :8001
kill <PID>
```

### **🔴 "Database connection failed"**
```bash
# Comprehensive fix
./fix-db-issues.sh db

# Or restart infrastructure
make infra-clean
make infra-only
```

### **🔴 "Services won't start"**
```bash
# Complete diagnostic and fix
./fix-db-issues.sh

# Check specific logs
tail -f logs/db-sql-multi.log
```

### **🔴 "Docker issues"**
```bash
# Clean restart
docker system prune -f
make infra-clean
make infra-only
```

---

## 🎯 Next Steps

### **🔍 Explore the Platform**
- **[Usage Examples](./README.md#usage-examples)** - Learn each service
- **[API Documentation](./README.md#api-documentation)** - Endpoint details
- **[Architecture Guide](./README.md#architecture)** - System design

### **🛠️ Start Developing**
- **[Development Guide](./README.md#development)** - Build your own services
- **[Testing Guide](./README.md#testing)** - Write and run tests
- **[Deployment Guide](./README.md#deployment)** - Production deployment

### **🌐 Share Your Work**
- **[Public Access Guide](./PUBLIC-ACCESS-GUIDE.md)** - Internet access
- **[Security Guide](./README.md#security)** - Secure your endpoints
- **[Monitoring Guide](./README.md#monitoring)** - Production monitoring

---

## 🆘 Need Help?

### **Quick Help**
```bash
make help                   # All available commands
./status-db-apps.sh         # Current status
tail -f logs/*.log          # View logs
```

### **Documentation**
- **[Complete README](./README.md)** - Full documentation
- **[Database Management](./DATABASE-MANAGEMENT.md)** - Database operations
- **[Public Access Guide](./PUBLIC-ACCESS-GUIDE.md)** - Network access
- **[Troubleshooting](./README.md#troubleshooting)** - Problem solving

### **Emergency Recovery**
```bash
# Nuclear option - reset everything
./stop-db-apps.sh
make infra-clean
./fix-db-issues.sh
make infra-only
./start-db-apps.sh
```

**🎉 You're all set! Happy coding!** 🚀
