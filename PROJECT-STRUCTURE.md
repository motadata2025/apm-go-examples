# 📁 Project Structure - APM Examples

**Expert-level folder organization for professional microservices development.**

## 🏗️ Directory Structure

```
apm-examples/
├── 📚 docs/                           # Documentation
│   ├── DATABASE-MANAGEMENT.md         # Database operations guide
│   ├── OPERATIONS-GUIDE.md            # Daily operations manual
│   ├── PUBLIC-ACCESS-GUIDE.md         # Network access guide
│   ├── DOCUMENTATION-INDEX.md         # Navigation hub
│   └── FINAL-SUMMARY.md               # Achievement summary
│
├── 🚀 services/                       # Microservices
│   ├── db-sql-multi/                  # Database service
│   ├── grpc-svc/                      # gRPC service
│   ├── http-rest/                     # HTTP REST API
│   └── kafka-segmentio/               # Kafka services
│
├── 🛠️ scripts/                        # Automation scripts
│   ├── setup/                         # Initial setup scripts
│   │   ├── quick-start.sh             # Zero-config setup
│   │   ├── setup-machine-ip-access.sh # Network access setup
│   │   ├── setup-public-access.sh     # Public access setup
│   │   └── setup-public-endpoints.sh  # Endpoint configuration
│   │
│   ├── management/                    # Service management
│   │   ├── start-db-apps.sh           # Start applications
│   │   ├── stop-db-apps.sh            # Stop applications
│   │   ├── restart-db-apps.sh         # Restart applications
│   │   ├── status-db-apps.sh          # Check status
│   │   ├── start-machine-ip-apps.sh   # Network access start
│   │   ├── stop-machine-ip-apps.sh    # Network access stop
│   │   ├── status-machine-ip-apps.sh  # Network status
│   │   ├── test-machine-ip-apps.sh    # Network testing
│   │   ├── start-public-apps.sh       # Public access start
│   │   ├── stop-public-apps.sh        # Public access stop
│   │   ├── status-public-apps.sh      # Public status
│   │   ├── test-public-apps.sh        # Public testing
│   │   ├── start-public-services.sh   # Public services start
│   │   ├── stop-public-services.sh    # Public services stop
│   │   ├── status-public-services.sh  # Public services status
│   │   └── test-public-endpoints.sh   # Endpoint testing
│   │
│   └── database/                      # Database initialization
│       ├── postgres-init.sql          # PostgreSQL setup
│       ├── mysql-init.sql             # MySQL setup
│       ├── setup.sh                   # Database setup
│       └── verify-setup.sh            # Setup verification
│
├── 🔧 tools/                          # Development tools
│   ├── monitoring/                    # Monitoring & diagnostics
│   │   ├── fix-db-issues.sh           # Comprehensive issue fixer
│   │   ├── fix-ports.sh               # Port conflict resolver
│   │   └── check-services.sh          # Service health checker
│   │
│   └── security/                      # Security tools
│       └── secure-public-services.sh  # Security hardening
│
├── 🏗️ infrastructure/                 # Infrastructure as Code
│   ├── docker-compose.minimal.yml     # Minimal infrastructure
│   ├── docker-compose.public.yml      # Public access infrastructure
│   └── docker-compose.yml             # Full infrastructure
│
├── 📊 runtime/                        # Runtime data
│   └── logs/                          # Application logs
│       ├── *.log                      # Service logs
│       ├── *.pid                      # Process IDs
│       └── *.port                     # Port assignments
│
├── 🔨 build/                          # Build system
│   ├── multi-set-build/               # Multi-target builds
│   └── internal/                      # Shared build components
│
├── 📋 Root Files
│   ├── README.md                      # Main documentation
│   ├── QUICK-START.md                 # Getting started guide
│   ├── PROJECT-STRUCTURE.md           # This file
│   ├── Makefile                       # Build automation
│   ├── LICENSE                        # License information
│   └── .gitignore                     # Git ignore rules
```

