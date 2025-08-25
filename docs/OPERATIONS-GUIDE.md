# 🛠️ Operations Guide - APM Examples

**Complete guide for managing, monitoring, and operating your APM platform.**

## 📋 Quick Reference

### **🚀 Essential Commands**
```bash
./quick-start.sh            # Zero-config setup
./start-db-apps.sh          # Start applications
./status-db-apps.sh         # Check status
./stop-db-apps.sh           # Stop applications
./fix-db-issues.sh          # Fix all issues
```

### **🌐 Network Access**
```bash
./setup-machine-ip-access.sh    # Configure network access
./start-machine-ip-apps.sh      # Start with network binding
./test-machine-ip-apps.sh       # Test network accessibility
```

### **🏗️ Infrastructure**
```bash
make infra-only             # Start infrastructure only
make infra-stop             # Stop infrastructure
make infra-clean            # Clean infrastructure
```

---

## 🎮 Service Management

### **Application Lifecycle**

#### **Starting Services**
```bash
# Option 1: Zero-config (Recommended)
./quick-start.sh

# Option 2: Step-by-step
make infra-only              # Start infrastructure
./start-db-apps.sh          # Start applications

# Option 3: Network access
./setup-machine-ip-access.sh
./start-machine-ip-apps.sh
```

#### **Checking Status**
```bash
# Detailed status with health checks
./status-db-apps.sh

# Quick status check
./status-machine-ip-apps.sh  # For network access

# Infrastructure status
docker ps | grep apm-
```

#### **Stopping Services**
```bash
# Stop applications only
./stop-db-apps.sh

# Stop applications with network access
./stop-machine-ip-apps.sh

# Stop infrastructure
make infra-stop

# Stop everything
make infra-clean
./stop-db-apps.sh
```

#### **Restarting Services**
```bash
# Restart applications
./restart-db-apps.sh

# Restart with network access
./stop-machine-ip-apps.sh
./start-machine-ip-apps.sh

# Restart infrastructure
make infra-clean
make infra-only
```

---

## 📊 Monitoring & Health Checks

### **Real-time Monitoring**
```bash
# Application status
./status-db-apps.sh

# Infrastructure status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Resource usage
docker stats

# System resources
htop
iotop
```

### **Health Endpoints**
```bash
# Application health checks
curl http://localhost:8001/health    # Database service
curl http://localhost:8002/health    # Kafka service
curl http://localhost:8003/health    # gRPC service
curl http://localhost:8004/health    # HTTP service

# Infrastructure health
docker exec apm-postgres pg_isready -U testuser
docker exec apm-mysql mysqladmin ping -u testuser -pTest@1234
```

### **Log Monitoring**
```bash
# Application logs
tail -f logs/*.log

# Specific application logs
tail -f logs/db-sql-multi.log
tail -f logs/kafka-consumer.log

# Infrastructure logs
docker logs apm-postgres
docker logs apm-mysql
docker logs apm-kafka
docker logs apm-zookeeper

# Follow infrastructure logs
docker logs -f apm-postgres
```

---

## 🔧 Configuration Management

### **Port Configuration**
```bash
# Check current ports
./status-db-apps.sh

# Port files location
ls logs/*.port

# Manual port check
lsof -i :8001
netstat -tlnp | grep 8001
```

### **Database Configuration**
```bash
# Connection strings
export PG_DSN="postgres://testuser:Test%401234@127.0.0.1:5432/testdb?sslmode=disable"
export MYSQL_DSN="testuser:Test@1234@tcp(127.0.0.1:3306)/testdb?parseTime=true"

# Database admin
open http://localhost:8080
```

### **Environment Variables**
```bash
# Application binding
export BIND_ADDRESS="0.0.0.0"
export HOST="0.0.0.0"
export SERVER_HOST="0.0.0.0"

# Port configuration
export PORT=8001
export HTTP_PORT=8001
```

---

## 🚨 Troubleshooting

### **Automated Diagnostics**
```bash
# Comprehensive fix (recommended)
./fix-db-issues.sh

# Specific issue fixes
./fix-db-issues.sh ports     # Port conflicts
./fix-db-issues.sh docker    # Docker issues
./fix-db-issues.sh db        # Database issues
./fix-db-issues.sh go        # Go environment
./fix-db-issues.sh clean     # Process cleanup
```

### **Manual Diagnostics**

