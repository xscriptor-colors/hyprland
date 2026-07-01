#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# SYSTEM MONITOR DATA FETCHER
# Outputs JSON with CPU, RAM, disk, network, uptime
# ────────────────────────────────────────────────────────────────

CPU=$(top -bn1 2>/dev/null | awk '/^%Cpu/ {print 100 - $8}' || echo 0)
CPU=${CPU%.*}

read -r RAM_TOTAL RAM_USED <<< $(free -m 2>/dev/null | awk '/^Mem:/ {print $2, $3}')
RAM_PCT=$(( RAM_USED * 100 / RAM_TOTAL ))

DISK_DATA=$(df -h / 2>/dev/null | awk 'NR==2 {print $2, $3, $4, $5}')
DISK_TOTAL=$(echo "$DISK_DATA" | awk '{print $1}')
DISK_USED=$(echo "$DISK_DATA" | awk '{print $2}')
DISK_PCT=$(echo "$DISK_DATA" | awk '{print $4}' | tr -d '%')

RX_BYTES=0; TX_BYTES=0
IFACE=$(ip route get 1 2>/dev/null | awk '{print $5; exit}')
if [ -n "$IFACE" ] && [ -d "/sys/class/net/$IFACE" ]; then
    RX_BYTES=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
    TX_BYTES=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
fi

UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
PROC_COUNT=$(ps -e --no-headers 2>/dev/null | wc -l || echo 0)
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
TEMP=$(( TEMP / 1000 ))

echo "{\"cpu\":$CPU,\"ram_pct\":$RAM_PCT,\"ram_used\":$RAM_USED,\"ram_total\":$RAM_TOTAL,\"disk_pct\":$DISK_PCT,\"disk_used\":\"$DISK_USED\",\"disk_total\":\"$DISK_TOTAL\",\"rx_bytes\":$RX_BYTES,\"tx_bytes\":$TX_BYTES,\"uptime\":\"$UPTIME\",\"procs\":$PROC_COUNT,\"temp\":$TEMP,\"iface\":\"${IFACE:-none}\"}"