## 🎯 Directory Purposes

### **📚 docs/**
**Purpose**: All documentation files  
**Contents**: User guides, operations manuals, API documentation  
**Access**: Read-only reference materials

### **🚀 services/**
**Purpose**: Individual microservices  
**Contents**: Go applications with their own build systems  
**Structure**: Each service has `cmd/`, `internal/`, `Dockerfile`, `Makefile`

### **🛠️ scripts/**
**Purpose**: Automation and management scripts  
**Structure**:
- `setup/` - Initial configuration and setup
- `management/` - Daily operations and service management
- `database/` - Database initialization and management

### **🔧 tools/**
**Purpose**: Development and operational tools  
**Structure**:
- `monitoring/` - Health checks, diagnostics, issue resolution
- `security/` - Security hardening and access control

### **🏗️ infrastructure/**
**Purpose**: Infrastructure as Code definitions  
**Contents**: Docker Compose files for different environments

### **📊 runtime/**
**Purpose**: Runtime data and logs  
**Contents**: Application logs, process IDs, port assignments  
**Note**: Excluded from git, created at runtime

### **🔨 build/**
**Purpose**: Build system and shared components  
**Contents**: Multi-target builds, shared internal packages

## 🚀 Quick Access Commands

### **Setup & Start**
```bash
# Initial setup
./scripts/setup/quick-start.sh

# Network access setup
./scripts/setup/setup-machine-ip-access.sh
```

### **Daily Management**
```bash
# Start applications
./scripts/management/start-db-apps.sh

# Check status
./scripts/management/status-db-apps.sh

# Stop applications
./scripts/management/stop-db-apps.sh
```

### **Troubleshooting**
```bash
# Fix all issues
./tools/monitoring/fix-db-issues.sh

# Check service health
./tools/monitoring/check-services.sh
```

### **Documentation**
```bash
# Main documentation
cat README.md

# Operations guide
cat docs/OPERATIONS-GUIDE.md

# Documentation index
cat docs/DOCUMENTATION-INDEX.md
```

## 🎯 Benefits of This Structure

### **🏢 Professional Organization**
- **Clear separation** of concerns
- **Logical grouping** of related files
- **Scalable structure** for team development
- **Industry standard** layout

### **🔍 Easy Navigation**
- **Intuitive folder names** with clear purposes
- **Consistent organization** across all areas
- **Quick access** to commonly used files
- **Self-documenting** structure

### **🛠️ Operational Excellence**
- **Centralized scripts** for easy management
- **Organized documentation** for quick reference
- **Separated concerns** for better maintenance
- **Version control friendly** structure

### **🚀 Development Efficiency**
- **Fast onboarding** for new developers
- **Clear file locations** reduce search time
- **Consistent patterns** across services
- **Automated workflows** with organized scripts

## 📋 File Naming Conventions

### **Scripts**
- `start-*.sh` - Service startup scripts
- `stop-*.sh` - Service shutdown scripts
- `status-*.sh` - Status checking scripts
- `test-*.sh` - Testing and validation scripts
- `setup-*.sh` - Initial configuration scripts
- `fix-*.sh` - Problem resolution scripts

### **Documentation**
- `*.md` - Markdown documentation files
- `*-GUIDE.md` - Comprehensive guides
- `*-INDEX.md` - Navigation and reference
- `README.md` - Primary documentation

### **Configuration**
- `docker-compose.*.yml` - Environment-specific Docker configs
- `Makefile` - Build automation
- `*.sql` - Database initialization scripts

## 🎉 Conclusion

This expert-level folder structure provides:
- **Professional organization** for enterprise development
- **Clear separation** of concerns and responsibilities
- **Scalable architecture** for team collaboration
- **Operational excellence** with organized tooling
- **Developer efficiency** with intuitive navigation

**Your project now follows industry best practices for microservices development!** 🚀
