# Multi-Set Build System for APM Examples

This directory contains a sophisticated build system that organizes Go services into **port-based sets** with **multiple compilation variants**.

## Overview

The system creates deterministic port mappings using a base number system:
- **Port Math**: Base `N` → ports `N*10+1` through `N*10+4` for the 4 main services
- **Sets**: `build-800`, `static-801`, `race-802`, `xcompile-803`
- **Port Injection**: Uses environment variables and `-ldflags -X` to override hardcoded ports
- **Background Execution**: Scripts to run entire sets with proper logging and PID management

## Quick Start

```bash
# Build all sets
make all

# Build specific set
make build-800

# Run set 800 in background
make run-800

# Check status
./scripts/check_status.sh build-800

# Stop set 800
make stop-800

# Clean everything
make clean
```

## Port Mapping

| Set | Base | DB | Kafka | gRPC Client | HTTP | gRPC Server |
|-----|------|----|----|-------------|------|-------------|
| build-800 | 800 | 8001 | 8002 | 8003 | 8004 | 8005 |
| static-801 | 801 | 8011 | 8012 | 8013 | 8014 | 8015 |
| race-802 | 802 | 8021 | 8022 | 8023 | 8024 | 8025 |
| xcompile-803 | 803 | 8031 | 8032 | 8033 | 8034 | 8035 |

## Service Endpoints

For each set, the following endpoints are available:

### Database Service (Port: Base*10+1)
- `GET /trigger-crud` - Trigger database operations

### Kafka Producer (Port: Base*10+2)
- `GET /trigger-produce` - Trigger message production

### gRPC Client (Port: Base*10+3)
- `GET /trigger-simple` - Trigger unary gRPC call
- `GET /trigger-stream` - Trigger streaming gRPC call

### HTTP REST (Port: Base*10+4)
- `GET /trigger/db` - Trigger database service
- `GET /trigger/kafka` - Trigger kafka producer
- `GET /trigger/grpcunary` - Trigger gRPC unary
- `GET /trigger/grpcstream` - Trigger gRPC stream
- `GET /trigger/allservices` - Trigger all services

## Compilation Variants

- **build-800**: Standard build + includes grpc-server and kafka-consumer
- **static-801**: Static linking (`CGO_ENABLED=0`, `-ldflags="-s -w"`)
- **race-802**: Race detection (`-race`)
- **xcompile-803**: Cross-compilation for multiple platforms

## Testing Commands

### Set 800 (ports 8001-8004, gRPC server: 8005)
```bash
curl http://localhost:8001/trigger-crud
curl http://localhost:8002/trigger-produce
curl http://localhost:8003/trigger-simple
curl http://localhost:8003/trigger-stream
curl http://localhost:8004/trigger/allservices
```

### Set 801 (ports 8011-8014, gRPC server: 8015)
```bash
curl http://localhost:8011/trigger-crud
curl http://localhost:8012/trigger-produce
curl http://localhost:8013/trigger-simple
curl http://localhost:8013/trigger-stream
curl http://localhost:8014/trigger/allservices
```

### Set 802 (ports 8021-8024, gRPC server: 8025)
```bash
curl http://localhost:8021/trigger-crud
curl http://localhost:8022/trigger-produce
curl http://localhost:8023/trigger-simple
curl http://localhost:8024/trigger/allservices
```

## Live Demo

The system is currently running with set 800 active. You can test it immediately:

```bash
# Test all services via HTTP REST aggregator
curl http://localhost:8004/trigger/allservices

# Test individual services
curl http://localhost:8001/trigger-crud      # Database operations
curl http://localhost:8002/trigger-produce   # Kafka message production
curl http://localhost:8003/trigger-simple    # gRPC unary call
curl http://localhost:8003/trigger-stream    # gRPC streaming call
```

## Directory Structure

```
multi-set-build/
├── Makefile
├── scripts/
│   ├── build_sets.sh
│   ├── run_set_bg.sh
│   ├── stop_set.sh
│   └── check_status.sh
├── internal/
│   └── config/
│       └── ports.go
├── build-800/
│   ├── bin/
│   ├── logs/
│   └── env/
├── static-801/
│   ├── bin/
│   ├── logs/
│   └── env/
├── race-802/
│   ├── bin/
│   ├── logs/
│   └── env/
├── xcompile-803/
│   ├── bin/
│   ├── logs/
│   └── env/
└── README.md
```

## Prerequisites

- Go 1.21+
- Running Kafka/ZooKeeper (for kafka services)
- Running MySQL/PostgreSQL (for database service)
- `grpcurl` (optional, for gRPC testing)

## Troubleshooting

### Ports in Use
If ports are already in use, you can override them:
```bash
PORT_DB=9001 PORT_KAFKA=9002 PORT_GRPC_CLIENT=9003 PORT_HTTP=9004 make run-800
```

### Service Dependencies
Make sure infrastructure is running:
```bash
# From main project directory
make infra-up
```

### Logs
Check service logs:
```bash
tail -f build-800/logs/*.log
```
