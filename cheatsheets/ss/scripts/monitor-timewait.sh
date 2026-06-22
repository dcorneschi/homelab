#!/bin/bash
# Monitor ephemeral port usage every 10 seconds
RANGE=$(sysctl -n net.ipv4.ip_local_port_range | awk '{print $2 - $1}')

while true; do
    TW=$(ss -Htn state time-wait | wc -l)
    TOTAL=$(ss -Htn | wc -l)
    PCT=$((TW * 100 / RANGE))
    echo "$(date +%H:%M:%S) TIME_WAIT: $TW  TOTAL: $TOTAL  Usage: ${PCT}% of $RANGE ports"
    sleep 10
done
