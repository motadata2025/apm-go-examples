package config

import (
	"os"
	"strconv"
)

// Port configuration with environment variable overrides
var (
	// Default ports (can be overridden via ldflags or env vars)
	DefaultDBPort     = "8081"
	DefaultKafkaPort  = "8082"
	DefaultGRPCPort   = "8083"
	DefaultHTTPPort   = "8084"
	DefaultGRPCServer = "127.0.0.1:50051"
)

// PortConfig holds all port configurations for a service set
type PortConfig struct {
	DBPort     string
	KafkaPort  string
	GRPCPort   string
	HTTPPort   string
	GRPCServer string
}

// GetPorts returns port configuration with environment variable overrides
func GetPorts() PortConfig {
	return PortConfig{
		DBPort:     getEnvOrDefault("PORT_DB", DefaultDBPort),
		KafkaPort:  getEnvOrDefault("PORT_KAFKA", DefaultKafkaPort),
		GRPCPort:   getEnvOrDefault("PORT_GRPC_CLIENT", DefaultGRPCPort),
		HTTPPort:   getEnvOrDefault("PORT_HTTP", DefaultHTTPPort),
		GRPCServer: getEnvOrDefault("GRPC_SERVER_ADDR", DefaultGRPCServer),
	}
}

// GetPortsForBase calculates ports for a given base number
// Base 800 -> ports 8001, 8002, 8003, 8004
// Base 801 -> ports 8011, 8012, 8013, 8014
func GetPortsForBase(base int) PortConfig {
	return PortConfig{
		DBPort:     getEnvOrDefault("PORT_DB", strconv.Itoa(base*10+1)),
		KafkaPort:  getEnvOrDefault("PORT_KAFKA", strconv.Itoa(base*10+2)),
		GRPCPort:   getEnvOrDefault("PORT_GRPC_CLIENT", strconv.Itoa(base*10+3)),
		HTTPPort:   getEnvOrDefault("PORT_HTTP", strconv.Itoa(base*10+4)),
		GRPCServer: getEnvOrDefault("GRPC_SERVER_ADDR", "127.0.0.1:50051"),
	}
}

// getEnvOrDefault returns environment variable value or default
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// SetDefaults allows overriding defaults via ldflags
func SetDefaults(dbPort, kafkaPort, grpcPort, httpPort, grpcServer string) {
	if dbPort != "" {
		DefaultDBPort = dbPort
	}
	if kafkaPort != "" {
		DefaultKafkaPort = kafkaPort
	}
	if grpcPort != "" {
		DefaultGRPCPort = grpcPort
	}
	if httpPort != "" {
		DefaultHTTPPort = httpPort
	}
	if grpcServer != "" {
		DefaultGRPCServer = grpcServer
	}
}
