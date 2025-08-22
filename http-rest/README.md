# HTTP REST Service

This project provides a simple HTTP REST API in Go that:
- Manages a **Books** resource (basic CRUD logic)
- Acts as a **control plane** to trigger operations in other local services:
  - **Database/SQL Service** → insert, update, delete records
  - **Kafka Service** → produce messages
  - **gRPC Service** → call unary and streaming RPC methods

It is designed for local infrastructure testing where multiple services run together.

---

## ⚙️ Prerequisites

You need the following installed:

- **Go** 1.21+ → [Download Go](https://go.dev/dl/)
- Other services running locally:
  - **Database/SQL Service** (PostgreSQL & MySQL setup)
  - **Kafka Service** (broker running locally)
  - **gRPC Service** (running on its assigned port)

Make sure ports match what’s configured in the HTTP REST service.

---

## ▶️ Running the Service

```bash
go run .
````

Expected output:

```
HTTP server started on :8084
```


## 📌 Notes

* No automated tests are included — test manually using curl or Postman.
* The HTTP REST service **expects other services to be running**.
* Endpoints use hardcoded payloads for triggering purposes in local infra setups.

---

## 📜 License

MIT License. See `LICENSE` for details.
