#!/bin/bash
# ./server-stats.sh
# Script to gather and display server performance statistics
# Requires: vmstat, iostat, free, df, uptime
# Usage: ./server-stats.sh

# Function to display CPU usage
display_cpu() {
    echo "==== CPU Usage ===="
    read us sy id < <(
        vmstat 1 2 | tail -1 | awk '{print $13, $14, $15}'
    )

    echo "cpu.user: ${us}%"
    echo "cpu.system: ${sy}%"
    echo "cpu.idle: ${id}%"
    echo
}

# Function to display memory usage
display_memory() {
    echo "==== Memory Usage ===="
    read _ total_hr used_hr free_hr _ < <(free -h | awk 'NR==2')

    read _ total_kb used_kb _ _ < <(free -k | awk 'NR==2')

    usage_pct=$(awk -v u="$used_kb" -v t="$total_kb" \
        'BEGIN { printf "%.2f", (u / t) * 100 }')

    echo "memory.used: ${used_hr}"
    echo "memory.free: ${free_hr}"
    echo "memory.total: ${total_hr}"
    echo "memory.usage_pct: ${usage_pct}%"
    echo
}

# Function to display disk usage
display_disk() {
    echo "==== Disk Usage ===="
    df -h --output=source,size,used,avail,pcent,target | tail -n +2 | while read line; do
        read filesystem size used avail pcent mountpoint <<<"$line"
        echo "disk.filesystem: ${filesystem}"
        echo "disk.size: ${size}"
        echo "disk.used: ${used}"          
        echo "disk.avail: ${avail}"
        echo "disk.usage_pct: ${pcent}"
        echo "disk.mountpoint: ${mountpoint}"
        echo
    done
}

# Function to display top 5 processes by CPU Usage
display_top_processes_by_cpu() {
    echo "==== Top 5 Processes by CPU Usage ===="
    ps -eo pid,pcpu,comm --sort=-pcpu | head -n 6 | tail -n 5
    echo
}

# Function to display top 5 processes by Memory Usage
display_top_processes_by_memory() {
    echo "==== Top 5 Processes by Memory Usage ===="
    ps -eo pid,pmem,comm --sort=-pmem | head -n 6 | tail -n 5
    echo
}  

# Function to display OS Version
display_os_version() {
    echo "==== OS Version ===="
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: $PRETTY_NAME"
    else
        echo "OS information not available."
    fi
    echo
}   

# Function to display system uptime
display_uptime() {
    echo "==== System Uptime ===="
    uptime_info=$(uptime -p)
    echo "uptime: ${uptime_info}"
    echo
}

# Function to display Load Average
display_load_average() {
    echo "==== Load Average ===="
    read one five fifteen < <(uptime | awk -F'load average:' '{print $2}' | tr -d ' ' | tr ',' ' ')
    echo "load_average.1min: ${one}"
    echo "load_average.5min: ${five}"
    echo "load_average.15min: ${fifteen}"
    echo
}

# Function to display Logged In Users
display_logged_in_users() {
    echo "==== Logged In Users ===="
    who | awk '{print $1}' | sort | uniq -c | while read count user; do
        echo "user: ${user}, sessions: ${count}"
    done
    echo
}   

# Function to display Failed Login Attempts
display_failed_logins() {
    echo "==== Failed Login Attempts (last 24 hours) ===="
    lastb -s -1days | awk '{print $1}' | sort | uniq -c | while read count user; do
        if [ "$user" != "wtmp   " ] && [ -n "$user" ]; then
            echo "user: ${user}, failed_attempts: ${count}"
        fi
    done
    echo
}


# Main Execution
display_cpu
display_memory
display_disk
display_uptime
display_top_processes_by_cpu
display_top_processes_by_memory
display_os_version
display_load_average
display_logged_in_users
display_failed_logins