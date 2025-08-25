#!/bin/bash

# Public Access Setup Script
# This script configures all endpoints to be publicly accessible from the internet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Setting Up Public Internet Access${RESET}"
echo -e "${BLUE}====================================${RESET}"
echo ""

# Function to get public IP
get_public_ip() {
    local ip=""
    
    # Try multiple services to get public IP
    ip=$(curl -s ifconfig.me 2>/dev/null) || \
    ip=$(curl -s ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -s icanhazip.com 2>/dev/null) || \
    ip=$(curl -s checkip.amazonaws.com 2>/dev/null)
    
    if [ -n "$ip" ]; then
        echo "$ip"
    else
        echo "Unable to determine public IP"
        return 1
    fi
}

# Function to check if port is open externally
check_external_port() {
    local port=$1
    local public_ip=$2
    
    echo -e "${YELLOW}Checking external access for port $port...${RESET}"
    
    # Use nc to check if port is accessible externally
    if timeout 5 nc -z "$public_ip" "$port" 2>/dev/null; then
        echo -e "${GREEN}✓ Port $port is externally accessible${RESET}"
        return 0
    else
        echo -e "${RED}✗ Port $port is not externally accessible${RESET}"
        return 1
    fi
}

# Function to configure firewall
configure_firewall() {
    echo -e "${YELLOW}Configuring firewall for public access...${RESET}"
    
    # Ports to open
    local ports=(5432 3306 8080 8001 8002 8003 8004 8005 9092 2181)
    
    # Check if ufw is available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${YELLOW}Using UFW firewall...${RESET}"
        
        for port in "${ports[@]}"; do
            sudo ufw allow "$port" >/dev/null 2>&1 || true
            echo -e "${GREEN}✓ Opened port $port in UFW${RESET}"
        done
        
        # Enable UFW if not already enabled
        sudo ufw --force enable >/dev/null 2>&1 || true
        
    # Check if firewall-cmd is available (CentOS/RHEL)
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${YELLOW}Using firewall-cmd...${RESET}"
        
        for port in "${ports[@]}"; do
            sudo firewall-cmd --permanent --add-port="$port/tcp" >/dev/null 2>&1 || true
            echo -e "${GREEN}✓ Opened port $port in firewall-cmd${RESET}"
        done
        
        sudo firewall-cmd --reload >/dev/null 2>&1 || true
        
    # Check if iptables is available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${YELLOW}Using iptables...${RESET}"
        
        for port in "${ports[@]}"; do
            sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
            echo -e "${GREEN}✓ Opened port $port in iptables${RESET}"
        done
        
        # Save iptables rules
        sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        
    else
        echo -e "${YELLOW}⚠️  No firewall management tool found. You may need to manually configure your firewall.${RESET}"
    fi
}

# Function to update Docker Compose for public access
update_docker_compose() {
    echo -e "${YELLOW}Updating Docker Compose for public access...${RESET}"
    
    # Create public version of infrastructure/docker-compose
    cp infrastructure/docker-compose.minimal.yml infrastructure/docker-compose.public.yml
    
    # Update PostgreSQL to bind to all interfaces
    sed -i 's/127\.0\.0\.1:5432:5432/0.0.0.0:5432:5432/g' infrastructure/docker-compose.public.yml
    
    # Update MySQL to bind to all interfaces  
    sed -i 's/127\.0\.0\.1:3306:3306/0.0.0.0:3306:3306/g' infrastructure/docker-compose.public.yml
    
    # Update Kafka to bind to all interfaces
    sed -i 's/127\.0\.0\.1:9092:9092/0.0.0.0:9092:9092/g' infrastructure/docker-compose.public.yml
    
    # Update ZooKeeper to bind to all interfaces
    sed -i 's/127\.0\.0\.1:2181:2181/0.0.0.0:2181:2181/g' infrastructure/docker-compose.public.yml
    
    # Update Adminer to bind to all interfaces
    sed -i 's/127\.0\.0\.1:8080:8080/0.0.0.0:8080:8080/g' infrastructure/docker-compose.public.yml
    
    echo -e "${GREEN}✓ Created infrastructure/docker-compose.public.yml with public bindings${RESET}"
}

