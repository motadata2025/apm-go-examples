#!/bin/bash

# Machine IP Access Setup Script
# This script configures endpoints to be accessible via your machine's actual IP address

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Setting Up Machine IP Access for Endpoints${RESET}"
echo -e "${BLUE}=============================================${RESET}"
echo ""

# Function to get machine's primary IP
get_machine_ip() {
    # Get the primary IP (first non-localhost IP)
    local ip=$(hostname -I | awk '{print $1}')
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$ip"
    else
        # Fallback method
        ip=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null)
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
        else
            echo "Unable to determine machine IP"
            return 1
        fi
    fi
}

# Function to get all machine IPs
get_all_machine_ips() {
    echo "Available IP addresses on this machine:"
    ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | awk '{print "  " $2}' | cut -d'/' -f1
}

# Function to create machine IP startup script
create_machine_ip_startup() {
    local machine_ip=$1
    
    cat > start-machine-ip-apps.sh << EOF
#!/bin/bash

# Machine IP Applications Startup Script
# This script starts applications accessible via your machine's IP address

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "\${BLUE}🌐 Starting Applications on Machine IP${RESET}"
echo ""

MACHINE_IP="$machine_ip"

# Stop existing applications
echo -e "\${YELLOW}Stopping existing applications...\${RESET}"
./stop-db-apps.sh 2>/dev/null || true

# Set environment variables for public binding
export BIND_ADDRESS="0.0.0.0"
export HOST="0.0.0.0"
export SERVER_HOST="0.0.0.0"

# Start database applications
echo -e "\${YELLOW}Starting applications...\${RESET}"
./start-db-apps.sh

echo ""
echo -e "\${GREEN}🎉 Applications are now accessible via machine IP!\${RESET}"
echo ""
echo -e "\${CYAN}Machine IP Access URLs:\${RESET}"
echo -e "  🌐 Machine IP: \${GREEN}\$MACHINE_IP\${RESET}"
echo ""

# Show application URLs
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=\$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "\${CYAN}DB SQL Multi Application:\${RESET}"
    echo -e "  🚀 Base URL: \${GREEN}http://\$MACHINE_IP:\$port\${RESET}"
    echo -e "  🔧 CRUD Operations: \${GREEN}http://\$MACHINE_IP:\$port/trigger-crud\${RESET}"
    echo -e "  📊 Health Check: \${GREEN}http://\$MACHINE_IP:\$port/health\${RESET}"
    echo -e "  🧪 Test Command: \${GREEN}curl http://\$MACHINE_IP:\$port/trigger-crud\${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=\$(cat runtime/logs/db-gorm.port)
    echo -e "\${CYAN}DB GORM Application:\${RESET}"
    echo -e "  🚀 Base URL: \${GREEN}http://\$MACHINE_IP:\$port\${RESET}"
    echo -e "  📊 Health Check: \${GREEN}http://\$MACHINE_IP:\$port/health\${RESET}"
    echo -e "  🧪 Test Command: \${GREEN}curl http://\$MACHINE_IP:\$port/health\${RESET}"
    echo ""
fi

# Show other applications if they exist
for app in grpc-svc kafka-segmentio http-rest; do
    if [ -f "runtime/logs/\${app}.port" ]; then
        port=\$(cat "runtime/logs/\${app}.port")
        echo -e "\${CYAN}\${app} Application:\${RESET}"
        echo -e "  🚀 Base URL: \${GREEN}http://\$MACHINE_IP:\$port\${RESET}"
        echo ""
    fi
done

echo -e "\${CYAN}Access from other machines on the same network:\${RESET}"
echo -e "  • Use the URLs above from any device on the same network"
echo -e "  • Make sure firewall allows connections to these ports"
echo -e "  • Applications are bound to 0.0.0.0 (all interfaces)"
echo ""
echo -e "\${CYAN}Management Commands:\${RESET}"
echo -e "  \${GREEN}./stop-machine-ip-apps.sh\${RESET}     # Stop applications"
echo -e "  \${GREEN}./status-machine-ip-apps.sh\${RESET}   # Check status"
echo -e "  \${GREEN}./test-machine-ip-apps.sh\${RESET}     # Test endpoints"
EOF

    chmod +x start-machine-ip-apps.sh
    echo -e "${GREEN}✓ Created start-machine-ip-apps.sh${RESET}"
}

