# Kafka Example Project

This project demonstrates how to use Apache Kafka with Go for producing and consuming messages.

It includes:
- A **Kafka producer** that sends messages to a topic
- A **Kafka consumer** that listens for messages on a topic
- HTTP trigger endpoints to send test messages
- Designed for **local infrastructure testing** (no automated test cases)

---

## 📦 Project Structure

```

kafka/
├── cmd/
│   ├── producer/         # Kafka producer logic
│       └── main.go           # Entry point
│   ├── consumer/         # Kafka consumer logic
│       └── main.go           # Entry point
├── internal/
│   ├── config/         
│   ├── kafkautil/         
│   └── model/         
└── go.mod

````

---

## ⚙️ Prerequisites

You need the following installed:

- [Docker](https://docs.docker.com/get-docker/) installed  
- [Go 1.22+](https://go.dev/dl/) installed  
- Make sure you use **Docker Compose v2** (`docker compose`) instead of the old `docker-compose`.

Check with:

```bash
docker compose version
````

---

## 🔧 Setup

## 🐳 Kafka Setup (via Docker Compose)

We use Docker Compose to run **Kafka** and **Zookeeper** locally.
A sample `docker-compose.yml` is already included in this repo.

```yaml
version: "3.8"
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    depends_on:
      - zookeeper
```

Start Kafka:

```bash
docker compose up -d
```

Check running containers:

```bash
docker ps
```

---

## 🚀 Running the Go Services

### 1. Start the **Consumer**

In one terminal:

```bash
go run cmd/consumer/main.go
```

You should see logs waiting for messages.

---

### 2. Start the **Producer**

In another terminal:

```bash
go run cmd/producer/main.go
```

It will start an HTTP server on port `8082`.

---

### 3. Trigger Message Production

Open a new terminal and run:

```bash
curl -X GET http://localhost:8082/trigger-produce
```

This will produce:

* An `OrderCreated` event into topic `orders`
* A `PaymentReceived` event into topic `payments`

---

### 4. Verify Consumer Output

Check the **consumer terminal** — you should see logs like:

```
INFO order key=order-1 amount=1499
INFO payment key=pay-1 order=O-1001
```

---

## 🛑 Stopping

To stop Kafka:

```bash
docker compose down
```

---

## 🔧 Environment Variables (optional)

You can override defaults via `.env` or shell exports:

* `KAFKA_BROKERS` → default: `127.0.0.1:9092`
* `TOPIC_A` → default: `orders`
* `TOPIC_B` → default: `payments`
* `GROUP_ID` → default: `demo-consumers`

Example:

```bash
export KAFKA_BROKERS=localhost:9092
export TOPIC_A=orders
export TOPIC_B=payments
export GROUP_ID=my-consumers
```


---

## 📂 Managing Kafka Topics

### 1. List Existing Topics

After starting Kafka:

```bash
docker exec -it kafka kafka-topics --list \
  --bootstrap-server localhost:9092
````

If you see `orders` and `payments` in the list, they are already created.

---

### 2. Create Topics Manually (if missing)

To create `orders` topic:

```bash
docker exec -it kafka kafka-topics --create \
  --topic orders \
  --partitions 1 \
  --replication-factor 1 \
  --bootstrap-server localhost:9092
```

To create `payments` topic:

```bash
docker exec -it kafka kafka-topics --create \
  --topic payments \
  --partitions 1 \
  --replication-factor 1 \
  --bootstrap-server localhost:9092
```

---

### 3. Describe a Topic

To verify details of a topic:

```bash
docker exec -it kafka kafka-topics --describe \
  --topic orders \
  --bootstrap-server localhost:9092
```

You’ll see info about partitions, replication factor, and leader brokers.

---

### 4. Optional: Disable Auto-Creation of Topics

By default, Kafka may auto-create topics when your producer/consumer writes.
If you want to **disable this behavior** (recommended in production), set this in `docker-compose.yml` under the `kafka` service:

```yaml
environment:
  KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
```

Then, you must **manually create topics** as shown above.

```

---
## 📜 License

MIT License. See `LICENSE` for details.
