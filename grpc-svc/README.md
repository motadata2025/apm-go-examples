# gRPC Service Example

This project demonstrates a Go-based gRPC service with two types of RPC calls:
- **Unary RPC** → Single request, single response
- **Server Streaming RPC** → Single request, multiple streamed responses

It is intended for **infrastructure and integration testing** with gRPC clients.

---

## 📦 Project Structure

```

grpc-svc/
├── proto/               # Protobuf definitions
│   └── service.proto
├── server/              # gRPC server implementation
│   ├── handlers.go      # RPC method handlers
│   └── server.go        # Server setup & start
├── client/              # Example gRPC client logic
└── go.mod

````

---

## ⚙️ Prerequisites

You need the following installed:

- **Go** 1.21+ → [Download Go](https://go.dev/dl/)
- **Protocol Buffers Compiler** (`protoc`) → [Installation Guide](https://grpc.io/docs/protoc-installation/)
- **Go gRPC plugins**:
  ```bash
  go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
````

Make sure `$GOPATH/bin` is in your `PATH`.

---

## 🛠 Generating gRPC Code

After updating `.proto` files:

```bash
protoc --go_out=. --go-grpc_out=. proto/service.proto
```

---

## ▶️ Running the Service

Start the gRPC server:

```bash
go run ./server
```

Expected output:

```
gRPC server started on :50051
```

---

## 📚 RPC Methods

| RPC Name          | Type             | Description                                 |
| ----------------- | ---------------- | ------------------------------------------- |
| `GetBook`         | Unary            | Returns book details for a given ID         |
| `ListBooksStream` | Server Streaming | Streams multiple book entries to the client |

---

## 🧪 Testing the Service

### 1. Using gRPCurl (recommended)

**Unary RPC:**

```bash
grpcurl -plaintext -d '{"id": "123"}' localhost:50051 proto.BookService/GetBook
```

**Streaming RPC:**

```bash
grpcurl -plaintext -d '{"category": "fiction"}' localhost:50051 proto.BookService/ListBooksStream
```

### 2. Using Example Client

```bash
go run ./client
```

This client calls both the unary and streaming methods.

---

## 📌 Notes

* **No automated tests** are provided — testing is manual using gRPCurl or the sample client.
* Ensure you regenerate `.pb.go` files after modifying `.proto` definitions.
* The service can be extended with authentication, interceptors, and logging for production.

---

## 📜 License

MIT License. See `LICENSE` for details.
