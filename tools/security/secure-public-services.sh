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
if [ -f "logs/db-sql-multi.log" ]; then
    tail -20 logs/db-sql-multi.log | grep -E 'GET|POST' | tail -5
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

