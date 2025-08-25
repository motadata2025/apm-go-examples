package main

import (
	"log/slog"
	"net/http"
	"os"

	"http-rest/internal/handlers"
	"http-rest/internal/router"
)

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mux := http.NewServeMux()

	books := handlers.NewBookHandler()
	books.Register(mux)

	handler := router.New(mux, mux)
	addr := ":8084"
	logger.Info("http server", "addr", addr)
	if err := http.ListenAndServe(addr, handler); err != nil {
		logger.Error("server", "err", err)
	}
}
