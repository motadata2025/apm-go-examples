#!/bin/bash
set -euo pipefail

# Colors
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MULTI_SET_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GO="${GO:-go}"
CGO_ENABLED="${CGO_ENABLED:-0}"

# Service paths - use wrapper commands that support environment variables
DB_SQL_PATH="$MULTI_SET_ROOT/cmd/db-sql-multi"
GRPC_CLIENT_PATH="$MULTI_SET_ROOT/cmd/grpc-client"
GRPC_SERVER_PATH="$MULTI_SET_ROOT/cmd/grpc-server"
KAFKA_PRODUCER_PATH="$MULTI_SET_ROOT/cmd/kafka-producer"
KAFKA_CONSUMER_PATH="$MULTI_SET_ROOT/cmd/kafka-consumer"
HTTP_REST_PATH="$MULTI_SET_ROOT/cmd/http-rest"

# Original service paths for go.mod dependencies
ORIG_DB_SQL_PATH="$PROJECT_ROOT/db-sql-multi"
ORIG_GRPC_SVC_PATH="$PROJECT_ROOT/grpc-svc"
ORIG_KAFKA_PATH="$PROJECT_ROOT/kafka-segmentio"
ORIG_HTTP_REST_PATH="$PROJECT_ROOT/http-rest"

# Build specific base or all bases
if [ -n "${BASE:-}" ]; then
    BASES="$BASE"
else
    BASES="${BASES:-800 801 802 803}"
fi

echo -e "${BLUE}Building sets for bases: $BASES${RESET}"

build_service() {
    local service_name="$1"
    local cmd_path="$2"
    local output_path="$3"
    local build_flags="$4"
    local ldflags="$5"
    local orig_service_path="$6"

    echo -e "${YELLOW}  Building $(basename "$output_path")...${RESET}"

    # Build from the original service directory using original source
    cd "$orig_service_path"

    if [ -n "$ldflags" ]; then
        eval "$GO build $build_flags -ldflags \"$ldflags\" -o \"$output_path\" \"$cmd_path\""
    else
        eval "$GO build $build_flags -o \"$output_path\" \"$cmd_path\""
    fi
}

build_set() {
    local base="$1"
    local set_name=""
    local build_flags=""
    local ldflags=""
    
    # Determine set name and build flags
    case "$base" in
        800)
            set_name="build-800"
            build_flags=""
            ;;
        801)
            set_name="static-801"
            build_flags="-a"
            ldflags="-s -w"
            export CGO_ENABLED=0
            ;;
        802)
            set_name="race-802"
            build_flags="-race"
            export CGO_ENABLED=1
            ;;
        803)
            set_name="xcompile-803"
            build_flags=""
            ;;
        *)
            echo -e "${RED}Unknown base: $base${RESET}"
            return 1
            ;;
    esac
    
    echo -e "${CYAN}Building set: $set_name (base $base)${RESET}"
    
    # Create directories
    mkdir -p "$MULTI_SET_ROOT/$set_name"/{bin,logs,env}
    
    # Calculate ports
    local db_port=$((base * 10 + 1))
    local kafka_port=$((base * 10 + 2))
    local grpc_port=$((base * 10 + 3))
    local http_port=$((base * 10 + 4))
    local grpc_server_port=$((base * 10 + 5))
    local grpc_server="127.0.0.1:$grpc_server_port"
    
    # Create environment file
    cat > "$MULTI_SET_ROOT/$set_name/env/$set_name.env" << EOF
