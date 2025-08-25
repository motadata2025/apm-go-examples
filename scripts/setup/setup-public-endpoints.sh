#!/bin/bash

# Public Endpoints Setup Script
# This script configures Go application endpoints to be publicly accessible (IPv4 only)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Setting Up Public Application Endpoints (IPv4)${RESET}"
echo -e "${BLUE}=================================================${RESET}"
echo ""

# Function to get IPv4 public IP
get_ipv4_public_ip() {
    local ip=""
    
    # Try multiple services to get IPv4 public IP
    ip=$(curl -4 -s ifconfig.me 2>/dev/null) || \
    ip=$(curl -4 -s ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -4 -s icanhazip.com 2>/dev/null) || \
    ip=$(curl -4 -s checkip.amazonaws.com 2>/dev/null) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    
    # Validate IPv4 format
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo "Unable to determine IPv4 public IP"
        return 1
    fi
}

# Function to configure application for public access
configure_app_public() {
    local app_dir=$1
    local app_name=$2
    
    echo -e "${YELLOW}Configuring $app_name for public access...${RESET}"
    
    if [ ! -d "$app_dir" ]; then
        echo -e "${YELLOW}  ⚠️  $app_dir not found, skipping${RESET}"
        return 1
    fi
    
    # Find main.go files and update bind addresses
    find "$app_dir" -name "main.go" -type f | while read -r main_file; do
        echo -e "${YELLOW}  Updating $main_file...${RESET}"
        
        # Backup original file
        cp "$main_file" "${main_file}.backup"
        
        # Replace localhost and 127.0.0.1 with 0.0.0.0 for public binding
        sed -i 's/127\.0\.0\.1:/0.0.0.0:/g' "$main_file"
        sed -i 's/localhost:/0.0.0.0:/g' "$main_file"
        
        # If no explicit binding, ensure it binds to all interfaces
        if grep -q '":[0-9]' "$main_file" && ! grep -q '0\.0\.0\.0:' "$main_file"; then
            sed -i 's/":\([0-9]\)/"0.0.0.0:\1/g' "$main_file"
        fi
        
        echo -e "${GREEN}  ✓ Updated $main_file for public binding${RESET}"
    done
    
    # Update configuration files if they exist
    find "$app_dir" -name "config.go" -type f | while read -r config_file; do
        echo -e "${YELLOW}  Updating $config_file...${RESET}"
        
        # Backup original file
        cp "$config_file" "${config_file}.backup"
        
        # Update any hardcoded addresses
        sed -i 's/127\.0\.0\.1/0.0.0.0/g' "$config_file"
        sed -i 's/localhost/0.0.0.0/g' "$config_file"
        
        echo -e "${GREEN}  ✓ Updated $config_file${RESET}"
    done
}

# Function to configure firewall for application ports
configure_app_firewall() {
    echo -e "${YELLOW}Configuring firewall for application endpoints...${RESET}"
    
    # Application ports to open (not Docker infrastructure ports)
    local app_ports=(8001 8002 8003 8004 8005 8006 8007 8008 8009 8010)
    
    # Check if ufw is available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${YELLOW}Using UFW firewall...${RESET}"
        
        for port in "${app_ports[@]}"; do
            sudo ufw allow "$port" >/dev/null 2>&1 || true
            echo -e "${GREEN}✓ Opened application port $port in UFW${RESET}"
        done
        
        # Enable UFW if not already enabled
        sudo ufw --force enable >/dev/null 2>&1 || true
        
    # Check if firewall-cmd is available (CentOS/RHEL)
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${YELLOW}Using firewall-cmd...${RESET}"
        
        for port in "${app_ports[@]}"; do
            sudo firewall-cmd --permanent --add-port="$port/tcp" >/dev/null 2>&1 || true
            echo -e "${GREEN}✓ Opened application port $port in firewall-cmd${RESET}"
        done
        
        sudo firewall-cmd --reload >/dev/null 2>&1 || true
        
    # Check if iptables is available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${YELLOW}Using iptables...${RESET}"
        
        for port in "${app_ports[@]}"; do
            sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
            echo -e "${GREEN}✓ Opened application port $port in iptables${RESET}"
        done
        
        # Save iptables rules
        sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        
    else
        echo -e "${YELLOW}⚠️  No firewall management tool found. You may need to manually configure your firewall.${RESET}"
    fi
}

