# Database Service (db-sql-multi)

[![Go Version](https://img.shields.io/badge/Go-1.24+-blue.svg)](https://golang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue.svg)](https://postgresql.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-orange.svg)](https://mysql.com)

A multi-database service that demonstrates database operations with both PostgreSQL and MySQL, showcasing connection pooling, transaction management, and CRUD operations across different database systems.

## 🎯 **Overview**

This service provides a unified HTTP API for database operations that work with both PostgreSQL and MySQL databases simultaneously. It demonstrates:

- **Multi-database connectivity** with PostgreSQL and MySQL
- **Connection pooling** for optimal performance
- **Transaction management** across different database systems
- **CRUD operations** with proper error handling
- **Health checks** for database connectivity
- **Structured logging** for observability

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Client   │    │  Database API   │    │   PostgreSQL    │
│                 │◄──►│   (Port 8081)   │◄──►│   (Port 5432)   │
│                 │    │                 │    │                 │
└─────────────────┘    │                 │    └─────────────────┘
                       │                 │    ┌─────────────────┐
                       │                 │◄──►│     MySQL       │
                       │                 │    │   (Port 3306)   │
                       └─────────────────┘    └─────────────────┘
```

## 🚀 **Quick Start**

### Prerequisites

- **Go 1.24+**
- **PostgreSQL 15+** or Docker
- **MySQL 8.0+** or Docker
- **Make** (for build automation)

### Installation

```bash
# Clone and navigate to the service
cd db-sql-multi

# Copy environment configuration
cp .env.example .env

# Edit configuration as needed
nano .env

# Build the service
make build

# Start databases (if using Docker)
docker run --name postgres -e POSTGRES_USER=testuser -e POSTGRES_PASSWORD=Test@1234 -e POSTGRES_DB=testdb -p 5432:5432 -d postgres:15
docker run --name mysql -e MYSQL_ROOT_PASSWORD=rootpass -e MYSQL_DATABASE=testdb -p 3306:3306 -d mysql:8

# Run the service
make run
```

### Quick Test

```bash
# Check service health
curl http://localhost:8081/health

# Trigger CRUD operations
curl http://localhost:8081/trigger-crud

# Check specific database operations
curl http://localhost:8081/postgres/users
curl http://localhost:8081/mysql/products
```

## 📖 **API Reference**

### Health Check

```http
GET /health
```

Returns the health status of the service and database connections.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "databases": {
    "postgresql": "connected",
    "mysql": "connected"
  }
}
```

### CRUD Operations

#### Trigger All CRUD Operations
```http
POST /trigger-crud
```

Executes a series of CRUD operations on both databases for demonstration.

#### PostgreSQL Operations

```http
GET    /postgres/users          # List all users
POST   /postgres/users          # Create user
GET    /postgres/users/{id}     # Get user by ID
PUT    /postgres/users/{id}     # Update user
DELETE /postgres/users/{id}     # Delete user
```

#### MySQL Operations

```http
GET    /mysql/products          # List all products
POST   /mysql/products          # Create product
GET    /mysql/products/{id}     # Get product by ID
PUT    /mysql/products/{id}     # Update product
DELETE /mysql/products/{id}     # Delete product
```

### Example Requests

**Create User (PostgreSQL):**
```bash
curl -X POST http://localhost:8081/postgres/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

**Create Product (MySQL):**
```bash
curl -X POST http://localhost:8081/mysql/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"category":"Electronics"}'
```

## ⚙️ **Configuration**

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `HTTP_HOST` | HTTP server host | `0.0.0.0` | No |
| `HTTP_PORT` | HTTP server port | `8081` | No |
| `PG_HOST` | PostgreSQL host | `127.0.0.1` | Yes |
| `PG_PORT` | PostgreSQL port | `5432` | No |
| `PG_USER` | PostgreSQL username | `testuser` | Yes |
| `PG_PASSWORD` | PostgreSQL password | `Test@1234` | Yes |
| `PG_DATABASE` | PostgreSQL database | `testdb` | Yes |
| `PG_SSLMODE` | PostgreSQL SSL mode | `disable` | No |
| `MYSQL_HOST` | MySQL host | `127.0.0.1` | Yes |
| `MYSQL_PORT` | MySQL port | `3306` | No |
| `MYSQL_USER` | MySQL username | `root` | Yes |
| `MYSQL_PASSWORD` | MySQL password | `rootpass` | Yes |
| `MYSQL_DATABASE` | MySQL database | `testdb` | Yes |
| `LOG_LEVEL` | Logging level | `INFO` | No |
├── internal/
│   ├── db/               # Database connection & CRUD logic
│   ├── handlers/         # HTTP handlers to trigger DB operations
│   └── models/           # Struct definitions
└── go.mod

````

---

## ⚙️ Prerequisites

You need the following installed on your Ubuntu machine:

- **Go** 1.21+ → [Download Go](https://go.dev/dl/)
- **PostgreSQL** (server running locally or remotely)
- **MySQL** (server running locally or remotely)
- **Go database drivers** (already in `go.mod`):
  - PostgreSQL: [`github.com/lib/pq`](https://pkg.go.dev/github.com/lib/pq)
  - MySQL: [`github.com/go-sql-driver/mysql`](https://pkg.go.dev/github.com/go-sql-driver/mysql)
- **cURL** or Postman for hitting trigger endpoints

---

## 🔧 Setup
## Database Configuration

This project demonstrates working with **two databases simultaneously**: MySQL and PostgreSQL.  
Both connections are configured in `config.go` and can be overridden via environment variables.

---

### 1. MySQL Setup

**Default DSN:**
```

root\:rootpass\@tcp(127.0.0.1:3306)/testdb?parseTime=true

````

**Steps:**

1. Start MySQL server (ensure it is running on port `3306`).
   ```bash
   sudo systemctl start mysql
````

or using Docker:

```bash
docker run --name mysql -e MYSQL_ROOT_PASSWORD=rootpass -p 3306:3306 -d mysql:8
```

2. Create the database:

   ```bash
   mysql -u root -p
   ```

   Then inside MySQL shell:

   ```sql
   CREATE DATABASE testdb;
   ```

3. Verify connection:

   ```bash
   mysql -u root -p -h 127.0.0.1 -P 3306 testdb
   ```

4. (Optional) Override DSN:

   ```bash
   export MYSQL_DSN="user:password@tcp(localhost:3306)/testdb?parseTime=true"
   ```

---

### 2. PostgreSQL Setup

**Default DSN:**

```
postgres://testuser:Test@1234@127.0.0.1:5432/testdb?sslmode=disable
```

**Steps:**

1. Start PostgreSQL server (ensure it is running on port `5432`).

   ```bash
   sudo systemctl start postgresql
   ```

   or using Docker:

   ```bash
   docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:15
   ```

2. Create database and user:

   ```bash
   sudo -i -u postgres psql
   ```

   Inside `psql`:

   ```sql
   CREATE DATABASE testdb;
   CREATE USER testuser WITH PASSWORD 'Test@1234';
   GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
   ```

3. Verify connection:

   ```bash
   PGPASSWORD='Test@1234' psql -U testuser -h 127.0.0.1 -p 5432 -d testdb
   ```

4. (Optional) Override DSN:

   ```bash
   export PG_DSN="postgres://testuser:Test@1234@127.0.0.1:5432/testdb?sslmode=disable"
   ```

---

### 3. Connection Pooling Parameters

Both MySQL and PostgreSQL connections support tuning via environment variables:

| Variable         | Default | Description                        |
| ---------------- | ------- | ---------------------------------- |
| `MYSQL_MAX_OPEN` | `10`    | Max open connections to MySQL      |
| `MYSQL_MAX_IDLE` | `5`     | Max idle connections to MySQL      |
| `PG_MAX_OPEN`    | `10`    | Max open connections to PostgreSQL |
| `PG_MAX_IDLE`    | `5`     | Max idle connections to PostgreSQL |

Connection lifetime is fixed at **30 minutes**.

---

### 4. Running the App

Ensure both databases are running and accessible, then start the application:

```bash
go run cmd/app/main.go
```

You should see logs confirming connections to both MySQL and PostgreSQL.

```

---

## ▶️ Running the Project

Start the service:

```bash
go run ./cmd
```

If successful, you’ll see:

```
Connected to PostgreSQL successfully!
Connected to MySQL successfully!
HTTP server started on :8081
```

## 🧪 Testing

> **Note:** This project **does not** have automated test cases.
> Testing is done manually via the HTTP endpoints above.

---

## 📌 Notes

* This service is intended for **local infrastructure demos** where other services (e.g., HTTP REST gateway) can trigger DB operations.
* PostgreSQL and MySQL are both active; all operations run on both in parallel.
* For production:
  * Use environment-specific configs
  * Add proper error handling and connection pooling
  * Consider transaction management