# Environment variables for $set_name
export PORT_DB=$db_port
export PORT_KAFKA=$kafka_port
export PORT_GRPC_CLIENT=$grpc_port
export PORT_HTTP=$http_port
export GRPC_SERVER_ADDR=$grpc_server
export SET_NAME=$set_name
export BASE=$base
EOF
    
    # Build port injection ldflags
    local port_ldflags=""
    if [ -n "$ldflags" ]; then
        port_ldflags="$ldflags"
    fi
    
    # For cross-compilation, handle differently
    if [ "$set_name" = "xcompile-803" ]; then
        build_cross_compile "$set_name" "$base" "$build_flags" "$port_ldflags"
        return 0
    fi
    
    # Build main services (all sets get these)
    build_service "database-sql" "./cmd/app" "$MULTI_SET_ROOT/$set_name/bin/database-sql-$base" "$build_flags" "$port_ldflags" "$ORIG_DB_SQL_PATH"
    build_service "kafka-producer" "./cmd/producer" "$MULTI_SET_ROOT/$set_name/bin/kafka-producer-$base" "$build_flags" "$port_ldflags" "$ORIG_KAFKA_PATH"
    build_service "grpc-client" "./cmd/client" "$MULTI_SET_ROOT/$set_name/bin/grpc-client-$base" "$build_flags" "$port_ldflags" "$ORIG_GRPC_SVC_PATH"
    build_service "http-rest" "./cmd/api" "$MULTI_SET_ROOT/$set_name/bin/http-rest-$base" "$build_flags" "$port_ldflags" "$ORIG_HTTP_REST_PATH"

    # Only build-800 gets server and consumer
    if [ "$set_name" = "build-800" ]; then
        build_service "grpc-server" "./cmd/server" "$MULTI_SET_ROOT/$set_name/bin/grpc-server-$base" "$build_flags" "$port_ldflags" "$ORIG_GRPC_SVC_PATH"
        build_service "kafka-consumer" "./cmd/consumer" "$MULTI_SET_ROOT/$set_name/bin/kafka-consumer-$base" "$build_flags" "$port_ldflags" "$ORIG_KAFKA_PATH"
    fi
    
    echo -e "${GREEN}✓ Set $set_name built successfully${RESET}"
}

build_cross_compile() {
    local set_name="$1"
    local base="$2"
    local build_flags="$3"
    local ldflags="$4"
    
    echo -e "${YELLOW}Cross-compiling for multiple platforms...${RESET}"
    
    # Platform matrix
    local platforms=(
        "linux/amd64"
        "linux/arm64"
        "darwin/amd64"
        "darwin/arm64"
        "windows/amd64"
    )
    
    for platform in "${platforms[@]}"; do
        local goos="${platform%/*}"
        local goarch="${platform#*/}"
        local suffix="-${goos}-${goarch}"
        
        if [ "$goos" = "windows" ]; then
            suffix="${suffix}.exe"
        fi
        
        echo -e "${YELLOW}  Building for $platform...${RESET}"
        
        export GOOS="$goos"
        export GOARCH="$goarch"
        export CGO_ENABLED=0
        
        # Build main services
        build_service "database-sql" "./cmd/app" "$MULTI_SET_ROOT/$set_name/bin/database-sql-$base$suffix" "$build_flags" "$ldflags" "$ORIG_DB_SQL_PATH"
        build_service "kafka-producer" "./cmd/producer" "$MULTI_SET_ROOT/$set_name/bin/kafka-producer-$base$suffix" "$build_flags" "$ldflags" "$ORIG_KAFKA_PATH"
        build_service "grpc-client" "./cmd/client" "$MULTI_SET_ROOT/$set_name/bin/grpc-client-$base$suffix" "$build_flags" "$ldflags" "$ORIG_GRPC_SVC_PATH"
        build_service "http-rest" "./cmd/api" "$MULTI_SET_ROOT/$set_name/bin/http-rest-$base$suffix" "$build_flags" "$ldflags" "$ORIG_HTTP_REST_PATH"
        
        unset GOOS GOARCH
    done
}

# Main execution
main() {
    echo -e "${BLUE}Multi-Set Build System${RESET}"
    echo -e "${BLUE}Project root: $PROJECT_ROOT${RESET}"
    echo -e "${BLUE}Multi-set root: $MULTI_SET_ROOT${RESET}"
    echo ""
    
    for base in $BASES; do
        build_set "$base"
        echo ""
    done
    
    echo -e "${GREEN}✓ All requested sets built successfully${RESET}"
}

# Run main function
main "$@"
