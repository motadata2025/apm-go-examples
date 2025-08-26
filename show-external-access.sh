#!/bin/bash

# =============================================================================
# APM Examples - Show External Access Information
# =============================================================================
# Display machine IPs and external access URLs for services
# Run with: ./show-external-access.sh

echo "🌐 APM Examples - External Access Information"
echo "============================================="
echo ""

# Get machine IP addresses
echo "📡 Machine IP Addresses:"
echo ""

# Primary local IP (most likely to work for external access)
LOCAL_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null || echo "127.0.0.1")
echo "Primary Local IP: $LOCAL_IP"

# All network interfaces
echo ""
echo "All Network Interfaces:"
ip addr show | grep -E "inet [0-9]" | grep -v "127.0.0.1" | while read line; do
    interface=$(echo "$line" | awk '{print $NF}')
    ip_addr=$(echo "$line" | awk '{print $2}' | cut -d'/' -f1)
    echo "  $interface: $ip_addr"
done

# Public IP (if available)
echo ""
echo -n "Public IP: "
curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "Not available (behind NAT/firewall)"

echo ""
echo ""

# Service status and external URLs
echo "🔍 Service Status & External URLs:"
echo ""

# Service definitions
PORTS=(8081 8082 8083 8084 50051)
NAMES=("Database" "Kafka Producer" "gRPC HTTP Client" "HTTP REST API" "gRPC Server")
ENDPOINTS=("/trigger-crud" "/trigger-produce" "/trigger-stream" "/trigger/allservices" "grpc")

for i in "${!PORTS[@]}"; do
    port=${PORTS[$i]}
    name=${NAMES[$i]}
    endpoint=${ENDPOINTS[$i]}
    
    # Check if service is running
    if nc -z localhost "$port" 2>/dev/null; then
        status="✅ Running"
        
        # Show external URL
        if [ "$endpoint" = "grpc" ]; then
            echo "  $name: $status"
            echo "    External: grpc://$LOCAL_IP:$port"
            echo "    Test: grpcurl -plaintext $LOCAL_IP:$port list"
        else
            external_url="http://$LOCAL_IP:$port$endpoint"
            echo "  $name: $status"
            echo "    External: $external_url"
            echo "    Test: curl $external_url"
        fi
    else
        echo "  $name: ❌ Not running"
        echo "    Start with: ./quick-start-expert.sh"
    fi
    echo ""
done

echo "🔥 Firewall Configuration (if needed):"
echo ""
echo "Ubuntu/Debian:"
for port in "${PORTS[@]}"; do
    echo "  sudo ufw allow $port"
done

echo ""
echo "CentOS/RHEL:"
for port in "${PORTS[@]}"; do
    echo "  sudo firewall-cmd --permanent --add-port=$port/tcp"
done
echo "  sudo firewall-cmd --reload"

echo ""
echo "✅ Use the external URLs above to test from other machines!"
