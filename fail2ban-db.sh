while true; do
  # Clear the terminal
  clear

  # Display static header
  echo -e "\e[1;44m        List of Banned IPs         \n\e[0m"

  # Fetch dynamic info
  IPs=$(sudo fail2ban-client status sshd | grep "Banned IP list:" | sed 's/.*Banned IP list://g' | tr -s ' ' '\n')
  current_count=$(echo -e "$IPs" | wc -l)
  total_count=$(grep "Ban " /var/log/fail2ban.log | wc -l)

  # Display Currently Banned IPs and Total Banned to Date
  echo -e "\e[1;32m   Currently Banned IPs: $current_count\e[0m"
  echo -e "\e[1;32m   Total Banned to Date: $total_count\n\e[0m"
  

  # Display table headers
  echo -e " ┌─────┬──────────────────────┬────────────────┐"
  echo -e " │ No. │          IP          │    Unban In    │"
  echo -e " ├─────┼──────────────────────┼────────────────┤"

  # Parse each IP and look up its ban time using fail2ban-client
  counter=0
  while read -r ip ban_start plus duration equals unban_time; do
    # Skip empty lines or header lines
    [[ -z "$ip" || "$ip" == "No"* ]] && continue
    
    counter=$((counter + 1))
    
    # Parse duration (in seconds) and convert to days, hours, minutes
    days=$(( duration / 86400 ))
    hours=$(( (duration % 86400) / 3600 ))
    mins=$(( (duration % 3600) / 60 ))
    
    # Build the time left string - always show days, hours, and minutes with fixed width
    time_str=$(printf "%dd %dh %dm" "$days" "$hours" "$mins")
    
    printf " │ %2d  │     %-15s  │  %-12s  │\n" "$counter" "$ip" "$time_str"
    
  done < <(sudo fail2ban-client get sshd banip --with-time)
  
  echo " └─────┴──────────────────────┴────────────────┘"  # Line below each IP
  server_info=""

  for i in {59..0}; do
    if ((counter % 10 == 0)); then
      cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
      cpu_load=$(uptime | awk -F 'load average: ' '{print $2}')
      disk_usage=$(df -h / | awk 'NR==2 {print $5}')
      memory_usage=$(free -m | awk 'NR==2 {print $3 "/" $2 "MB"}')
      logged_users=$(who | awk '{print $1}' | sort -u | wc -l)
      logged_users_list=$(who | awk '{print $1}' | sort | uniq | tr '\n' ', ' | sed 's/,$//')
      cpu_temp_c=$(awk -v temp="$cpu_temp" 'BEGIN{printf "%.1f", temp / 1000}')


      server_info="\e[1;32m\n - Server Info:\n - CPU Load : $cpu_load\n - CPU Temp : $cpu_temp_c °C\n - Disk Usage : $disk_usage\n - Memory Usage : $memory_usage\n - Count of unique logged-in users : $logged_users\n - Logged in as : $logged_users_list\n\e[0m"
    fi

    echo -e "\e[1;32m  Current Time: $(date '+%H:%M:%S')\e[0m"
    echo " ──────────────────────────────────────────"
    echo -e "$server_info"
    echo " ──────────────────────────────────────────"
    counter=$((counter + 1))
    sleep 1

    # Clear the lines for server info and time, but no more than that
    echo -ne "\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A\033[2K\033[A"
  done
done
