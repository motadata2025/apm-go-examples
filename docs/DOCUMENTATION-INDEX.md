# 📚 Documentation Index - APM Examples

**Your complete guide to the APM Examples platform. Everything you need to know in one place.**

## 🚀 Getting Started

### **New to APM Examples?**
1. **[Quick Start Guide](./QUICK-START.md)** - Get running in 2 minutes
2. **[README](./README.md)** - Complete platform overview
3. **[Architecture Guide](./README.md#architecture)** - System design

### **First Steps**
```bash
# 1. Clone the repository
git clone https://github.com/your-org/apm-examples.git
cd apm-examples

# 2. Run the magic setup
./quick-start.sh

# 3. Verify everything works
./status-db-apps.sh
```

---

## 📖 Core Documentation

### **📋 Essential Guides**
| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[README.md](./README.md)** | Complete platform overview | First read, reference |
| **[QUICK-START.md](./QUICK-START.md)** | 2-minute setup guide | Getting started |
| **[OPERATIONS-GUIDE.md](./OPERATIONS-GUIDE.md)** | Daily operations & management | Running the platform |
| **[DATABASE-MANAGEMENT.md](./DATABASE-MANAGEMENT.md)** | Database operations | Database issues |
| **[PUBLIC-ACCESS-GUIDE.md](./PUBLIC-ACCESS-GUIDE.md)** | Network & internet access | Sharing your work |

### **🔧 Technical References**
| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[Makefile](./Makefile)** | Build & automation commands | Development workflow |
| **[docker-compose.minimal.yml](./docker-compose.minimal.yml)** | Infrastructure definition | Understanding setup |
| **Service READMEs** | Individual service docs | Service-specific work |

---

## 🎯 Quick Navigation

### **🚀 I want to...**

#### **Get Started**
- **Start from scratch** → [Quick Start Guide](./QUICK-START.md)
- **Understand the platform** → [README](./README.md)
- **See what's included** → [Architecture Overview](./README.md#architecture)

#### **Use the Platform**
- **Test the services** → [Usage Examples](./README.md#usage-examples)
- **Check service status** → `./status-db-apps.sh`
- **View logs** → `tail -f logs/*.log`
- **Stop/start services** → [Operations Guide](./OPERATIONS-GUIDE.md)

#### **Share My Work**
- **Access from other devices** → [Machine IP Setup](./README.md#public-access)
- **Make it internet accessible** → [Public Access Guide](./PUBLIC-ACCESS-GUIDE.md)
- **Secure public access** → [Security Setup](./PUBLIC-ACCESS-GUIDE.md#security)

#### **Develop & Customize**
- **Build my own service** → [Development Guide](./README.md#development)
- **Understand the code** → Individual service READMEs
- **Add new features** → [Architecture Guide](./README.md#architecture)

#### **Fix Problems**
- **Something's not working** → `./fix-db-issues.sh`
- **Port conflicts** → [Troubleshooting](./README.md#troubleshooting)
- **Database issues** → [Database Management](./DATABASE-MANAGEMENT.md)
- **Emergency recovery** → [Operations Guide](./OPERATIONS-GUIDE.md#emergency-recovery)

---

## 🛠️ Command Reference

### **🎮 Essential Commands**
```bash
# Setup & Start
./quick-start.sh                    # Zero-config setup
./start-db-apps.sh                  # Start applications
./setup-machine-ip-access.sh        # Network access setup

# Status & Monitoring
./tools/monitoring/check-services.sh  # Expert service monitoring
./status-db-apps.sh                 # Application status
./test-machine-ip-apps.sh           # Test network access
make help                           # All available commands

# Expert Tools & Reports
./quick-start-expert.sh             # Expert automation setup
../COMPREHENSIVE_TEST_REPORT.md     # Complete testing results (94 tests)
../EXPERT-FIXES-SUMMARY.md          # Expert-level improvements

# Troubleshooting
./fix-db-issues.sh                  # Fix all issues
./fix-db-issues.sh ports            # Fix port conflicts
./fix-db-issues.sh db               # Fix database issues

# Infrastructure
make infra-only                     # Start infrastructure
make infra-stop                     # Stop infrastructure
make infra-clean                    # Clean infrastructure
```

### **📊 Testing Commands**
```bash
# Test individual services
curl http://localhost:8001/trigger-crud     # Database operations
curl http://localhost:8002/trigger-produce  # Kafka messaging
curl http://localhost:8003/health           # gRPC health
curl http://localhost:8004/books            # HTTP REST API

# Test network access
curl http://YOUR_MACHINE_IP:8001/trigger-crud

# Infrastructure tests
docker ps | grep apm-                       # Check containers
docker logs apm-postgres                    # Database logs
```

---

## 🏗️ Architecture Quick Reference

### **🚀 Services**
- **Database Service** (Port 8001) - PostgreSQL & MySQL operations
- **Kafka Service** (Port 8002) - Event streaming & messaging
- **gRPC Service** (Port 8003) - High-performance RPC
- **HTTP REST API** (Port 8004) - Web services

### **🏗️ Infrastructure**
- **PostgreSQL** (Port 5432) - Primary database
- **MySQL** (Port 3306) - Secondary database
- **Apache Kafka** (Port 9092) - Message broker
- **Adminer** (Port 8080) - Database admin interface

### **🌐 Access Patterns**
- **Local Access** - `http://localhost:PORT`
- **Network Access** - `http://MACHINE_IP:PORT`
- **Public Access** - `http://PUBLIC_IP:PORT` (with setup)

---

## 🚨 Troubleshooting Quick Reference

### **Common Issues**
| Problem | Quick Fix | Detailed Guide |
|---------|-----------|----------------|
| Port conflicts | `./fix-db-issues.sh ports` | [Troubleshooting](./README.md#troubleshooting) |
| Database connection failed | `./fix-db-issues.sh db` | [Database Management](./DATABASE-MANAGEMENT.md) |
| Services won't start | `./fix-db-issues.sh` | [Operations Guide](./OPERATIONS-GUIDE.md) |
| Docker issues | `make infra-clean && make infra-only` | [Operations Guide](./OPERATIONS-GUIDE.md) |

### **Emergency Recovery**
```bash
# Nuclear option - reset everything
./stop-db-apps.sh
make infra-clean
./fix-db-issues.sh
make infra-only
./start-db-apps.sh
```

---

## 📁 File Structure Reference

```
apm-examples/
├── 📚 Documentation
│   ├── README.md                    # Main documentation
│   ├── QUICK-START.md              # Getting started guide
│   ├── OPERATIONS-GUIDE.md         # Operations manual
│   ├── DATABASE-MANAGEMENT.md      # Database guide
│   └── PUBLIC-ACCESS-GUIDE.md      # Network access guide
│
├── 🛠️ Management Scripts
│   ├── quick-start.sh              # Zero-config setup
│   ├── start-db-apps.sh            # Start applications
│   ├── status-db-apps.sh           # Check status
│   ├── fix-db-issues.sh            # Fix issues
│   └── setup-machine-ip-access.sh  # Network setup
│
├── 🏗️ Infrastructure
│   ├── docker-compose.minimal.yml  # Infrastructure definition
│   ├── scripts/                    # Database initialization
│   └── Makefile                    # Build automation
│
├── 🚀 Services
│   ├── db-sql-multi/               # Database service
│   ├── grpc-svc/                   # gRPC service
│   ├── http-rest/                  # HTTP REST API
│   └── kafka-segmentio/            # Kafka services
│
└── 📊 Runtime
    └── logs/                       # Application logs
```

---

## 🎓 Learning Path

### **Beginner (Day 1)**
1. Read [Quick Start Guide](./QUICK-START.md)
2. Run `./quick-start.sh`
3. Test all endpoints
4. Explore [README](./README.md)

### **Intermediate (Week 1)**
1. Study [Architecture](./README.md#architecture)
2. Try [Network Access](./README.md#public-access)
3. Read [Operations Guide](./OPERATIONS-GUIDE.md)
4. Customize configurations

### **Advanced (Month 1)**
1. Build custom services
2. Set up [Public Access](./PUBLIC-ACCESS-GUIDE.md)
3. Implement monitoring
4. Production deployment

---

## 🆘 Getting Help

### **Self-Help Resources**
1. **Check Status**: `./status-db-apps.sh`
2. **View Logs**: `tail -f logs/*.log`
3. **Run Diagnostics**: `./fix-db-issues.sh`
4. **Read Documentation**: This index!

### **Documentation Hierarchy**
1. **Quick fixes** → Command reference above
2. **Common issues** → [Troubleshooting](./README.md#troubleshooting)
3. **Detailed operations** → [Operations Guide](./OPERATIONS-GUIDE.md)
4. **Specific problems** → Individual service docs

### **Emergency Contacts**
- **Platform Issues** → [Operations Guide](./OPERATIONS-GUIDE.md)
- **Database Problems** → [Database Management](./DATABASE-MANAGEMENT.md)
- **Network Issues** → [Public Access Guide](./PUBLIC-ACCESS-GUIDE.md)

**🎉 You now have everything you need to master the APM Examples platform!** 🚀
