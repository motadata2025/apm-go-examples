# 🚀 APM Examples - Zero-Config Quick Start

**Get everything running in 2 commands. No configuration needed!**

## ⚡ Super Quick Start

```bash
# 1. Clone and enter
git clone <your-repo> && cd apm-examples

# 2. Run the magic script
./quick-start.sh
```

**That's it!** 🎉

## 🎯 What You Get

### Infrastructure (Docker)
- **PostgreSQL**: `localhost:5432` (testuser/Test@1234/testdb)
- **MySQL**: `localhost:3306` (testuser/Test@1234/testdb)  
- **Kafka**: `localhost:9092` (topics: orders, payments)
- **Adminer**: `http://localhost:8080` (database admin)

### Your Go Apps (Native)
- **Database Service**: `http://localhost:8001/trigger-crud`
- **Kafka Producer**: `http://localhost:8002/trigger-produce`
- **gRPC Client**: `http://localhost:8003/trigger-simple`
- **HTTP REST**: `http://localhost:8004/trigger/allservices`

## 🧪 Test Everything Works

```bash
# Test all services at once
curl http://localhost:8004/trigger/allservices

# Test individual services
curl http://localhost:8001/trigger-crud      # Database
curl http://localhost:8002/trigger-produce   # Kafka
curl http://localhost:8003/trigger-simple    # gRPC
```

## 🔧 Management Commands

```bash
# View infrastructure logs
docker compose -f docker-compose.minimal.yml logs -f

# Stop infrastructure
docker compose -f docker-compose.minimal.yml stop

# Stop and remove everything
docker compose -f docker-compose.minimal.yml down

# Restart infrastructure
docker compose -f docker-compose.minimal.yml restart
```

## 🚨 Port Conflicts?

If you get port conflicts, run:

```bash
# Check what's using the ports
sudo lsof -i :3306 -i :5432 -i :9092 -i :2181

# Kill conflicting processes
sudo lsof -ti:3306 | xargs sudo kill -9
sudo lsof -ti:5432 | xargs sudo kill -9
sudo lsof -ti:9092 | xargs sudo kill -9

# Then run quick-start again
./quick-start.sh
```

## 🎛️ Alternative: Multi-Set Build System

For advanced scenarios with multiple port sets:

```bash
cd multi-set-build

# Build all variants
make all

# Run set 800 (ports 8001-8005)
make run-800

# Run set 801 (ports 8011-8015)  
make run-801

# Test endpoints
make test-800
```

## 📁 What's Running Where

| Service | Port | Purpose | Status |
|---------|------|---------|---------|
| PostgreSQL | 5432 | Database | 🐳 Docker |
| MySQL | 3306 | Database | 🐳 Docker |
| Kafka | 9092 | Message Queue | 🐳 Docker |
| ZooKeeper | 2181 | Kafka Coordinator | 🐳 Docker |
| Adminer | 8080 | DB Admin UI | 🐳 Docker |
| DB Service | 8001 | Go App | 🖥️ Native |
| Kafka Producer | 8002 | Go App | 🖥️ Native |
| gRPC Client | 8003 | Go App | 🖥️ Native |
| HTTP REST | 8004 | Go App | 🖥️ Native |

## 🎯 Design Philosophy

- **Infrastructure in Docker**: Databases, message queues (consistent across environments)
- **Applications Native**: Your Go code runs on the host (fast development)
- **Zero Configuration**: Works out of the box, no setup needed
- **Port Conflict Detection**: Automatically checks and warns about conflicts
- **Health Checks**: Waits for services to be ready before proceeding

## 🆘 Troubleshooting

### Services won't start?
```bash
# Check Docker is running
docker ps

# Check port availability
netstat -tulpn | grep -E ':(3306|5432|9092|2181)'

# Restart Docker
sudo systemctl restart docker
```

### Go apps won't build?
```bash
# Update dependencies
go mod tidy

# Clean and rebuild
make clean && make build
```

### Can't connect to databases?
```bash
# Test PostgreSQL
psql -h localhost -U testuser -d testdb

# Test MySQL  
mysql -h localhost -u testuser -p testdb

# Check containers
docker compose -f docker-compose.minimal.yml ps
```

---

**Made with ❤️ for developers who just want things to work!**
