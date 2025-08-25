package main

import (
	"context"
	"encoding/json"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"grpc-svc/grpc-svc/api/proto"

	"google.golang.org/grpc"
)

type sayResponse struct {
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
}

type countResponse struct {
	Values []int32 `json:"values,omitempty"`
	Error  string  `json:"error,omitempty"`
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))

	// Get gRPC server address from environment or use default
	grpcAddr := os.Getenv("GRPC_SERVER_ADDR")
	if grpcAddr == "" {
		grpcAddr = "127.0.0.1:50051"
	}

	cc, err := grpc.Dial(grpcAddr, grpc.WithInsecure())
	if err != nil {
		log.Fatal(err)
	}
	defer cc.Close()

	client := proto.NewEchoServiceClient(cc)

	// Unary endpoint
	http.HandleFunc("/trigger-simple", func(w http.ResponseWriter, r *http.Request) {
		reqCtx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		resp, err := client.Say(reqCtx, &proto.SayRequest{Msg: "hello"})
		if err != nil {
			logger.Error("unary call failed", "err", err)
			writeJSON(w, http.StatusInternalServerError, sayResponse{
				Error: err.Error(),
			})
			return
		}

		logger.Info("unary call success", "msg", resp.GetMsg())
		writeJSON(w, http.StatusOK, sayResponse{
			Message: resp.GetMsg(),
		})
	})

	// Server streaming endpoint
	http.HandleFunc("/trigger-stream", func(w http.ResponseWriter, r *http.Request) {
		reqCtx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		stream, err := client.StreamCount(reqCtx, &proto.CountRequest{From: 3, To: 7})
		if err != nil {
			logger.Error("streaming call failed", "err", err)
			writeJSON(w, http.StatusInternalServerError, countResponse{
				Error: err.Error(),
			})
			return
		}

		var values []int32
		for {
			tick, err := stream.Recv()
			if err != nil {
				break
			}
			values = append(values, tick.GetValue())
		}

		logger.Info("streaming call success", "count", len(values))
		writeJSON(w, http.StatusOK, countResponse{
			Values: values,
		})
	})

	// Get port from environment or use default
	port := os.Getenv("PORT_GRPC_CLIENT")
	if port == "" {
		port = "8083"
	}
	addr := "0.0.0.0:" + port

	// HTTP server setup
	srv := &http.Server{
		Addr:    addr,
		Handler: http.DefaultServeMux,
	}

	// Start server
	go func() {
		logger.Info("HTTP server started", "addr", srv.Addr, "grpc_server", grpcAddr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("server error", "err", err)
			os.Exit(1)
		}
	}()

	// Wait for shutdown signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down server...")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("server shutdown failed", "err", err)
	} else {
		logger.Info("server exited gracefully")
	}
}

// Helper to write JSON responses
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