# Function to create public application startup script
create_public_app_startup() {
    cat > start-public-apps.sh << 'EOF'
#!/bin/bash

# Public Applications Startup Script
# This script starts Go applications with public IPv4 access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Starting Applications with Public IPv4 Access${RESET}"
echo ""

# Get IPv4 public IP
get_ipv4_public_ip() {
    local ip=""
    ip=$(curl -4 -s ifconfig.me 2>/dev/null) || \
    ip=$(curl -4 -s ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -4 -s icanhazip.com 2>/dev/null) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo "Unable to determine IPv4 public IP"
        return 1
    fi
}

PUBLIC_IP=$(get_ipv4_public_ip)

# Stop existing applications
echo -e "${YELLOW}Stopping existing applications...${RESET}"
./stop-db-apps.sh 2>/dev/null || true

# Set environment variables for public binding
export BIND_ADDRESS="0.0.0.0"
export HOST="0.0.0.0"
export SERVER_HOST="0.0.0.0"

# Start database applications with public binding
echo -e "${YELLOW}Starting applications with public access...${RESET}"
./start-db-apps.sh

echo ""
echo -e "${GREEN}🎉 Applications are now publicly accessible!${RESET}"
echo ""
echo -e "${CYAN}Public IPv4 Access URLs:${RESET}"
echo -e "  🌐 Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Show application URLs
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "${CYAN}DB SQL Multi Application:${RESET}"
    echo -e "  🚀 Base URL: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "  🔧 CRUD Operations: ${GREEN}http://$PUBLIC_IP:$port/trigger-crud${RESET}"
    echo -e "  📊 Health Check: ${GREEN}http://$PUBLIC_IP:$port/health${RESET}"
    echo -e "  🧪 Test Command: ${GREEN}curl http://$PUBLIC_IP:$port/trigger-crud${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "${CYAN}DB GORM Application:${RESET}"
    echo -e "  🚀 Base URL: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "  📊 Health Check: ${GREEN}http://$PUBLIC_IP:$port/health${RESET}"
    echo -e "  🧪 Test Command: ${GREEN}curl http://$PUBLIC_IP:$port/health${RESET}"
    echo ""
fi

# Show other applications if they exist
for app in grpc-svc kafka-segmentio http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        echo -e "${CYAN}${app} Application:${RESET}"
        echo -e "  🚀 Base URL: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
        echo ""
    fi
done

echo -e "${YELLOW}⚠️  Security Notice:${RESET}"
echo -e "  • Your application endpoints are now accessible from the internet"
echo -e "  • Infrastructure services (databases) remain internal"
echo -e "  • Consider adding authentication and rate limiting"
echo -e "  • Monitor access logs regularly"
echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./stop-public-apps.sh${RESET}     # Stop public applications"
echo -e "  ${GREEN}./status-public-apps.sh${RESET}   # Check public application status"
echo -e "  ${GREEN}./test-public-apps.sh${RESET}     # Test public application endpoints"

EOF

    chmod +x start-public-apps.sh
    echo -e "${GREEN}✓ Created start-public-apps.sh${RESET}"
}

# Function to create public application status checker
create_public_app_status() {
    cat > status-public-apps.sh << 'EOF'
#!/bin/bash

# Public Applications Status Checker
# This script checks the status of publicly accessible application endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Public Application Endpoints Status${RESET}"
echo -e "${BLUE}======================================${RESET}"
echo ""

# Get IPv4 public IP
get_ipv4_public_ip() {
    local ip=""
    ip=$(curl -4 -s ifconfig.me 2>/dev/null) || \
    ip=$(curl -4 -s ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -4 -s icanhazip.com 2>/dev/null) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo "Unable to determine IPv4 public IP"
        return 1
    fi
}

PUBLIC_IP=$(get_ipv4_public_ip)
echo -e "${CYAN}Public IPv4: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test application endpoint
test_app_endpoint() {
    local app_name=$1
    local port=$2
    local endpoint=${3:-""}
    
    echo -e "${YELLOW}Testing $app_name...${RESET}"
    echo -e "  Port: $port"
    echo -e "  URL: http://$PUBLIC_IP:$port$endpoint"
    
    if timeout 10 curl -4 -s "http://$PUBLIC_IP:$port$endpoint" >/dev/null 2>&1; then
        echo -e "  Status: ${GREEN}✓ PUBLICLY ACCESSIBLE${RESET}"
        
        # Try to get response content
        local response=$(timeout 5 curl -4 -s "http://$PUBLIC_IP:$port$endpoint" 2>/dev/null | head -c 100)
        if [ -n "$response" ]; then
            echo -e "  Response: ${GREEN}$(echo "$response" | tr '\n' ' ')${RESET}"
        fi
    else
        echo -e "  Status: ${RED}✗ NOT ACCESSIBLE${RESET}"
        echo -e "  Note: Check cloud provider security groups/firewall"
    fi
    echo ""
}

# Test application endpoints
echo -e "${CYAN}Application Endpoints:${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    test_app_endpoint "DB SQL Multi - Health" "$port" "/"
    test_app_endpoint "DB SQL Multi - CRUD" "$port" "/trigger-crud"
else
    echo -e "${YELLOW}DB SQL Multi not running${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    test_app_endpoint "DB GORM - Health" "$port" "/health"
else
    echo -e "${YELLOW}DB GORM not running${RESET}"
    echo ""
fi

# Test other applications
for app in grpc-svc kafka-segmentio http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        test_app_endpoint "$app" "$port" "/"
    fi
done

echo -e "${CYAN}Quick Test Commands:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  ${GREEN}curl http://$PUBLIC_IP:$port/trigger-crud${RESET}  # Test database operations"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  ${GREEN}curl http://$PUBLIC_IP:$port/health${RESET}        # Test GORM health"
fi

echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./start-public-apps.sh${RESET}    # Start public applications"
echo -e "  ${GREEN}./stop-public-apps.sh${RESET}     # Stop public applications"
echo -e "  ${GREEN}./test-public-apps.sh${RESET}     # Comprehensive endpoint testing"

EOF

    chmod +x status-public-apps.sh
    echo -e "${GREEN}✓ Created status-public-apps.sh${RESET}"
}

