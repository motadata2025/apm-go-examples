#!/bin/bash

# List of services to check
services=("httpRestTest" "client" "server" "producer" "consumer" "db-sql-multi")

echo "=== Checking running services ==="
for svc in "${services[@]}"; do
    echo "--- $svc ---"
    if pgrep -a "$svc" > /dev/null; then
        pgrep -a "$svc"
    else
        echo "$svc not running"
    fi
done

echo ""
echo "=== Checking listening ports (8080-8084, 9092, 50051) ==="
sudo lsof -i -P -n | grep LISTEN | egrep "8080|8081|8082|8083|8084|9092|50051" || echo "No matching services listening on expected ports"