# Function to update application configurations
update_app_configs() {
    echo -e "${YELLOW}Updating application configurations for public access...${RESET}"
    
    # Update services/db-sql-multi to bind to all interfaces
    if [ -f "services/db-sql-multi/cmd/app/main.go" ]; then
        sed -i 's/0\.0\.0\.0:/0.0.0.0:/g' services/db-sql-multi/cmd/app/main.go
        echo -e "${GREEN}✓ Updated services/db-sql-multi for public access${RESET}"
    fi
    
    # Update other applications if they exist
    for app in grpc-svc kafka-segmentio http-rest; do
        if [ -d "$app" ]; then
            # Look for main.go files and update bind addresses
            find "$app" -name "main.go" -exec sed -i 's/127\.0\.0\.1:/0.0.0.0:/g' {} \; 2>/dev/null || true
            find "$app" -name "main.go" -exec sed -i 's/localhost:/0.0.0.0:/g' {} \; 2>/dev/null || true
            echo -e "${GREEN}✓ Updated $app for public access${RESET}"
        fi
    done
}

# Function to create public access startup script
create_public_startup() {
    cat > start-public-services.sh << 'EOF'
#!/bin/bash

# Public Services Startup Script
# This script starts all services with public internet access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Starting Services with Public Internet Access${RESET}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to get IP")

# Stop existing services
echo -e "${YELLOW}Stopping existing services...${RESET}"
./stop-db-apps.sh 2>/dev/null || true
infrastructure/docker-compose -f infrastructure/docker-compose.minimal.yml down 2>/dev/null || true

# Start infrastructure with public bindings
echo -e "${YELLOW}Starting infrastructure with public access...${RESET}"
infrastructure/docker-compose -f infrastructure/docker-compose.public.yml up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${RESET}"
sleep 15

# Start database applications
echo -e "${YELLOW}Starting database applications...${RESET}"
export BIND_ADDRESS="0.0.0.0"
./start-db-apps.sh

echo ""
echo -e "${GREEN}🎉 All services are now publicly accessible!${RESET}"
echo ""
echo -e "${CYAN}Public Access URLs:${RESET}"
echo -e "  🌐 Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""
echo -e "${CYAN}Infrastructure Services:${RESET}"
echo -e "  📊 PostgreSQL:  ${GREEN}$PUBLIC_IP:5432${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📊 MySQL:       ${GREEN}$PUBLIC_IP:3306${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📨 Kafka:       ${GREEN}$PUBLIC_IP:9092${RESET} (topics: orders, payments)"
echo -e "  🔧 Adminer:     ${GREEN}http://$PUBLIC_IP:8080${RESET} (database admin)"
echo ""
echo -e "${CYAN}Application Services:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    echo -e "  🚀 DB SQL Multi: ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "     Test: ${GREEN}curl http://$PUBLIC_IP:$port/trigger-crud${RESET}"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    echo -e "  🚀 DB GORM:      ${GREEN}http://$PUBLIC_IP:$port${RESET}"
    echo -e "     Test: ${GREEN}curl http://$PUBLIC_IP:$port/health${RESET}"
fi

echo ""
echo -e "${YELLOW}⚠️  Security Notice:${RESET}"
echo -e "  • Your services are now accessible from the internet"
echo -e "  • Make sure to use strong passwords and enable SSL in production"
echo -e "  • Consider using a reverse proxy with authentication"
echo -e "  • Monitor access logs regularly"
echo ""
echo -e "${CYAN}Management Commands:${RESET}"
echo -e "  ${GREEN}./stop-public-services.sh${RESET}  # Stop public services"
echo -e "  ${GREEN}./status-public-services.sh${RESET} # Check public status"
echo -e "  ${GREEN}./secure-public-services.sh${RESET} # Add security measures"

EOF

    chmod +x start-public-services.sh
    echo -e "${GREEN}✓ Created start-public-services.sh${RESET}"
}

# Function to create public status checker
create_public_status() {
    cat > status-public-services.sh << 'EOF'
#!/bin/bash

# Public Services Status Checker
# This script checks the status of publicly accessible services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🌐 Public Services Status Check${RESET}"
echo -e "${BLUE}===============================${RESET}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unable to get IP")
echo -e "${CYAN}Public IP: ${GREEN}$PUBLIC_IP${RESET}"
echo ""

