#!/bin/bash
set -euo pipefail

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo -e "${BLUE}Patching source files to support environment variable port injection...${RESET}"

# Backup and patch db-sql-multi main.go
DB_MAIN="$PROJECT_ROOT/db-sql-multi/cmd/app/main.go"
if [ ! -f "$DB_MAIN.backup" ]; then
    echo -e "${YELLOW}Backing up and patching $DB_MAIN${RESET}"
    cp "$DB_MAIN" "$DB_MAIN.backup"
    
    # Replace hardcoded port with environment variable
    sed -i 's/Addr:    "0.0.0.0:8081"/Addr:    "0.0.0.0:" + getEnvOrDefault("PORT_DB", "8081")/' "$DB_MAIN"
    
    # Add helper function before main()
    sed -i '/^func main() {/i\
// getEnvOrDefault returns environment variable value or default\
func getEnvOrDefault(key, defaultValue string) string {\
	if value := os.Getenv(key); value != "" {\
		return value\
	}\
	return defaultValue\
}\
' "$DB_MAIN"
fi

# Patch grpc-svc client main.go
GRPC_CLIENT_MAIN="$PROJECT_ROOT/grpc-svc/cmd/client/main.go"
if [ ! -f "$GRPC_CLIENT_MAIN.backup" ]; then
    echo -e "${YELLOW}Backing up and patching $GRPC_CLIENT_MAIN${RESET}"
    cp "$GRPC_CLIENT_MAIN" "$GRPC_CLIENT_MAIN.backup"
    
    # Replace hardcoded addresses
    sed -i 's/grpc.Dial("127.0.0.1:50051"/grpc.Dial(getEnvOrDefault("GRPC_SERVER_ADDR", "127.0.0.1:50051")/' "$GRPC_CLIENT_MAIN"
    sed -i 's/Addr:    "0.0.0.0:8083"/Addr:    "0.0.0.0:" + getEnvOrDefault("PORT_GRPC_CLIENT", "8083")/' "$GRPC_CLIENT_MAIN"
    
    # Add helper function
    sed -i '/^func main() {/i\
// getEnvOrDefault returns environment variable value or default\
func getEnvOrDefault(key, defaultValue string) string {\
	if value := os.Getenv(key); value != "" {\
		return value\
	}\
	return defaultValue\
}\
' "$GRPC_CLIENT_MAIN"
fi

# Patch grpc-svc server main.go
GRPC_SERVER_MAIN="$PROJECT_ROOT/grpc-svc/cmd/server/main.go"
if [ ! -f "$GRPC_SERVER_MAIN.backup" ]; then
    echo -e "${YELLOW}Backing up and patching $GRPC_SERVER_MAIN${RESET}"
    cp "$GRPC_SERVER_MAIN" "$GRPC_SERVER_MAIN.backup"
    
    # Replace hardcoded port
    sed -i 's/net.Listen("tcp", ":50051")/net.Listen("tcp", getEnvOrDefault("GRPC_SERVER_ADDR", ":50051"))/' "$GRPC_SERVER_MAIN"
    
    # Add helper function and import
    sed -i '/^import (/a\
	"os"' "$GRPC_SERVER_MAIN"
    
    sed -i '/^func main() {/i\
// getEnvOrDefault returns environment variable value or default\
func getEnvOrDefault(key, defaultValue string) string {\
	if value := os.Getenv(key); value != "" {\
		return value\
	}\
	return defaultValue\
}\
' "$GRPC_SERVER_MAIN"
fi

# Patch kafka producer main.go
KAFKA_PRODUCER_MAIN="$PROJECT_ROOT/kafka-segmentio/cmd/producer/main.go"
if [ ! -f "$KAFKA_PRODUCER_MAIN.backup" ]; then
    echo -e "${YELLOW}Backing up and patching $KAFKA_PRODUCER_MAIN${RESET}"
    cp "$KAFKA_PRODUCER_MAIN" "$KAFKA_PRODUCER_MAIN.backup"
    
    # Replace hardcoded port
    sed -i 's/Addr:    "0.0.0.0:8082"/Addr:    "0.0.0.0:" + getEnvOrDefault("PORT_KAFKA", "8082")/' "$KAFKA_PRODUCER_MAIN"
    
    # Add helper function
    sed -i '/^func writeJSON/i\
// getEnvOrDefault returns environment variable value or default\
func getEnvOrDefault(key, defaultValue string) string {\
	if value := os.Getenv(key); value != "" {\
		return value\
	}\
	return defaultValue\
}\
' "$KAFKA_PRODUCER_MAIN"
fi

