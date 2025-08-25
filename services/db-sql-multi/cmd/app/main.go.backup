package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"db-sql-multi/internal/config"
	"db-sql-multi/internal/db"
	"db-sql-multi/internal/repo"
	"db-sql-multi/internal/service"
)

type response struct {
	Message string `json:"message"`
	Error   string `json:"error,omitempty"`
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	cfg := config.Load()

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pair, err := db.Open(cfg, logger)
	if err != nil {
		logger.Error("open dbs", "err", err)
		os.Exit(1)
	}
	defer pair.My.Close()
	defer pair.Pg.Close()

	svc := service.DualService{
		My:  repo.MySQLUserRepo{DB: pair.My},
		Pg:  repo.PGUserRepo{DB: pair.Pg},
		Log: logger,
	}

	if err := svc.Bootstrap(ctx); err != nil {
		logger.Error("bootstrap", "err", err)
		os.Exit(1)
	}
	// if err := svc.Demo(ctx); err != nil {
	// 	logger.Error("demo", "err", err)
	// 	os.Exit(1)
	// }

	// HTTP Handler for /trigger-crud
	http.HandleFunc("/trigger-crud", func(w http.ResponseWriter, r *http.Request) {
		reqCtx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		if err := svc.Demo(reqCtx); err != nil {
			logger.Error("demo failed", "err", err)
			writeJSON(w, http.StatusInternalServerError, response{
				Message: "Database operation failed",
				Error:   err.Error(),
			})
			return
		}

		writeJSON(w, http.StatusOK, response{
			Message: "Database operation completed successfully",
		})
	})

	// HTTP server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}
	addr := "0.0.0.0:" + port
	srv := &http.Server{
		Addr:    addr,
		Handler: http.DefaultServeMux,
	}

	// Graceful shutdown handling
	go func() {
		logger.Info("HTTP server started", "addr", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("server error", "err", err)
			os.Exit(1)
		}
	}()

	// Wait for interrupt signal
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
	logger.Info("done")
}

// writeJSON encodes v to JSON and writes it to w with the given status code
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
