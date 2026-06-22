#!/bin/bash
# Real-time network throughput — packets/s and bandwidth per interface
# Usage: ./net-realtime.sh [interface] [interval]
#   interface: default = auto-detect primary
#   interval:  refresh seconds (default 1)

IFACE="${1:-$(ip route | awk '/default/ {print $5; exit}')}"
INTERVAL="${2:-1}"

if [ ! -d "/sys/class/net/$IFACE" ]; then
    echo "Interface '$IFACE' not found. Available:"
    ls /sys/class/net/
    exit 1
fi

# Read counters for the interface
read_stats() {
    awk -v i="$IFACE:" '$1==i {gsub(":"," "); print $2, $3, $10, $11}' /proc/net/dev
}

echo "Monitoring $IFACE (refresh ${INTERVAL}s) — press Ctrl+C to stop"
printf "%-10s %12s %12s %12s %12s\n" "TIME" "RX KB/s" "RX pkt/s" "TX KB/s" "TX pkt/s"

read RXB1 RXP1 TXB1 TXP1 < <(read_stats)
while true; do
    sleep "$INTERVAL"
    read RXB2 RXP2 TXB2 TXP2 < <(read_stats)

    RX_KB=$(( (RXB2 - RXB1) / 1024 / INTERVAL ))
    TX_KB=$(( (TXB2 - TXB1) / 1024 / INTERVAL ))
    RX_PKT=$(( (RXP2 - RXP1) / INTERVAL ))
    TX_PKT=$(( (TXP2 - TXP1) / INTERVAL ))

    printf "%-10s %12s %12s %12s %12s\n" "$(date +%H:%M:%S)" "$RX_KB" "$RX_PKT" "$TX_KB" "$TX_PKT"

    RXB1=$RXB2; RXP1=$RXP2; TXB1=$TXB2; TXP1=$TXP2
done
