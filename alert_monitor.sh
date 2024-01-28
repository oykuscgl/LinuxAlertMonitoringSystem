#!/bin/bash

# Telegram Bot Token
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

# Thresholds (adjust as needed)
CPU_THRESHOLD=94
MEMORY_THRESHOLD=90
DISK_THRESHOLD=92

# Function to send message via Telegram bot
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message"
}

# Function to check CPU usage
check_cpu() {

    local cpu_usage=$(grep "%CPU(s):" | awk '{print 100 - $NF}')
    if (( $(echo "$cpu_usage >= $CPU_THRESHOLD" | bc -l) )); then
        send_telegram_message "⚠️ High CPU Usage: $cpu_usage%"
    fi
}

# Function to check Memory usage
check_memory() {
    
    local memory_usage=$(free | grep Mem | awk '{print ($3/$2)*100}')
    if (( $(echo "$memory_usage >= $MEMORY_THRESHOLD" | bc -l) )); then
        send_telegram_message "⚠️ High Memory Usage: $memory_usage%"
    fi
}

# Function to check Disk usage
check_disk() {
    local disk_usage=$(df -h | grep /dev/sda1 | awk '{print $5}' | cut -d'%' -f1)
    if (( $(echo "$disk_usage >= $DISK_THRESHOLD" | bc -l) )); then
        send_telegram_message "⚠️ High Disk Usage: $disk_usage%"
    fi
}

# Main function
main() {
    while true; do
        stress --cpu 1 &
        check_cpu

        stress --vm 8 &
        check_memory

        cd /khas
        stress --hdd 4 -hdd-bytes 4G &
        check_disk

        sleep 300  # Check every 5 minutes (adjust as needed)
    done
}

# Run the monitoring script
main