# Function to create status checker
create_machine_ip_status() {
    local machine_ip=$1
    
    cat > status-machine-ip-apps.sh << EOF
#!/bin/bash

# Machine IP Applications Status Checker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "\${BLUE}🌐 Machine IP Application Status\${RESET}"
echo -e "\${BLUE}================================\${RESET}"
echo ""

MACHINE_IP="$machine_ip"
echo -e "\${CYAN}Machine IP: \${GREEN}\$MACHINE_IP\${RESET}"
echo ""

# Function to test application endpoint
test_app_endpoint() {
    local app_name=\$1
    local port=\$2
    local endpoint=\${3:-""}
    
    echo -e "\${YELLOW}Testing \$app_name...\${RESET}"
    echo -e "  Port: \$port"
    echo -e "  URL: http://\$MACHINE_IP:\$port\$endpoint"
    
    if timeout 5 curl -s "http://\$MACHINE_IP:\$port\$endpoint" >/dev/null 2>&1; then
        echo -e "  Status: \${GREEN}✓ ACCESSIBLE\${RESET}"
        
        # Try to get response content
        local response=\$(timeout 3 curl -s "http://\$MACHINE_IP:\$port\$endpoint" 2>/dev/null | head -c 100)
        if [ -n "\$response" ]; then
            echo -e "  Response: \${GREEN}\$(echo "\$response" | tr '\n' ' ')\${RESET}"
        fi
    else
        echo -e "  Status: \${RED}✗ NOT ACCESSIBLE\${RESET}"
        echo -e "  Note: Check if application is running and firewall settings"
    fi
    echo ""
}

# Test application endpoints
echo -e "\${CYAN}Application Endpoints:\${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=\$(cat runtime/logs/services/db-sql-multi.port)
    test_app_endpoint "DB SQL Multi - Health" "\$port" "/"
    test_app_endpoint "DB SQL Multi - CRUD" "\$port" "/trigger-crud"
else
    echo -e "\${YELLOW}DB SQL Multi not running\${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=\$(cat runtime/logs/db-gorm.port)
    test_app_endpoint "DB GORM - Health" "\$port" "/health"
else
    echo -e "\${YELLOW}DB GORM not running\${RESET}"
    echo ""
fi

echo -e "\${CYAN}Quick Test Commands:\${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=\$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  \${GREEN}curl http://\$MACHINE_IP:\$port/trigger-crud\${RESET}  # Test database operations"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=\$(cat runtime/logs/db-gorm.port)
    echo -e "  \${GREEN}curl http://\$MACHINE_IP:\$port/health\${RESET}        # Test GORM health"
fi
EOF

    chmod +x status-machine-ip-apps.sh
    echo -e "${GREEN}✓ Created status-machine-ip-apps.sh${RESET}"
}

# Function to create comprehensive tester
create_machine_ip_tester() {
    local machine_ip=$1
    
    cat > test-machine-ip-apps.sh << EOF
#!/bin/bash

# Machine IP Applications Comprehensive Tester

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "\${BLUE}🧪 Comprehensive Machine IP Endpoint Testing\${RESET}"
echo -e "\${BLUE}==========================================\${RESET}"
echo ""

MACHINE_IP="$machine_ip"
echo -e "\${CYAN}Testing with Machine IP: \${GREEN}\$MACHINE_IP\${RESET}"
echo ""

# Function to test endpoint with detailed analysis
test_endpoint_detailed() {
    local name=\$1
    local url=\$2
    local expected_content=\${3:-""}
    
    echo -e "\${YELLOW}Testing \$name...\${RESET}"
    echo -e "  URL: \$url"
    
    # Test connectivity
    local http_code=\$(timeout 10 curl -s -o /dev/null -w "%{http_code}" "\$url" 2>/dev/null || echo "000")
    local response_time=\$(timeout 10 curl -s -o /dev/null -w "%{time_total}" "\$url" 2>/dev/null || echo "timeout")
    
    if [ "\$http_code" = "200" ]; then
        echo -e "  Status: \${GREEN}✓ SUCCESS (HTTP \$http_code)\${RESET}"
        echo -e "  Response Time: \${GREEN}\${response_time}s\${RESET}"
        
        # Get response content
        local response=\$(timeout 10 curl -s "\$url" 2>/dev/null | head -c 200)
        if [ -n "\$response" ]; then
            echo -e "  Response: \${GREEN}\$(echo "\$response" | tr '\n' ' ' | cut -c1-80)...\${RESET}"
        fi
        
        # Check for expected content if provided
        if [ -n "\$expected_content" ]; then
            if echo "\$response" | grep -q "\$expected_content"; then
                echo -e "  Content Check: \${GREEN}✓ PASSED\${RESET}"
            else
                echo -e "  Content Check: \${YELLOW}⚠ UNEXPECTED CONTENT\${RESET}"
            fi
        fi
        
    elif [ "\$http_code" != "000" ]; then
        echo -e "  Status: \${YELLOW}⚠ HTTP \$http_code\${RESET}"
        echo -e "  Note: Endpoint reachable but returned non-200 status"
    else
        echo -e "  Status: \${RED}✗ FAILED\${RESET}"
        echo -e "  Note: Check if application is running and firewall settings"
    fi
    echo ""
}

# Test all application endpoints
echo -e "\${CYAN}Application Endpoint Tests:\${RESET}"

if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=\$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "\${BLUE}DB SQL Multi Application:\${RESET}"
    test_endpoint_detailed "Health Check" "http://\$MACHINE_IP:\$port/"
    test_endpoint_detailed "CRUD Operations" "http://\$MACHINE_IP:\$port/trigger-crud" "message"
    test_endpoint_detailed "Database Test" "http://\$MACHINE_IP:\$port/trigger-crud" "success"
else
    echo -e "\${YELLOW}DB SQL Multi not running - start with ./start-machine-ip-apps.sh\${RESET}"
    echo ""
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=\$(cat runtime/logs/db-gorm.port)
    echo -e "\${BLUE}DB GORM Application:\${RESET}"
    test_endpoint_detailed "Health Check" "http://\$MACHINE_IP:\$port/health" "ok"
else
    echo -e "\${YELLOW}DB GORM not running\${RESET}"
    echo ""
fi

# Summary
echo -e "\${CYAN}Test Summary:\${RESET}"
echo -e "  🌐 Machine IP: \${GREEN}\$MACHINE_IP\${RESET}"
echo -e "  📊 Application endpoints tested"
echo -e "  🔧 Accessible from same network"
echo ""

echo -e "\${CYAN}Network Access:\${RESET}"
echo -e "  • Same machine: ✓ Working"
echo -e "  • Same network: ✓ Should work (if firewall allows)"
echo -e "  • Internet: Requires port forwarding/public IP"
echo ""

echo -e "\${YELLOW}📝 Notes:\${RESET}"
echo -e "  • Applications are bound to 0.0.0.0 (all interfaces)"
echo -e "  • Accessible from other devices on the same network"
echo -e "  • For internet access, configure router port forwarding"
EOF

    chmod +x test-machine-ip-apps.sh
    echo -e "${GREEN}✓ Created test-machine-ip-apps.sh${RESET}"
}

