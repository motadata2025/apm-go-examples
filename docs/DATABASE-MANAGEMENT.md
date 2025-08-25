# 🗄️ Database Management System

This document describes the comprehensive database management system that prevents all common database issues during development.

## 🚀 Quick Start

```bash
# 1. Start infrastructure
./quick-start.sh

# 2. Start database applications (with intelligent port management)
./start-db-apps.sh

# 3. Check status
./status-db-apps.sh
```

## 🛠️ Management Scripts

### Core Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `./start-db-apps.sh` | Start database applications with intelligent port management | `./start-db-apps.sh` |
| `./stop-db-apps.sh` | Gracefully stop all database applications | `./stop-db-apps.sh` |
| `./restart-db-apps.sh` | Restart all database applications | `./restart-db-apps.sh` |
| `./status-db-apps.sh` | Check application status and health | `./status-db-apps.sh` |
| `./fix-db-issues.sh` | Comprehensive diagnostic and fix tool | `./fix-db-issues.sh` |

### Troubleshooting Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `./fix-db-issues.sh` | **COMPREHENSIVE FIX** - Solves all common issues | `./fix-db-issues.sh` |
| `./fix-db-issues.sh ports` | Fix port conflicts only | `./fix-db-issues.sh ports` |
| `./fix-db-issues.sh db` | Test and fix database connections | `./fix-db-issues.sh db` |
| `./fix-db-issues.sh clean` | Clean up orphaned processes | `./fix-db-issues.sh clean` |

## 🔧 Problem Prevention Features

### 1. **Intelligent Port Management**
- **Auto-detects port conflicts** and finds available ports
- **No more "address already in use" errors**
- **Dynamic port allocation** for database applications
- **Port tracking** in `logs/*.port` files

### 2. **Database Connection Validation**
- **Pre-flight checks** before starting applications
- **Connection string validation** for both PostgreSQL and MySQL
- **Automatic database initialization** if tables are missing
- **Health checks** with retry logic

### 3. **Process Management**
- **PID tracking** for all applications
- **Graceful shutdown** with SIGTERM before SIGKILL
- **Orphaned process cleanup**
- **Memory usage monitoring**

### 4. **Dependency Management**
- **Automatic `go mod tidy`** before starting applications
- **Dependency download** verification
- **Go environment validation**

## 📊 What Gets Monitored

### Infrastructure Services
- ✅ PostgreSQL (port 5432)
- ✅ MySQL (port 3306)
- ✅ Kafka (port 9092)
- ✅ ZooKeeper (port 2181)

### Database Applications
- ✅ `db-sql-multi` - Multi-database SQL operations
- ✅ `db-gorm` - GORM ORM operations

### Health Checks
- ✅ Process status (running/stopped)
- ✅ Port availability
- ✅ HTTP endpoint responses
- ✅ Database connectivity
- ✅ Memory usage

## 🚨 Common Issues & Solutions

### Issue: "Port already in use"
**Solution:** Run `./fix-db-issues.sh ports` or use `./start-db-apps.sh` (auto-detects available ports)

### Issue: "Database connection failed"
**Solution:** Run `./fix-db-issues.sh db` to test and reinitialize databases

### Issue: "Application won't start"
**Solution:** Run `./fix-db-issues.sh` for comprehensive diagnosis and fix

### Issue: "Orphaned processes"
**Solution:** Run `./fix-db-issues.sh clean` to clean up all processes

### Issue: "Infrastructure not running"
**Solution:** Run `make infra-only` to restart infrastructure

## 📁 File Structure

```
apm-examples/
├── start-db-apps.sh      # 🚀 Main launcher with intelligent port management
├── stop-db-apps.sh       # 🛑 Graceful application stopper
├── restart-db-apps.sh    # 🔄 Application restarter
├── status-db-apps.sh     # 📊 Status and health checker
├── fix-db-issues.sh      # 🔧 Comprehensive diagnostic and fix tool
├── logs/                 # 📝 Application logs and tracking files
│   ├── *.log            # Application logs
│   ├── *.pid            # Process ID files
│   └── *.port           # Port tracking files
└── DATABASE-MANAGEMENT.md # 📖 This documentation
```

## 🎯 Best Practices

### 1. **Always Use the Management Scripts**
```bash
# ✅ Good
./start-db-apps.sh

# ❌ Avoid
cd db-sql-multi && go run cmd/app/main.go
```

### 2. **Check Status Before Troubleshooting**
```bash
./status-db-apps.sh  # See what's actually running
```

### 3. **Use Comprehensive Fix for Unknown Issues**
```bash
./fix-db-issues.sh   # Solves 99% of problems
```

### 4. **Monitor Logs**
```bash
tail -f logs/*.log   # Watch application logs in real-time
```

## 🔍 Debugging Commands

```bash
# Check what's running
./status-db-apps.sh

# View logs
tail -f logs/db-sql-multi.log
tail -f logs/db-gorm.log

# Check infrastructure
docker ps | grep apm-

# Test database connections manually
psql "postgres://testuser:Test%401234@localhost:5432/testdb?sslmode=disable" -c "SELECT 1;"
mysql -h localhost -P 3306 -u testuser -pTest@1234 -D testdb -e "SELECT 1;"

# Check port usage
lsof -i :8001  # Check specific port
lsof -i :5432  # Check PostgreSQL
lsof -i :3306  # Check MySQL
```

## 🎉 Success Indicators

When everything is working correctly, you should see:

```bash
$ ./status-db-apps.sh

📊 Database Applications Status
================================

Infrastructure Status:
  apm-postgres: RUNNING
  apm-mysql: RUNNING
  apm-kafka: RUNNING
  apm-zookeeper: RUNNING

Database Applications:
db-sql-multi:
  Status: RUNNING (PID: 12345)
  Port: 8001
  URL: http://localhost:8001
  Health: OK
  Memory: 25MB

db-gorm:
  Status: RUNNING (PID: 12346)
  Port: 8005
  URL: http://localhost:8005
  Health: OK
  Memory: 23MB
```

## 🆘 Emergency Recovery

If everything is broken:

```bash
# Nuclear option - reset everything
./stop-db-apps.sh
make infra-clean
./fix-db-issues.sh
make infra-only
./start-db-apps.sh
```

This will completely reset your development environment and fix all issues.
