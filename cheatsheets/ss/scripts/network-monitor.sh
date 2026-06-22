#!/bin/bash
# Simple Linux network monitoring — key things to watch on the network side
# Usage: ./network-monitor.sh [interface]   (default: auto-detect primary)

IFACE="${1:-$(ip route | awk '/default/ {print $5; exit}')}"

echo "=========================================="
echo " Network Monitor — interface: $IFACE"
echo " $(date)"
echo "=========================================="

# --- 1. Packets and bytes in/out (rate over 1 second) ---
echo ""
echo "=== Packets & Bandwidth (per second) ==="
read RX1 TX1 RXP1 TXP1 < <(awk -v i="$IFACE:" '$1==i {gsub(":"," "); print $2, $10, $3, $11}' /proc/net/dev)
sleep 1
read RX2 TX2 RXP2 TXP2 < <(awk -v i="$IFACE:" '$1==i {gsub(":"," "); print $2, $10, $3, $11}' /proc/net/dev)
echo "RX: $(( (RX2-RX1)/1024 )) KB/s   $(( RXP2-RXP1 )) packets/s"
echo "TX: $(( (TX2-TX1)/1024 )) KB/s   $(( TXP2-TXP1 )) packets/s"

# --- 2. Interface errors and drops (cumulative) ---
echo ""
echo "=== Interface Errors & Drops ==="
awk -v i="$IFACE:" '$1==i {gsub(":"," "); printf "RX errors: %s  RX drops: %s\nTX errors: %s  TX drops: %s\n", $4, $5, $12, $13}' /proc/net/dev

# --- 3. TCP connection states ---
echo ""
echo "=== TCP Connection States ==="
ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c | sort -rn

# --- 4. Listening services ---
echo ""
echo "=== Listening Ports ==="
ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | sort -u

# --- 5. TIME_WAIT count (port exhaustion risk) ---
echo ""
echo "=== TIME_WAIT Count ==="
TW=$(ss -Htn state time-wait | wc -l)
RANGE=$(sysctl -n net.ipv4.ip_local_port_range | awk '{print $2 - $1}')
echo "$TW TIME_WAIT sockets ($(( TW * 100 / RANGE ))% of $RANGE ephemeral ports)"

# --- 5b. CLOSE_WAIT count (socket leak indicator) ---
echo ""
echo "=== CLOSE_WAIT (socket leaks) ==="
CW=$(ss -Htn state close-wait | wc -l)
echo "$CW sockets in CLOSE_WAIT"
if [ "$CW" -gt 10 ]; then
    echo "⚠️  High CLOSE_WAIT — app not closing sockets. Top processes:"
    ss -Htnp state close-wait 2>/dev/null | grep -oE 'users:\(\("[^"]+",pid=[0-9]+' \
        | sed 's/users:((//; s/,pid=/ pid /' | sort | uniq -c | sort -rn | head -5
fi

# --- 6. Top 5 remote IP:port + state by connection count ---
echo ""
echo "=== Top 5 Remote Endpoints ==="
printf "%-8s %-24s %s\n" "COUNT" "REMOTE IP:PORT" "STATE"
ss -Htn | awk '{print $5, $1}' | sort | uniq -c | sort -rn | head -5 | \
    awk '{printf "%-8s %-24s %s\n", $1, $2, $3}'

# --- 7. TCP retransmit rate (packet loss indicator) ---
echo ""
echo "=== TCP Retransmits ==="
awk '/^Tcp:/{c++; if(c==2){if($11>0) printf "%.4f%% (%d retrans / %d segments out)\n", $12/$11*100, $12, $11; else print "no segments sent yet"}}' /proc/net/snmp

# --- 8. Conntrack table usage (if loaded) ---
echo ""
echo "=== Conntrack Table ==="
if [ -f /proc/sys/net/netfilter/nf_conntrack_count ]; then
    CT_COUNT=$(cat /proc/sys/net/netfilter/nf_conntrack_count)
    CT_MAX=$(cat /proc/sys/net/netfilter/nf_conntrack_max)
    echo "$CT_COUNT / $CT_MAX ($(( CT_COUNT * 100 / CT_MAX ))% used)"
else
    echo "conntrack not loaded"
fi

# --- 9. Listen queue overflows (connections dropped) ---
echo ""
echo "=== Listen Queue Drops ==="
OVERFLOWS=$(awk '/^TcpExt:/{c++; if(c==2){for(i=1;i<=NF;i++) if(h[i]=="ListenOverflows") print $i}} /^TcpExt:/{if(c==1) for(i=1;i<=NF;i++) h[i]=$i}' /proc/net/netstat)
echo "ListenOverflows: ${OVERFLOWS:-0}  (non-zero = clients being dropped)"

# --- 9b. Live accept-queue depth per listening socket ---
echo ""
echo "=== Listen Accept-Queue Depth ==="
printf "%-8s %-8s %s\n" "RECV-Q" "SEND-Q" "ADDRESS"
ss -Hltn | awk '$2 > 0 {printf "%-8s %-8s %s  ⚠️ pending connections\n", $2, $3, $4}'
ss -Hltn | awk 'END{if(NR==0) print "(no listening sockets)"}'

# --- 10. Socket memory summary ---
echo ""
echo "=== Socket Summary ==="
awk '/TCP:/ {printf "TCP inuse: %s  orphan: %s  tw: %s  mem: %s pages (%d KB)\n", $3, $5, $7, $11, $11*4}' /proc/net/sockstat

# --- 11. UDP receive buffer errors (packets dropped, app too slow) ---
echo ""
echo "=== UDP Buffer Errors ==="
awk '/^Udp:/{c++; if(c==2){for(i=1;i<=NF;i++) if(h[i]=="RcvbufErrors") r=$i; for(i=1;i<=NF;i++) if(h[i]=="SndbufErrors") s=$i; printf "RcvbufErrors: %s  SndbufErrors: %s\n", r, s}} /^Udp:/{if(c==1) for(i=1;i<=NF;i++) h[i]=$i}' /proc/net/snmp

# --- 12. Open file descriptors per process vs limit (connection ceiling) ---
echo ""
echo "=== File Descriptors (top processes vs their limit) ==="
read FD_ALLOC FD_FREE FD_MAX < /proc/sys/fs/file-nr
echo "System-wide: $FD_ALLOC allocated / $FD_MAX max"
echo ""
printf "%-8s %-8s %-8s %s\n" "USED" "LIMIT" "USE%" "PROCESS"
for pid in /proc/[0-9]*; do
    [ -d "$pid/fd" ] || continue
    used=$(ls "$pid/fd" 2>/dev/null | wc -l)
    [ "$used" -eq 0 ] && continue
    limit=$(awk '/Max open files/ {print $4}' "$pid/limits" 2>/dev/null)
    [ -z "$limit" ] && continue
    name=$(tr -d '\0' < "$pid/comm" 2>/dev/null)
    pct=$(( used * 100 / limit ))
    echo "$used $limit $pct $name"
done | sort -k1 -rn | head -5 | awk '{printf "%-8s %-8s %-7s%% %s\n", $1, $2, $3, $4}'

# --- 13. Active packet loss to gateway (10 pkts, 0.2s interval, 1400-byte) ---
echo ""
echo "=== Packet Loss to Gateway ==="
GW=$(ip route | awk '/default/ {print $3; exit}')
if [ -n "$GW" ]; then
    echo "Pinging gateway $GW (10 packets)..."
    ping -c 10 -i 0.2 -s 1400 -q "$GW" | grep -E "packet loss|rtt"
else
    echo "No default gateway found"
fi
