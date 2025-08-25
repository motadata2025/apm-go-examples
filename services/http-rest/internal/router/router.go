package router

import (
	"net/http"
)

func New(mux *http.ServeMux, h http.Handler) http.Handler {
	// Attach basic middleware stack
	return loggingMiddleware(recoverMiddleware(h))
}

func recoverMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				http.Error(w, "internal", http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// tiny request log
		next.ServeHTTP(w, r)
	})
}