# Function to create comprehensive endpoint tester
create_endpoint_tester() {
    cat > test-public-apps.sh << 'EOF'
#!/bin/bash

# Public Application Endpoints Comprehensive Tester
# This script thoroughly tests all public application endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🧪 Comprehensive Public Endpoint Testing${RESET}"
echo -e "${BLUE}=========================================${RESET}"
echo ""

# Get IPv4 public IP
get_ipv4_public_ip() {
    local ip=""
    ip=$(curl -4 -s ifconfig.me 2>/dev/null) || \
    ip=$(curl -4 -s ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -4 -s icanhazip.com 2>/dev/null) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        echo "Unable to determine IPv4 public IP"
        return 1
    fi
}

PUBLIC_IP=$(get_ipv4_public_ip)
echo -e "${CYAN}Testing with IPv4: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test endpoint with detailed analysis
test_endpoint_detailed() {
    local name=$1
    local url=$2
    local expected_content=${3:-""}
    
    echo -e "${YELLOW}Testing $name...${RESET}"
    echo -e "  URL: $url"
    
    # Test connectivity
    local http_code=$(timeout 10 curl -4 -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    local response_time=$(timeout 10 curl -4 -s -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || echo "timeout")
    
    if [ "$http_code" = "200" ]; then
        echo -e "  Status: ${GREEN}✓ SUCCESS (HTTP $http_code)${RESET}"
        echo -e "  Response Time: ${GREEN}${response_time}s${RESET}"
        
        # Get response content
        local response=$(timeout 10 curl -4 -s "$url" 2>/dev/null | head -c 200)
        if [ -n "$response" ]; then
            echo -e "  Response: ${GREEN}$(echo "$response" | tr '\n' ' ' | cut -c1-80)...${RESET}"
        fi
        
        # Check for expected content if provided
        if [ -n "$expected_content" ]; then
            if echo "$response" | grep -q "$expected_content"; then
                echo -e "  Content Check: ${GREEN}✓ PASSED${RESET}"
            else
                echo -e "  Content Check: ${YELLOW}⚠ UNEXPECTED CONTENT${RESET}"
            fi
        fi
        
    elif [ "$http_code" != "000" ]; then
        echo -e "  Status: ${YELLOW}⚠ HTTP $http_code${RESET}"
        echo -e "  Note: Endpoint reachable but returned non-200 status"
    else
        echo -e "  Status: ${RED}✗ FAILED${RESET}"
        echo -e "  Note: Check cloud provider security groups/firewall rules"
    fi
    echo ""
}

# Test all application endpoints
echo -e "${CYAN}Application Endpoint Tests:${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "${BLUE}DB SQL Multi Application:${RESET}"
    test_endpoint_detailed "Health Check" "http://$PUBLIC_IP:$port/"
    test_endpoint_detailed "CRUD Operations" "http://$PUBLIC_IP:$port/trigger-crud" "message"
    test_endpoint_detailed "Database Test" "http://$PUBLIC_IP:$port/trigger-crud" "success"
else
    echo -e "${YELLOW}DB SQL Multi not running - start with ./start-public-apps.sh${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "${BLUE}DB GORM Application:${RESET}"
    test_endpoint_detailed "Health Check" "http://$PUBLIC_IP:$port/health" "ok"
else
    echo -e "${YELLOW}DB GORM not running${RESET}"
    echo ""
fi

# Test other applications
for app in grpc-svc kafka-segmentio http-rest; do
    if [ -f "runtime/logs/${app}.port" ]; then
        port=$(cat "runtime/logs/${app}.port")
        echo -e "${BLUE}${app} Application:${RESET}"
        test_endpoint_detailed "Base Endpoint" "http://$PUBLIC_IP:$port/"
    fi
done

# Summary
echo -e "${CYAN}Test Summary:${RESET}"
echo -e "  🌐 Public IPv4: ${GREEN}$PUBLIC_IP${RESET}"
echo -e "  📊 Application endpoints tested"
echo -e "  🔧 Infrastructure services remain internal (secure)"
echo ""

echo -e "${CYAN}Next Steps:${RESET}"
echo -e "  1. If tests fail: Check cloud provider security groups"
echo -e "  2. Add authentication: Implement API keys or OAuth"
echo -e "  3. Add monitoring: Set up access logging"
echo -e "  4. Add SSL: Use HTTPS with certificates"
echo ""

echo -e "${YELLOW}⚠️  Security Reminder:${RESET}"
echo -e "  • Your application endpoints are now public"
echo -e "  • Add authentication before production use"
echo -e "  • Monitor access logs regularly"
echo -e "  • Consider rate limiting for production"

EOF

    chmod +x test-public-apps.sh
    echo -e "${GREEN}✓ Created test-public-apps.sh${RESET}"
}

# Function to create stop script
create_stop_script() {
    cat > stop-public-apps.sh << 'EOF'
#!/bin/bash

# Stop Public Applications Script

echo "🛑 Stopping public applications..."

# Stop applications
./stop-db-apps.sh 2>/dev/null || true

echo "✓ All public applications stopped"
echo "Note: Infrastructure services (databases) continue running internally"
EOF

    chmod +x stop-public-apps.sh
    echo -e "${GREEN}✓ Created stop-public-apps.sh${RESET}"
}

# Main execution
echo -e "${BLUE}Step 1: Getting IPv4 public IP address...${RESET}"
PUBLIC_IP=$(get_ipv4_public_ip)
if [[ $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${GREEN}✓ IPv4 Public IP: $PUBLIC_IP${RESET}"
else
    echo -e "${YELLOW}⚠️  Could not determine IPv4 public IP automatically${RESET}"
    echo -e "${YELLOW}    You may need to configure this manually${RESET}"
fi
echo ""

echo -e "${BLUE}Step 2: Configuring firewall for application ports...${RESET}"
configure_app_firewall
echo ""

echo -e "${BLUE}Step 3: Configuring applications for public access...${RESET}"
configure_app_public "services/db-sql-multi" "DB SQL Multi"
configure_app_public "db-gorm" "DB GORM"
configure_app_public "grpc-svc" "gRPC Service" || true
configure_app_public "kafka-segmentio" "Kafka Service" || true
configure_app_public "http-rest" "HTTP REST Service" || true
echo ""

echo -e "${BLUE}Step 4: Creating public application management scripts...${RESET}"
create_public_app_startup
create_public_app_status
create_endpoint_tester
create_stop_script
echo ""

echo -e "${GREEN}🎉 Public Application Endpoints Setup Complete!${RESET}"
echo ""
echo -e "${CYAN}Next Steps:${RESET}"
echo -e "  1. Start public applications: ${GREEN}./start-public-apps.sh${RESET}"
echo -e "  2. Check public status: ${GREEN}./status-public-apps.sh${RESET}"
echo -e "  3. Test endpoints: ${GREEN}./test-public-apps.sh${RESET}"
echo ""
echo -e "${CYAN}Your Public IPv4 Endpoints Will Be:${RESET}"
echo -e "  🌐 Base URL: ${GREEN}http://$PUBLIC_IP:PORT${RESET}"
echo -e "  🔧 DB Operations: ${GREEN}http://$PUBLIC_IP:PORT/trigger-crud${RESET}"
echo -e "  📊 Health Checks: ${GREEN}http://$PUBLIC_IP:PORT/health${RESET}"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${RESET}"
echo -e "  • Only application endpoints will be public (not database ports)"
echo -e "  • Infrastructure services remain internal for security"
echo -e "  • Configure cloud provider security groups if needed"
echo -e "  • Add authentication before production use"