# Patch http-rest main.go
HTTP_MAIN="$PROJECT_ROOT/http-rest/cmd/api/main.go"
if [ ! -f "$HTTP_MAIN.backup" ]; then
    echo -e "${YELLOW}Backing up and patching $HTTP_MAIN${RESET}"
    cp "$HTTP_MAIN" "$HTTP_MAIN.backup"

    # Replace hardcoded port
    sed -i 's/addr := "0.0.0.0:8084"/addr := "0.0.0.0:" + getEnvOrDefault("PORT_HTTP", "8084")/' "$HTTP_MAIN"

    # Add helper function (os is already imported)
    sed -i '/^func main() {/i\
// getEnvOrDefault returns environment variable value or default\
func getEnvOrDefault(key, defaultValue string) string {\
	if value := os.Getenv(key); value != "" {\
		return value\
	}\
	return defaultValue\
}\
' "$HTTP_MAIN"
fi

# Update external handlers to use environment variables
EXT_HANDLERS="$PROJECT_ROOT/http-rest/internal/handlers/external_handlers.go"
if [ ! -f "$EXT_HANDLERS.backup" ]; then
    echo -e "${YELLOW}Backing up and patching $EXT_HANDLERS${RESET}"
    cp "$EXT_HANDLERS" "$EXT_HANDLERS.backup"

    # Add import and helper function
    sed -i '/^import (/a\
	"os"' "$EXT_HANDLERS"
    
    sed -i '/^type TriggerResponse/i\
// getEnvOrDefault returns environment variable value or default\
func getEnvOrDefault(key, defaultValue string) string {\
	if value := os.Getenv(key); value != "" {\
		return value\
	}\
	return defaultValue\
}\
' "$EXT_HANDLERS"
    
    # Replace hardcoded URLs with environment-based ones
    sed -i 's|"http://localhost:8081/trigger-crud"|"http://localhost:" + getEnvOrDefault("PORT_DB", "8081") + "/trigger-crud"|' "$EXT_HANDLERS"
    sed -i 's|"http://localhost:8082/trigger-produce"|"http://localhost:" + getEnvOrDefault("PORT_KAFKA", "8082") + "/trigger-produce"|' "$EXT_HANDLERS"
    sed -i 's|"http://localhost:8083/trigger-simple"|"http://localhost:" + getEnvOrDefault("PORT_GRPC_CLIENT", "8083") + "/trigger-simple"|' "$EXT_HANDLERS"
    sed -i 's|"http://localhost:8083/trigger-stream"|"http://localhost:" + getEnvOrDefault("PORT_GRPC_CLIENT", "8083") + "/trigger-stream"|' "$EXT_HANDLERS"
    
    # Update the services array in TriggerAllServices
    sed -i 's|{"database-sql", "http://localhost:8081/trigger-crud"}|{"database-sql", "http://localhost:" + getEnvOrDefault("PORT_DB", "8081") + "/trigger-crud"}|' "$EXT_HANDLERS"
    sed -i 's|{"kafka-go", "http://localhost:8082/trigger-produce"}|{"kafka-go", "http://localhost:" + getEnvOrDefault("PORT_KAFKA", "8082") + "/trigger-produce"}|' "$EXT_HANDLERS"
    sed -i 's|{"grpc-unary", "http://localhost:8083/trigger-simple"}|{"grpc-unary", "http://localhost:" + getEnvOrDefault("PORT_GRPC_CLIENT", "8083") + "/trigger-simple"}|' "$EXT_HANDLERS"
    sed -i 's|{"grpc-stream", "http://localhost:8083/trigger-stream"}|{"grpc-stream", "http://localhost:" + getEnvOrDefault("PORT_GRPC_CLIENT", "8083") + "/trigger-stream"}|' "$EXT_HANDLERS"
fi

echo -e "${GREEN}✓ All source files patched successfully${RESET}"
echo -e "${YELLOW}Note: Original files backed up with .backup extension${RESET}"