#### **Port Conflicts**
```bash
# Check what's using ports
lsof -i :8001 -i :8002 -i :8003 -i :8004
lsof -i :5432 -i :3306 -i :9092 -i :2181

# Kill conflicting processes
kill <PID>
sudo systemctl stop postgresql
sudo systemctl stop mysql
```

#### **Database Issues**
```bash
# Test database connections
psql "postgres://testuser:Test%401234@localhost:5432/testdb?sslmode=disable" -c "SELECT 1;"
mysql -h localhost -P 3306 -u testuser -pTest@1234 -D testdb -e "SELECT 1;"

# Reinitialize databases
docker exec apm-postgres psql -U testuser -d testdb -f /docker-entrypoint-initdb.d/postgres-init.sql
docker exec apm-mysql mysql -u testuser -pTest@1234 -D testdb < /docker-entrypoint-initdb.d/mysql-init.sql
```

#### **Application Issues**
```bash
# Check application logs
tail -f logs/db-sql-multi.log

# Check Go environment
go version
go env

# Update dependencies
cd db-sql-multi && go mod tidy
```

#### **Docker Issues**
```bash
# Check Docker status
docker info
docker ps -a

# Clean Docker
docker system prune -f
docker volume prune -f

# Restart Docker service
sudo systemctl restart docker
```

---

## 🌐 Network Access Management

### **Local Network Access**
```bash
# Setup for same network access
./setup-machine-ip-access.sh

# Start with network binding
./start-machine-ip-apps.sh

# Test from other devices
curl http://YOUR_MACHINE_IP:8001/trigger-crud
```

### **Public Internet Access**
```bash
# Setup for internet access
./setup-public-endpoints.sh

# Start with public binding
./start-public-apps.sh

# Test public accessibility
./test-public-apps.sh
```

### **Security Considerations**
```bash
# Add security measures
./secure-public-services.sh

# Monitor access
./monitor-public-access.sh

# Check firewall
sudo ufw status
sudo firewall-cmd --list-all
```

---

## 🔄 Backup & Recovery

### **Data Backup**
```bash
# Database backup
docker exec apm-postgres pg_dump -U testuser testdb > backup_postgres.sql
docker exec apm-mysql mysqldump -u testuser -pTest@1234 testdb > backup_mysql.sql

# Configuration backup
tar -czf config_backup.tar.gz logs/ scripts/ *.yml *.sh
```

### **Data Recovery**
```bash
# Restore databases
docker exec -i apm-postgres psql -U testuser testdb < backup_postgres.sql
docker exec -i apm-mysql mysql -u testuser -pTest@1234 testdb < backup_mysql.sql

# Restore configuration
tar -xzf config_backup.tar.gz
```

### **Emergency Recovery**
```bash
# Complete reset
./stop-db-apps.sh
make infra-clean
docker system prune -f
./fix-db-issues.sh
make infra-only
./start-db-apps.sh
```

---

## 📈 Performance Optimization

### **Resource Monitoring**
```bash
# System resources
htop
iotop
nethogs

# Docker resources
docker stats
docker system df

# Application metrics
curl http://localhost:8001/metrics
curl http://localhost:8002/metrics
```

### **Performance Tuning**
```bash
# Database optimization
docker exec apm-postgres psql -U testuser -d testdb -c "ANALYZE;"
docker exec apm-mysql mysql -u testuser -pTest@1234 -D testdb -e "OPTIMIZE TABLE users, orders;"

# Go application optimization
export GOMAXPROCS=$(nproc)
export GOGC=100
```

---

## 🎯 Best Practices

### **Daily Operations**
1. **Morning Check**: `./status-db-apps.sh`
2. **Monitor Logs**: `tail -f logs/*.log`
3. **Health Checks**: Test all endpoints
4. **Resource Check**: `docker stats`

### **Weekly Maintenance**
1. **Clean Docker**: `docker system prune -f`
2. **Update Dependencies**: `go mod tidy` in each service
3. **Backup Data**: Export databases
4. **Security Review**: Check access logs

### **Emergency Procedures**
1. **Service Down**: `./fix-db-issues.sh`
2. **Port Conflicts**: `./fix-db-issues.sh ports`
3. **Database Issues**: `./fix-db-issues.sh db`
4. **Complete Failure**: Emergency recovery procedure

**🎉 Your platform is now professionally managed!** 🚀
