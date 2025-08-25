package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"math"
	"math/rand/v2"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"kafka-segmentio/internal/config"
	"kafka-segmentio/internal/kafkautil"
	"kafka-segmentio/internal/model"
)

type response struct {
	Message string `json:"message"`
	Error   string `json:"error,omitempty"`
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	cfg := config.Load()

	wA := kafkautil.NewWriter(cfg.Brokers, cfg.TopicA)
	wB := kafkautil.NewWriter(cfg.Brokers, cfg.TopicB)
	defer wA.Close()
	defer wB.Close()

	// HTTP handler for producing Kafka messages
	http.HandleFunc("/trigger-produce", func(w http.ResponseWriter, r *http.Request) {
		reqCtx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		// generate random values
		orderID := fmt.Sprintf("O-%d", time.Now().UnixNano())
		paymentID := fmt.Sprintf("P-%d", time.Now().UnixNano())
		// generate amount between 100 and 5100, rounded to 2 decimals
		rawAmount := rand.Float64()*5000 + 100
		amount := math.Round(rawAmount*100) / 100

		// Produce messages
		if err := kafkautil.ProduceJSON(reqCtx, wA, logger, orderID, model.OrderCreated{
			OrderID: orderID,
			Amount:  amount,
			Time:    time.Now(),
		}); err != nil {
			logger.Error("produce order message failed", "err", err)
			writeJSON(w, http.StatusInternalServerError, response{
				Message: "Order message production failed",
				Error:   err.Error(),
			})
			return
		}

		if err := kafkautil.ProduceJSON(reqCtx, wB, logger, paymentID, model.PaymentReceived{
			PaymentID: paymentID,
			OrderID:   orderID,
			Amount:    amount,
			Time:      time.Now(),
		}); err != nil {
			logger.Error("produce payment message failed", "err", err)
			writeJSON(w, http.StatusInternalServerError, response{
				Message: "Payment message production failed",
				Error:   err.Error(),
			})
			return
		}

		logger.Info("messages produced successfully")
		writeJSON(w, http.StatusOK, response{
			Message: "Messages produced successfully",
		})
	})

	// Get port from environment or use default
	port := os.Getenv("PORT_KAFKA")
	if port == "" {
		port = "8082"
	}
	addr := "0.0.0.0:" + port

	// HTTP server
	srv := &http.Server{
		Addr:    addr,
		Handler: http.DefaultServeMux,
	}

	// Start server in a goroutine
	go func() {
		logger.Info("HTTP server started", "addr", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("server error", "err", err)
			os.Exit(1)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down server...")

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("server shutdown failed", "err", err)
	} else {
		logger.Info("server exited gracefully")
	}
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
