package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"http-rest/internal/types"
)

type BookHandler struct {
	mu   sync.RWMutex
	data map[int64]types.Book
	next int64
}

func NewBookHandler() *BookHandler {
	return &BookHandler{data: make(map[int64]types.Book), next: 1}
}

func (h *BookHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /books", h.create)
	mux.HandleFunc("GET /books", h.list)     // supports ?author= and ?q=
	mux.HandleFunc("GET /books/{id}", h.get) // path param
	mux.HandleFunc("PUT /books/{id}", h.update)
	mux.HandleFunc("DELETE /books/{id}", h.delete)

	// NEW Trigger routes
	mux.HandleFunc("/trigger/db", TriggerDBOperations)
	mux.HandleFunc("/trigger/kafka", TriggerKafkaProducer)
	mux.HandleFunc("/trigger/grpcunary", TriggerGRPCUnaryOperation)
	mux.HandleFunc("/trigger/grpcstream", TriggerGRPCStreamOperation)
	mux.HandleFunc("/trigger/allservices", TriggerAllServices)
}

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
