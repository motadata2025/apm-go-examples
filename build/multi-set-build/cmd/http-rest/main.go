package main

import (
	"encoding/json"
	"fmt"
	"log"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"http-rest/internal/types"
)

// Simplified handlers for multi-set build
type BookHandler struct {
	mu   sync.RWMutex
	data map[int64]types.Book
	next int64
}

type TriggerResponse struct {
	Service string `json:"service"`
	Status  string `json:"status"`
}

func NewBookHandler() *BookHandler {
	return &BookHandler{data: make(map[int64]types.Book), next: 1}
}

func (h *BookHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /books", h.create)
	mux.HandleFunc("GET /books", h.list)
	mux.HandleFunc("GET /books/{id}", h.get)
	mux.HandleFunc("PUT /books/{id}", h.update)
	mux.HandleFunc("DELETE /books/{id}", h.delete)

	// Trigger routes - these will use environment-based port discovery
	mux.HandleFunc("/trigger/db", h.triggerDB)
	mux.HandleFunc("/trigger/kafka", h.triggerKafka)
	mux.HandleFunc("/trigger/grpcunary", h.triggerGRPCUnary)
	mux.HandleFunc("/trigger/grpcstream", h.triggerGRPCStream)
	mux.HandleFunc("/trigger/allservices", h.triggerAllServices)
}

func (h *BookHandler) triggerDB(w http.ResponseWriter, r *http.Request) {
	dbPort := getEnvOrDefault("PORT_DB", "8081")
	url := fmt.Sprintf("http://localhost:%s/trigger-crud", dbPort)
	
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("error triggering DB operations: %v", err)
		http.Error(w, "DB trigger failed", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	json.NewEncoder(w).Encode(TriggerResponse{
		Service: "database-sql",
		Status:  resp.Status,
	})
}

func (h *BookHandler) triggerKafka(w http.ResponseWriter, r *http.Request) {
	kafkaPort := getEnvOrDefault("PORT_KAFKA", "8082")
	url := fmt.Sprintf("http://localhost:%s/trigger-produce", kafkaPort)
	
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("error triggering Kafka producer: %v", err)
		http.Error(w, "Kafka trigger failed", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	json.NewEncoder(w).Encode(TriggerResponse{
		Service: "kafka-go",
		Status:  resp.Status,
	})
}

func (h *BookHandler) triggerGRPCUnary(w http.ResponseWriter, r *http.Request) {
	grpcPort := getEnvOrDefault("PORT_GRPC_CLIENT", "8083")
	url := fmt.Sprintf("http://localhost:%s/trigger-simple", grpcPort)
	
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("error triggering gRPC operations: %v", err)
		http.Error(w, "gRPC trigger failed", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	json.NewEncoder(w).Encode(TriggerResponse{
		Service: "grpc-service",
		Status:  resp.Status,
	})
}

func (h *BookHandler) triggerGRPCStream(w http.ResponseWriter, r *http.Request) {
	grpcPort := getEnvOrDefault("PORT_GRPC_CLIENT", "8083")
	url := fmt.Sprintf("http://localhost:%s/trigger-stream", grpcPort)
	
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("error triggering gRPC operations: %v", err)
		http.Error(w, "gRPC trigger failed", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	json.NewEncoder(w).Encode(TriggerResponse{
		Service: "grpc-service",
		Status:  resp.Status,
	})
}

func (h *BookHandler) triggerAllServices(w http.ResponseWriter, r *http.Request) {
	dbPort := getEnvOrDefault("PORT_DB", "8081")
	kafkaPort := getEnvOrDefault("PORT_KAFKA", "8082")
	grpcPort := getEnvOrDefault("PORT_GRPC_CLIENT", "8083")
	
	services := []struct {
		Name string
		URL  string
	}{
		{"database-sql", fmt.Sprintf("http://localhost:%s/trigger-crud", dbPort)},
		{"kafka-go", fmt.Sprintf("http://localhost:%s/trigger-produce", kafkaPort)},
		{"grpc-unary", fmt.Sprintf("http://localhost:%s/trigger-simple", grpcPort)},
		{"grpc-stream", fmt.Sprintf("http://localhost:%s/trigger-stream", grpcPort)},
		{"http-rest", "https://jsonplaceholder.typicode.com/posts"},
	}

	var results []TriggerResponse

	for _, s := range services {
		resp, err := http.Get(s.URL)
		if err != nil {
			log.Printf("error triggering %s: %v", s.Name, err)
			results = append(results, TriggerResponse{
				Service: s.Name,
				Status:  "FAILED",
			})
			continue
		}
		defer resp.Body.Close()

		results = append(results, TriggerResponse{
			Service: s.Name,
			Status:  resp.Status,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

// Book CRUD operations (simplified)
func (h *BookHandler) create(w http.ResponseWriter, r *http.Request) {
	var in struct{ Title, Author string }
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "bad json", 400)
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	id := h.next
	h.next++
	b := types.Book{ID: id, Title: in.Title, Author: in.Author, Added: time.Now().UTC()}
	h.data[id] = b
	writeJSON(w, 201, b)
}

func (h *BookHandler) list(w http.ResponseWriter, r *http.Request) {
	author := r.URL.Query().Get("author")
	q := strings.ToLower(r.URL.Query().Get("q"))
	h.mu.RLock()
	defer h.mu.RUnlock()
	out := make([]types.Book, 0, len(h.data))
	for _, b := range h.data {
		if author != "" && b.Author != author {
			continue
		}
		if q != "" && !strings.Contains(strings.ToLower(b.Title), q) {
			continue
		}
		out = append(out, b)
	}
	writeJSON(w, 200, out)
}

func (h *BookHandler) get(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(r.PathValue("id"), 10, 64)
	h.mu.RLock()
	defer h.mu.RUnlock()
	b, ok := h.data[id]
	if !ok {
		http.NotFound(w, r)
		return
	}
	writeJSON(w, 200, b)
}

func (h *BookHandler) update(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(r.PathValue("id"), 10, 64)
	var in struct{ Title, Author string }
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "bad json", 400)
		return
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	b, ok := h.data[id]
	if !ok {
		http.NotFound(w, r)
		return
	}
	if in.Title != "" {
		b.Title = in.Title
	}
	if in.Author != "" {
		b.Author = in.Author
	}
	h.data[id] = b
	writeJSON(w, 200, b)
}

func (h *BookHandler) delete(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.ParseInt(r.PathValue("id"), 10, 64)
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.data, id)
	writeJSON(w, 204, nil)
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if v != nil {
		_ = json.NewEncoder(w).Encode(v)
	} else {
		_, _ = fmt.Fprint(w, "{}")
	}
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mux := http.NewServeMux()

	books := NewBookHandler()
	books.Register(mux)

	// Get port from environment or use default
	port := getEnvOrDefault("PORT_HTTP", "8084")
	addr := "0.0.0.0:" + port

	logger.Info("http server", "addr", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		logger.Error("server", "err", err)
	}
}
