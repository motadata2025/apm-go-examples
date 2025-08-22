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

	cc, err := grpc.Dial("127.0.0.1:50051", grpc.WithInsecure())
	if err != nil {
		log.Fatal(err)
	}
	defer cc.Close()

	client := proto.NewEchoServiceClient(cc)
	// ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	// defer cancel()

	// // Unary
	// resp, err := c.Say(ctx, &proto.SayRequest{Msg: "hello"})
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// fmt.Println("Unary:", resp.GetMsg())

	// // Server streaming
	// stream, err := c.StreamCount(context.Background(), &proto.CountRequest{From: 3, To: 7})
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// for {
	// 	tick, err := stream.Recv()
	// 	if err != nil {
	// 		break
	// 	}
	// 	fmt.Println("Tick:", tick.GetValue())
	// }

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

	// HTTP server setup
	srv := &http.Server{
		Addr:    "0.0.0.0:8083",
		Handler: http.DefaultServeMux,
	}

	// Start server
	go func() {
		logger.Info("HTTP server started", "addr", srv.Addr)
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