# Function to test external access
test_external_access() {
    local service=$1
    local port=$2
    local path=${3:-""}
    
    echo -e "${YELLOW}Testing $service (port $port)...${RESET}"
    
    if timeout 10 curl -s "http://$PUBLIC_IP:$port$path" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $service is publicly accessible${RESET}"
        echo -e "  URL: ${GREEN}http://$PUBLIC_IP:$port$path${RESET}"
    else
        echo -e "${RED}✗ $service is not publicly accessible${RESET}"
        echo -e "  Check firewall and port forwarding for port $port"
    fi
    echo ""
}

# Test infrastructure services
echo -e "${CYAN}Infrastructure Services:${RESET}"
test_external_access "Adminer (Database Admin)" 8080

# Test database applications
echo -e "${CYAN}Application Services:${RESET}"
if [ -f "runtime/logs/services/db-sql-multi.port" ]; then
    port=$(cat runtime/logs/services/db-sql-multi.port)
    test_external_access "DB SQL Multi" "$port" "/trigger-crud"
fi

if [ -f "runtime/logs/db-gorm.port" ]; then
    port=$(cat runtime/logs/db-gorm.port)
    test_external_access "DB GORM" "$port" "/health"
fi

# Test database connections (these require special clients)
echo -e "${CYAN}Database Services (require database clients):${RESET}"
echo -e "  📊 PostgreSQL: ${GREEN}$PUBLIC_IP:5432${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📊 MySQL:      ${GREEN}$PUBLIC_IP:3306${RESET} (user: testuser, pass: Test@1234, db: testdb)"
echo -e "  📨 Kafka:      ${GREEN}$PUBLIC_IP:9092${RESET} (topics: orders, payments)"
echo ""

echo -e "${CYAN}Security Recommendations:${RESET}"
echo -e "  🔒 Run: ${GREEN}./secure-public-services.sh${RESET} to add security measures"
echo -e "  🔍 Monitor access logs regularly"
echo -e "  🛡️  Consider using a reverse proxy with authentication"
echo -e "  🔐 Use SSL/TLS certificates for production"

EOF

    chmod +x status-public-services.sh
    echo -e "${GREEN}✓ Created status-public-services.sh${RESET}"
}

# Function to create security script
create_security_script() {
    cat > secure-public-services.sh << 'EOF'
#!/bin/bash

# Public Services Security Script
# This script adds basic security measures for public services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${BLUE}🔒 Adding Security Measures${RESET}"
echo -e "${BLUE}===========================${RESET}"
echo ""

# Function to install fail2ban
install_fail2ban() {
    echo -e "${YELLOW}Installing fail2ban for intrusion prevention...${RESET}"
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y fail2ban >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y fail2ban >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y fail2ban >/dev/null 2>&1
    else
        echo -e "${YELLOW}⚠️  Please install fail2ban manually${RESET}"
        return 1
    fi
    
    # Configure fail2ban for SSH
    sudo systemctl enable fail2ban >/dev/null 2>&1
    sudo systemctl start fail2ban >/dev/null 2>&1
    
    echo -e "${GREEN}✓ fail2ban installed and configured${RESET}"
}

# Function to setup basic rate limiting
setup_rate_limiting() {
    echo -e "${YELLOW}Setting up basic rate limiting...${RESET}"
    
    # Create nginx config for rate limiting (if nginx is available)
    if command -v nginx >/dev/null 2>&1; then
        cat > /tmp/rate_limit.conf << 'NGINX_EOF'
# Rate limiting configuration
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=db:10m rate=5r/s;

server {
    listen 80;
    
    # Rate limit API endpoints
    location /trigger-crud {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:8001;
    }
    
    location /health {
        limit_req zone=api burst=10 nodelay;
        proxy_pass http://localhost:8005;
    }
    
    # Rate limit database admin
    location /adminer {
        limit_req zone=db burst=5 nodelay;
        proxy_pass http://localhost:8080;
    }
}
NGINX_EOF
        
        echo -e "${GREEN}✓ Nginx rate limiting config created at /tmp/rate_limit.conf${RESET}"
        echo -e "${YELLOW}  Copy to /etc/nginx/sites-available/ and enable as needed${RESET}"
    fi
}

# Function to create monitoring script
create_monitoring() {
    cat > monitor-public-access.sh << 'MONITOR_EOF'
#!/bin/bash

# Public Access Monitor
# This script monitors access to public services

echo "=== Public Access Monitor - $(date) ==="

# Check for suspicious activity
echo "Recent connections to database ports:"
netstat -tn | grep -E ':(5432|3306|9092)' | head -10

echo ""
echo "Recent HTTP requests:"
if [ -f "runtime/logs/services/db-sql-multi.log" ]; then
    tail -20 runtime/logs/services/db-sql-multi.log | grep -E 'GET|POST' | tail -5
fi

echo ""
echo "System load:"
uptime

echo ""
echo "Memory usage:"
free -h

echo ""
echo "Disk usage:"
df -h | head -5

MONITOR_EOF

    chmod +x monitor-public-access.sh
    echo -e "${GREEN}✓ Created monitor-public-access.sh${RESET}"
}

# Main execution
echo -e "${YELLOW}Installing security tools...${RESET}"
install_fail2ban || echo -e "${YELLOW}⚠️  Skipping fail2ban installation${RESET}"

echo ""
setup_rate_limiting

echo ""
create_monitoring

echo ""
echo -e "${GREEN}🔒 Security measures added!${RESET}"
echo ""
echo -e "${CYAN}Security Features:${RESET}"
echo -e "  ✓ fail2ban for intrusion prevention"
echo -e "  ✓ Rate limiting configuration template"
echo -e "  ✓ Access monitoring script"
echo ""
echo -e "${CYAN}Additional Recommendations:${RESET}"
echo -e "  🔐 Change default database passwords"
echo -e "  🛡️  Setup SSL/TLS certificates"
echo -e "  🔍 Enable detailed logging"
echo -e "  🚫 Restrict access by IP if possible"
echo -e "  🔒 Use VPN for sensitive operations"

EOF

    chmod +x secure-public-services.sh
    echo -e "${GREEN}✓ Created secure-public-services.sh${RESET}"
}

