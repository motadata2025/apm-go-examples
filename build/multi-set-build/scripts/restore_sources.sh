#!/bin/bash
set -euo pipefail

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo -e "${BLUE}Restoring original source files...${RESET}"

# List of files to restore
FILES=(
    "$PROJECT_ROOT/db-sql-multi/cmd/app/main.go"
    "$PROJECT_ROOT/grpc-svc/cmd/client/main.go"
    "$PROJECT_ROOT/grpc-svc/cmd/server/main.go"
    "$PROJECT_ROOT/kafka-segmentio/cmd/producer/main.go"
    "$PROJECT_ROOT/http-rest/cmd/api/main.go"
    "$PROJECT_ROOT/http-rest/internal/handlers/external_handlers.go"
)

for file in "${FILES[@]}"; do
    if [ -f "$file.backup" ]; then
        echo -e "${YELLOW}Restoring $file${RESET}"
        mv "$file.backup" "$file"
    else
        echo -e "${YELLOW}No backup found for $file${RESET}"
    fi
done

echo -e "${GREEN}✓ Source files restored${RESET}"
