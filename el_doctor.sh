source /mnt/d/CyberSec/Linux/bashsimplecurses/simple_curses.sh

ascii_art=$(<assets/header.txt) 
alert_email="aTestEmail225@gmail.com"
high_load_threshold=0.75
critical_path="/var/log/auth.log"
failed_login_threshold=3


send_alert() {
    local subject="$1"
    local message="$2"
    echo "$message" | mail -s "$subject" "$alert_email"
}

log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> $critical_path 
}

monitor_failed_logins() {
    local failed_attempts=$(grep 'Failed password' /var/log/auth.log | wc -l)
    
    if [ "$failed_attempts" -ge "$failed_login_threshold" ]; then
        send_alert "Failed Login Alert" "Alert: There have been $failed_attempts failed login attempts."
        log_message "Failed login alert sent."
    fi
}

monitor_file_changes() {
    inotifywait -m -r -e modify,create,delete --format '%w%f' "$critical_path" | while read file; do
        send_alert "File Change Alert" "Change detected in $file"
        log_message "File change alert sent for $file."
    done
}


draw_horizontal_bar() {
    local value=$1
    local filled_length=$((value * max_width / 100))
    local unfilled_length=$((max_width - filled_length))
    local bar=$(printf '%0.s▮' $(seq 1 $filled_length))
    local empty=$(printf '%0.s-' $(seq 1 $unfilled_length))
    printf "%s%s %d%%\n" "$bar" "$empty" "$value"
}


system_info() {
    local hostname=$(hostname)
    local os=$(lsb_release -d | cut -f2)
    local kernel=$(uname -r)
    local uptime=$(uptime -p | cut -d ' ' -f2-)
 

    window "System Information" "green" "48%"
        append "Hostname: $hostname"
        append "OS: $os"
        append "Kernel: $kernel"
        append "Uptime: $uptime"

    endwin
}


ip_info() {
    local ip=$(hostname -I | awk '{print $1}')
    local dns=$(hostname -d)
    local mask=$(ifconfig | grep 'inet ' | awk '{print $2}' | head -1)
    local gateway=$(ip route | grep 'default' | awk '{print $3}')

    window "IP Information" "green" "48%"
    append "IP Address: $ip"
    append "DNS Domain: $dns"
    append "Subnet Mask: $mask"
    append "Gateway: $gateway"
    endwin
}

memory_usage() {
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local used_mem=$(free -m | awk '/^Mem:/{print $3}')
    local free_mem=$(free -m | awk '/^Mem:/{print $4}')

    window "Memory Usage" "red" "48%"
    append "Total: ${total_mem}MB"
    append "Used: ${used_mem}MB"
    append "Free: ${free_mem}MB" 
    append "Usage: $(echo "scale=2; $used_mem / $total_mem * 100" | bc)%"

    endwin
}


disk_usage() {
    local disk_usage=$(df -h / | awk '/\//{print $5}')
    local max_width=50

    window "Disk Usage" "yellow" "48%"
    append "Usage: $disk_usage"
    draw_horizontal_bar $disk_usage
    endwin
}


cpu_load() {
    local load=$(top -bn1 | grep "load average:" | awk '{print $10 $11 $12}')

    window "CPU Load" "blue" "48%"
    append "Load Average: $load"
    endwin

     local current_load=$(echo $load | awk '{print $1}')  
      if (( $(echo "$current_load > $high_load_threshold" |bc -l) )); then
        send_alert "High CPU Load Alert" "CPU Load is high: $load"
    fi
}

user() {
    local users=$(whoami| awk '{print $1, $2, $3, $4, $5}')

    window "Current Users" "magenta" "48%"
    append "$users"
    endwin
}

network_usage() {
    local rx=$(ifconfig | grep 'RX packets' | awk '{print $5}')
    local tx=$(ifconfig | grep 'TX packets' | awk '{print $5}')
    
    window "Network Usage" "cyan" "48%"
    append "Received: $rx bytes"
    append "Transmitted: $tx bytes"
    endwin
}

disk_io() {
    local io_stats=$(iostat | grep 'avg-cpu' -A 1 | tail -n 1)
    
    window "Disk I/O" "purple" "48%"
    append "$io_stats"
    endwin
}

process_stats() {
    local top_processes=$(ps -eo pcpu,pid,user,args | sort -k 1 -r | head -5)
    
    window "Process Stats (Top CPU)" "blue" "48%"
    append "$top_processes"
    endwin
}

processes_running() {
    local processes=$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 10)
    
    window "Processes Running" "blue" "48%"
    append "$processes"
    endwin
}

last_commands() {
    local last=$(history | tail -n 5)
    
    window "Last Commands" "blue" "48%"
    append "$last"
    endwin
}


main() {
    clear  
    
    echo "$ascii_art"
    
    window "Welcome to El-Doctor - System Monitoring Dashboard" "green" "48%"
    append "Current Time: $(date '+%Y-%m-%d %H:%M:%S')"
    endwin
     
    system_info
    memory_usage
    network_usage
    disk_usage
    ip_info
    cpu_load
    user
    disk_io
    process_stats
    processes_running
    last_commands

    }

 
main_loop 