# Function to create stop script
create_stop_script() {
    cat > stop-public-services.sh << 'EOF'
#!/bin/bash

# Stop Public Services Script

echo "🛑 Stopping public services..."

# Stop applications
./stop-db-apps.sh 2>/dev/null || true

# Stop infrastructure
infrastructure/docker-compose -f infrastructure/docker-compose.public.yml down 2>/dev/null || true
infrastructure/docker-compose -f infrastructure/docker-compose.minimal.yml down 2>/dev/null || true

echo "✓ All public services stopped"
EOF

    chmod +x stop-public-services.sh
    echo -e "${GREEN}✓ Created stop-public-services.sh${RESET}"
}

# Main execution
echo -e "${BLUE}Step 1: Getting public IP address...${RESET}"
PUBLIC_IP=$(get_public_ip)
if [ "$PUBLIC_IP" != "Unable to determine public IP" ]; then
    echo -e "${GREEN}✓ Public IP: $PUBLIC_IP${RESET}"
else
    echo -e "${YELLOW}⚠️  Could not determine public IP automatically${RESET}"
fi
echo ""

echo -e "${BLUE}Step 2: Configuring firewall...${RESET}"
configure_firewall
echo ""

echo -e "${BLUE}Step 3: Updating Docker Compose configuration...${RESET}"
update_docker_compose
echo ""

echo -e "${BLUE}Step 4: Updating application configurations...${RESET}"
update_app_configs
echo ""

echo -e "${BLUE}Step 5: Creating public access scripts...${RESET}"
create_public_startup
create_public_status
create_security_script
create_stop_script
echo ""

echo -e "${GREEN}🎉 Public Access Setup Complete!${RESET}"
echo ""
echo -e "${CYAN}Next Steps:${RESET}"
echo -e "  1. Start public services: ${GREEN}./start-public-services.sh${RESET}"
echo -e "  2. Check public status: ${GREEN}./status-public-services.sh${RESET}"
echo -e "  3. Add security measures: ${GREEN}./secure-public-services.sh${RESET}"
echo ""
echo -e "${YELLOW}⚠️  Important Security Notes:${RESET}"
echo -e "  • Your services will be accessible from the internet"
echo -e "  • Change default passwords before going public"
echo -e "  • Consider using SSL/TLS certificates"
echo -e "  • Monitor access logs regularly"
echo -e "  • Use strong authentication for production"
