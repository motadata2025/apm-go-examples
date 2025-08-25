package handlers

import (
	"encoding/json"
	"log"
	"net/http"
)

type TriggerResponse struct {
	Service string `json:"service"`
	Status  string `json:"status"`
}

func TriggerDBOperations(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get("http://localhost:8081/trigger-crud") // DB project endpoint
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

func TriggerKafkaProducer(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get("http://localhost:8082/trigger-produce") // Kafka project endpoint
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

func TriggerGRPCUnaryOperation(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get("http://localhost:8083/trigger-simple") // gRPC trigger endpoint
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

func TriggerGRPCStreamOperation(w http.ResponseWriter, r *http.Request) {
	resp, err := http.Get("http://localhost:8083/trigger-stream") // gRPC trigger endpoint
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

func TriggerAllServices(w http.ResponseWriter, r *http.Request) {
	services := []struct {
		Name string
		URL  string
	}{
		{"database-sql", "http://localhost:8081/trigger-crud"},
		{"kafka-go", "http://localhost:8082/trigger-produce"},
		{"grpc-unary", "http://localhost:8083/trigger-simple"},
		{"grpc-stream", "http://localhost:8083/trigger-stream"},
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

	// Return all results as JSON array
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}