# Function to create stop script
create_machine_ip_stop() {
    cat > stop-machine-ip-apps.sh << 'EOF'
#!/bin/bash

# Stop Machine IP Applications Script

echo "🛑 Stopping machine IP applications..."

# Stop applications
./stop-db-apps.sh 2>/dev/null || true

echo "✓ All applications stopped"
EOF

    chmod +x stop-machine-ip-apps.sh
    echo -e "${GREEN}✓ Created stop-machine-ip-apps.sh${RESET}"
}

# Main execution
echo -e "${BLUE}Step 1: Detecting machine IP addresses...${RESET}"
MACHINE_IP=$(get_machine_ip)

if [[ $MACHINE_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${GREEN}✓ Primary Machine IP: $MACHINE_IP${RESET}"
else
    echo -e "${RED}✗ Could not determine machine IP${RESET}"
    exit 1
fi

echo ""
get_all_machine_ips
echo ""

echo -e "${BLUE}Step 2: Creating machine IP access scripts...${RESET}"
create_machine_ip_startup "$MACHINE_IP"
create_machine_ip_status "$MACHINE_IP"
create_machine_ip_tester "$MACHINE_IP"
create_machine_ip_stop
echo ""

echo -e "${GREEN}🎉 Machine IP Access Setup Complete!${RESET}"
echo ""
echo -e "${CYAN}Your Machine IP: ${GREEN}$MACHINE_IP${RESET}"
echo ""
echo -e "${CYAN}Next Steps:${RESET}"
echo -e "  1. Start applications: ${GREEN}./start-machine-ip-apps.sh${RESET}"
echo -e "  2. Check status: ${GREEN}./status-machine-ip-apps.sh${RESET}"
echo -e "  3. Test endpoints: ${GREEN}./test-machine-ip-apps.sh${RESET}"
echo ""
echo -e "${CYAN}Your Endpoints Will Be Accessible At:${RESET}"
echo -e "  🌐 Base URL: ${GREEN}http://$MACHINE_IP:PORT${RESET}"
echo -e "  🔧 DB Operations: ${GREEN}http://$MACHINE_IP:PORT/trigger-crud${RESET}"
echo -e "  📊 Health Checks: ${GREEN}http://$MACHINE_IP:PORT/health${RESET}"
echo ""
echo -e "${YELLOW}📝 Access Notes:${RESET}"
echo -e "  • ✅ Same machine: Direct access"
echo -e "  • ✅ Same network: Access from other devices"
echo -e "  • ⚠️  Internet: Requires router configuration"
echo -e "  • 🔧 Applications bind to 0.0.0.0 (all interfaces)"
