#!/bin/bash

# TaskThief Discovery Module

# Global variables to store discovered jobs
DISCOVERED_CRON_JOBS=()
DISCOVERED_SYSTEMD_TIMERS=()
DISCOVERED_AT_JOBS=()
DISCOVERED_ANACRON_JOBS=()
DISCOVERED_HIDDEN_TASKS=()

# Display discovery menu
function discovery_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}AUTOMATIC DISCOVERY${NC}"
        echo -e "${BLUE}1.${NC} Discover Cron Jobs"
        echo -e "${BLUE}2.${NC} Discover Systemd Timers"
        echo -e "${BLUE}3.${NC} Discover AT Jobs"
        echo -e "${BLUE}4.${NC} Discover Anacron Jobs"
        echo -e "${BLUE}5.${NC} Full Discovery (All Methods)"
        echo -e "${BLUE}6.${NC} View Discovery Results"
        echo -e "${BLUE}b.${NC} Back to Main Menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) discover_cron_jobs ;;
            2) discover_systemd_timers ;;
            3) discover_at_jobs ;;
            4) discover_anacron_jobs ;;
            5) run_full_discovery ;;
            6) view_discovery_results ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Run a full discovery on all schedulers
function run_full_discovery() {
    display_header "FULL DISCOVERY"
    
    echo -e "Starting comprehensive discovery of scheduled tasks..."
    
    # Run all discovery functions
    discover_cron_jobs
    discover_systemd_timers
    discover_at_jobs
    discover_anacron_jobs
    discover_hidden_tasks
    
    echo -e "\n${GREEN}${BOLD}Discovery complete!${NC}"
    echo -e "Found:"
    echo -e "  - ${#DISCOVERED_CRON_JOBS[@]} Cron jobs"
    echo -e "  - ${#DISCOVERED_SYSTEMD_TIMERS[@]} Systemd timers"
    echo -e "  - ${#DISCOVERED_AT_JOBS[@]} AT jobs"
    echo -e "  - ${#DISCOVERED_ANACRON_JOBS[@]} Anacron jobs"
    echo -e "  - ${#DISCOVERED_HIDDEN_TASKS[@]} Hidden tasks"
    echo ""
    
    read -p "Press Enter to continue..." input
}

# View discovery results
function view_discovery_results() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}DISCOVERY RESULTS${NC}"
        echo -e "${BLUE}1.${NC} View Cron Jobs (${#DISCOVERED_CRON_JOBS[@]})"
        echo -e "${BLUE}2.${NC} View Systemd Timers (${#DISCOVERED_SYSTEMD_TIMERS[@]})"
        echo -e "${BLUE}3.${NC} View AT Jobs (${#DISCOVERED_AT_JOBS[@]})"
        echo -e "${BLUE}4.${NC} View Anacron Jobs (${#DISCOVERED_ANACRON_JOBS[@]})"
        echo -e "${BLUE}5.${NC} View Hidden Tasks (${#DISCOVERED_HIDDEN_TASKS[@]})"
        echo -e "${BLUE}6.${NC} Export Results to File"
        echo -e "${BLUE}b.${NC} Back"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) view_cron_jobs ;;
            2) view_systemd_timers ;;
            3) view_at_jobs ;;
            4) view_anacron_jobs ;;
            5) view_hidden_tasks ;;
            6) export_discovery_results ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Discover cron jobs
function discover_cron_jobs() {
    display_header "DISCOVERING CRON JOBS"
    
    # Clear previous results
    DISCOVERED_CRON_JOBS=()
    
    echo -e "Checking system crontabs..."
    
    # Check system-wide crontab
    if [ -f /etc/crontab ]; then
        status_message "Found system crontab" "info"
        local system_cron_content=$(cat /etc/crontab)
        DISCOVERED_CRON_JOBS+=("System crontab|System|$(echo "$system_cron_content" | grep -v "^#" | grep -v "^$" | wc -l) entries")
    else
        status_message "System crontab not found" "warning"
    fi
    
    # Check cron.d directory
    echo -e "\nChecking /etc/cron.d directory..."
    if [ -d /etc/cron.d ]; then
        for cron_file in /etc/cron.d/*; do
            if [ -f "$cron_file" ]; then
                local entries=$(cat "$cron_file" | grep -v "^#" | grep -v "^$" | wc -l)
                DISCOVERED_CRON_JOBS+=("$cron_file|System|$entries entries")
                status_message "Found cron file: $cron_file ($entries entries)" "info"
            fi
        done
    else
        status_message "/etc/cron.d directory not found" "warning"
    fi
    
    # Check user crontabs
    echo -e "\nChecking user crontabs..."
    if [ -d /var/spool/cron/crontabs ]; then
        for user_cron in /var/spool/cron/crontabs/*; do
            if [ -f "$user_cron" ]; then
                local user=$(basename "$user_cron")
                local entries=$(cat "$user_cron" | grep -v "^#" | grep -v "^$" | wc -l)
                DISCOVERED_CRON_JOBS+=("$user_cron|$user|$entries entries")
                status_message "Found crontab for user: $user ($entries entries)" "info"
            fi
        done
    elif [ -d /var/spool/cron ]; then
        # Some systems use /var/spool/cron instead
        for user_cron in /var/spool/cron/*; do
            if [ -f "$user_cron" ]; then
                local user=$(basename "$user_cron")
                local entries=$(cat "$user_cron" | grep -v "^#" | grep -v "^$" | wc -l)
                DISCOVERED_CRON_JOBS+=("$user_cron|$user|$entries entries")
                status_message "Found crontab for user: $user ($entries entries)" "info"
            fi
        done
    else
        status_message "User crontabs directory not found" "warning"
    fi
    
    # Check hourly/daily/weekly/monthly directories
    echo -e "\nChecking periodic directories..."
    local periodic_dirs=("/etc/cron.hourly" "/etc/cron.daily" "/etc/cron.weekly" "/etc/cron.monthly")
    
    for dir in "${periodic_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local count=0
            for script in "$dir"/*; do
                if [ -f "$script" ] && [ -x "$script" ]; then
                    count=$((count + 1))
                    DISCOVERED_CRON_JOBS+=("$script|System|$(basename "$dir")")
                fi
            done
            status_message "Found $count scripts in $dir" "info"
        else
            status_message "$dir directory not found" "warning"
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}Cron job discovery complete!${NC}"
    echo -e "Found ${#DISCOVERED_CRON_JOBS[@]} cron jobs in total."
    echo ""
    
    read -p "Press Enter to continue..." input
}

# Discover systemd timers
function discover_systemd_timers() {
    display_header "DISCOVERING SYSTEMD TIMERS"
    
    # Clear previous results
    DISCOVERED_SYSTEMD_TIMERS=()
    
    if command_exists systemctl; then
        echo -e "Checking systemd timers..."
        
        # List all timers
        local timers_output=$(systemctl list-timers --all 2>/dev/null)
        
        if [ -n "$timers_output" ]; then
            # Parse the output
            local timer_count=$(echo "$timers_output" | grep -v "^NEXT\|^$" | wc -l)
            
            # Add to discovered timers
            while IFS= read -r line; do
                if [[ ! "$line" =~ ^NEXT|^$ ]]; then
                    local timer_name=$(echo "$line" | awk '{print $5}')
                    local next_run=$(echo "$line" | awk '{print $1, $2, $3}')
                    
                    if [ -n "$timer_name" ]; then
                        # Get the service file path
                        local service_path=$(systemctl show "$timer_name" -p FragmentPath 2>/dev/null | cut -d= -f2)
                        
                        # Get additional timer information
                        local description=$(systemctl show "$timer_name" -p Description 2>/dev/null | cut -d= -f2)
                        local unit_file_state=$(systemctl show "$timer_name" -p UnitFileState 2>/dev/null | cut -d= -f2)
                        local active_state=$(systemctl show "$timer_name" -p ActiveState 2>/dev/null | cut -d= -f2)
                        local trigger=$(systemctl show "$timer_name" -p TimersMonotonic 2>/dev/null | cut -d= -f2-)
                        
                        DISCOVERED_SYSTEMD_TIMERS+=("$timer_name|$next_run|$service_path|$description|$unit_file_state|$active_state|$trigger")
                        status_message "Found timer: $timer_name (Next run: $next_run)" "info"
                        
                        if $VERBOSE_MODE; then
                            echo -e "  Description: $description"
                            echo -e "  State: $active_state ($unit_file_state)"
                            echo -e "  Service path: $service_path"
                        fi
                    fi
                fi
            done <<< "$timers_output"
            
            echo -e "\n${GREEN}${BOLD}Systemd timer discovery complete!${NC}"
            echo -e "Found $timer_count systemd timers in total."
        else
            status_message "No systemd timers found" "warning"
        fi
    else
        status_message "systemctl command not found. Systemd may not be installed." "error"
    fi
    
    echo ""
    read -p "Press Enter to continue..." input
}

# Discover AT jobs
function discover_at_jobs() {
    display_header "DISCOVERING AT JOBS"
    
    # Clear previous results
    DISCOVERED_AT_JOBS=()
    
    if command_exists atq; then
        echo -e "Checking AT jobs..."
        
        # Get the list of AT jobs
        local at_jobs=$(atq 2>/dev/null)
        
        if [ -n "$at_jobs" ]; then
            local job_count=$(echo "$at_jobs" | wc -l)
            
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    local job_id=$(echo "$line" | awk '{print $1}')
                    local job_time=$(echo "$line" | awk '{$1=""; print $0}')
                    
                    DISCOVERED_AT_JOBS+=("$job_id|$job_time")
                    status_message "Found AT job: $job_id (Scheduled: $job_time)" "info"
                fi
            done <<< "$at_jobs"
            
            echo -e "\n${GREEN}${BOLD}AT job discovery complete!${NC}"
            echo -e "Found $job_count AT jobs in total."
        else
            status_message "No AT jobs found" "warning"
        fi
    else
        status_message "atq command not found. AT job scheduler may not be installed." "error"
    fi
    
    echo ""
    read -p "Press Enter to continue..." input
}

# Discover Anacron jobs
function discover_anacron_jobs() {
    display_header "DISCOVERING ANACRON JOBS"
    
    # Clear previous results
    DISCOVERED_ANACRON_JOBS=()
    
    echo -e "Checking anacrontab..."
    
    # Check if anacrontab exists
    if [ -f /etc/anacrontab ]; then
        local anacron_content=$(cat /etc/anacrontab)
        local job_count=$(echo "$anacron_content" | grep -v "^#" | grep -v "^$" | grep -v "^START_HOURS" | grep -v "^RANDOM_DELAY" | wc -l)
        
        DISCOVERED_ANACRON_JOBS+=("System Anacrontab|System|$job_count entries")
        status_message "Found anacrontab with $job_count entries" "info"
        
        # Parse the anacrontab
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^#|^$|^START_HOURS|^RANDOM_DELAY ]]; then
                local period=$(echo "$line" | awk '{print $1}')
                local delay=$(echo "$line" | awk '{print $2}')
                local job_id=$(echo "$line" | awk '{print $3}')
                local command=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^ *//')
                
                DISCOVERED_ANACRON_JOBS+=("$job_id|$period|$delay|$command")
                status_message "Found Anacron job: $job_id (Period: $period days, Delay: $delay min)" "info"
            fi
        done <<< "$anacron_content"
        
        echo -e "\n${GREEN}${BOLD}Anacron job discovery complete!${NC}"
    else
        status_message "Anacrontab not found" "warning"
    fi
    
    echo ""
    read -p "Press Enter to continue..." input
}

# View discovered cron jobs
function view_cron_jobs() {
    display_header "CRON JOBS"
    
    if [ ${#DISCOVERED_CRON_JOBS[@]} -eq 0 ]; then
        status_message "No cron jobs discovered yet. Run discovery first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#DISCOVERED_CRON_JOBS[@]} cron jobs:${NC}\n"
    
    # Table header
    printf "%-40s %-15s %-25s\n" "Location" "Owner" "Details"
    echo "--------------------------------------------------------------------------------"
    
    # Table content
    for job in "${DISCOVERED_CRON_JOBS[@]}"; do
        IFS='|' read -r location owner details <<< "$job"
        printf "%-40s %-15s %-25s\n" "$location" "$owner" "$details"
    done
    
    echo ""
    read -p "Press Enter to continue..." input
}

# View discovered systemd timers
function view_systemd_timers() {
    display_header "SYSTEMD TIMERS"
    
    if [ ${#DISCOVERED_SYSTEMD_TIMERS[@]} -eq 0 ]; then
        status_message "No systemd timers discovered yet. Run discovery first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#DISCOVERED_SYSTEMD_TIMERS[@]} systemd timers:${NC}\n"
    
    # Ask user for display option
    echo -e "Display options:"
    echo -e "1. Basic information"
    echo -e "2. Detailed information"
    echo -e ""
    read -p "Select display option [1-2]: " display_option
    
    case "$display_option" in
        2)
            # Detailed view - use a loop to show each timer with full details
            for i in "${!DISCOVERED_SYSTEMD_TIMERS[@]}"; do
                local timer="${DISCOVERED_SYSTEMD_TIMERS[$i]}"
                IFS='|' read -r name next_run path description state active_state trigger <<< "$timer"
                
                echo -e "\n${BLUE}${BOLD}[$((i+1))] ${name}${NC}"
                echo -e "  ${YELLOW}Description:${NC} $description"
                echo -e "  ${YELLOW}Next Run:${NC} $next_run"
                echo -e "  ${YELLOW}State:${NC} $active_state ($state)"
                echo -e "  ${YELLOW}Service Path:${NC} $path"
                echo -e "  ${YELLOW}Trigger:${NC} $trigger"
                
                # Check service file if it exists
                if [ -f "$path" ]; then
                    echo -e "  ${YELLOW}Service File Contents:${NC}"
                    local content=$(cat "$path" 2>/dev/null | grep -v "^#" | grep -v "^$")
                    echo "$content" | sed 's/^/    /'
                fi
                
                echo -e "  ${BLUE}-------------------------------------------------------${NC}"
            done
            ;;
        *)
            # Basic view - show as table
            printf "%-30s %-30s %-20s %-20s\n" "Timer Name" "Next Run" "State" "Description" 
            echo "-------------------------------------------------------------------------------------------------"
            
            for timer in "${DISCOVERED_SYSTEMD_TIMERS[@]}"; do
                IFS='|' read -r name next_run path description state active_state trigger <<< "$timer"
                printf "%-30s %-30s %-20s %-20s\n" "$name" "$next_run" "$active_state" "$description"
            done
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..." input
}

# View discovered AT jobs
function view_at_jobs() {
    display_header "AT JOBS"
    
    if [ ${#DISCOVERED_AT_JOBS[@]} -eq 0 ]; then
        status_message "No AT jobs discovered yet. Run discovery first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#DISCOVERED_AT_JOBS[@]} AT jobs:${NC}\n"
    
    # Table header
    printf "%-10s %-60s\n" "Job ID" "Scheduled Time"
    echo "--------------------------------------------------------------------------------"
    
    # Table content
    for job in "${DISCOVERED_AT_JOBS[@]}"; do
        IFS='|' read -r id scheduled <<< "$job"
        printf "%-10s %-60s\n" "$id" "$scheduled"
    done
    
    echo ""
    read -p "Press Enter to continue..." input
}

# View discovered Anacron jobs
function view_anacron_jobs() {
    display_header "ANACRON JOBS"
    
    if [ ${#DISCOVERED_ANACRON_JOBS[@]} -eq 0 ]; then
        status_message "No Anacron jobs discovered yet. Run discovery first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#DISCOVERED_ANACRON_JOBS[@]} Anacron jobs:${NC}\n"
    
    # Table header
    printf "%-20s %-15s %-15s %-50s\n" "Job ID" "Period (days)" "Delay (min)" "Command"
    echo "--------------------------------------------------------------------------------"
    
    # Table content
    for job in "${DISCOVERED_ANACRON_JOBS[@]}"; do
        if [[ "$job" == *"|"*"|"*"|"* ]]; then
            IFS='|' read -r id period delay command <<< "$job"
            printf "%-20s %-15s %-15s %-50s\n" "$id" "$period" "$delay" "$command"
        else
            IFS='|' read -r location owner details <<< "$job"
            printf "%-20s %-15s %-15s %-50s\n" "$location" "$owner" "$details" ""
        fi
    done
    
    echo ""
    read -p "Press Enter to continue..." input
}

# Export discovery results to file
function export_discovery_results() {
    local report_file="$REPORT_PATH/discovery_report_$(get_date).txt"
    
    display_header "EXPORTING DISCOVERY RESULTS"
    
    echo -e "Exporting results to $report_file"
    
    # Create report header
    cat > "$report_file" << EOF
================================
TaskThief Discovery Report
================================
Generated: $(get_timestamp)
Hostname: $(get_hostname)
Distribution: $(check_distribution)
Kernel: $(get_kernel_version)
User: $(get_current_user)
================================

EOF
    
    # Add cron jobs
    cat >> "$report_file" << EOF
CRON JOBS
================================
Total: ${#DISCOVERED_CRON_JOBS[@]}

EOF
    
    if [ ${#DISCOVERED_CRON_JOBS[@]} -gt 0 ]; then
        printf "%-40s %-15s %-25s\n" "Location" "Owner" "Details" >> "$report_file"
        echo "--------------------------------------------------------------------------------" >> "$report_file"
        
        for job in "${DISCOVERED_CRON_JOBS[@]}"; do
            IFS='|' read -r location owner details <<< "$job"
            printf "%-40s %-15s %-25s\n" "$location" "$owner" "$details" >> "$report_file"
        done
    else
        echo "No cron jobs discovered." >> "$report_file"
    fi
    
    # Add systemd timers
    cat >> "$report_file" << EOF

SYSTEMD TIMERS
================================
Total: ${#DISCOVERED_SYSTEMD_TIMERS[@]}

EOF
    
    if [ ${#DISCOVERED_SYSTEMD_TIMERS[@]} -gt 0 ]; then
        printf "%-30s %-30s %-40s\n" "Timer Name" "Next Run" "Service Path" >> "$report_file"
        echo "--------------------------------------------------------------------------------" >> "$report_file"
        
        for timer in "${DISCOVERED_SYSTEMD_TIMERS[@]}"; do
            IFS='|' read -r name next_run path <<< "$timer"
            printf "%-30s %-30s %-40s\n" "$name" "$next_run" "$path" >> "$report_file"
        done
    else
        echo "No systemd timers discovered." >> "$report_file"
    fi
    
    # Add AT jobs
    cat >> "$report_file" << EOF

AT JOBS
================================
Total: ${#DISCOVERED_AT_JOBS[@]}

EOF
    
    if [ ${#DISCOVERED_AT_JOBS[@]} -gt 0 ]; then
        printf "%-10s %-60s\n" "Job ID" "Scheduled Time" >> "$report_file"
        echo "--------------------------------------------------------------------------------" >> "$report_file"
        
        for job in "${DISCOVERED_AT_JOBS[@]}"; do
            IFS='|' read -r id scheduled <<< "$job"
            printf "%-10s %-60s\n" "$id" "$scheduled" >> "$report_file"
        done
    else
        echo "No AT jobs discovered." >> "$report_file"
    fi
    
    # Add Anacron jobs
    cat >> "$report_file" << EOF

ANACRON JOBS
================================
Total: ${#DISCOVERED_ANACRON_JOBS[@]}

EOF
    
    if [ ${#DISCOVERED_ANACRON_JOBS[@]} -gt 0 ]; then
        printf "%-20s %-15s %-15s %-50s\n" "Job ID" "Period (days)" "Delay (min)" "Command" >> "$report_file"
        echo "--------------------------------------------------------------------------------" >> "$report_file"
        
        for job in "${DISCOVERED_ANACRON_JOBS[@]}"; do
            if [[ "$job" == *"|"*"|"*"|"* ]]; then
                IFS='|' read -r id period delay command <<< "$job"
                printf "%-20s %-15s %-15s %-50s\n" "$id" "$period" "$delay" "$command" >> "$report_file"
            else
                IFS='|' read -r location owner details <<< "$job"
                printf "%-20s %-15s %-15s %-50s\n" "$location" "$owner" "$details" "" >> "$report_file"
            fi
        done
    else
        echo "No Anacron jobs discovered." >> "$report_file"
    fi
    
    # Final footer
    cat >> "$report_file" << EOF

================================
End of Report
================================
EOF
    
    status_message "Report saved to $report_file" "success"
    echo ""
    
    if confirm_action "Would you like to view the report now?"; then
        less "$report_file"
    fi
    
    read -p "Press Enter to continue..." input
}

# Add function to view hidden tasks
function view_hidden_tasks() {
    display_header "HIDDEN TASKS"
    
    if [ ${#DISCOVERED_HIDDEN_TASKS[@]} -eq 0 ]; then
        status_message "No hidden tasks discovered yet. Run discovery first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#DISCOVERED_HIDDEN_TASKS[@]} hidden tasks:${NC}\n"
    
    # Table header
    printf "%-15s %-45s %-40s\n" "Type" "Location" "Details"
    echo "--------------------------------------------------------------------------------"
    
    # Table content
    for task in "${DISCOVERED_HIDDEN_TASKS[@]}"; do
        IFS='|' read -r type location details extra <<< "$task"
        printf "%-15s %-45s %-40s\n" "$type" "$(basename "$location")" "$details"
        
        if [ -n "$extra" ]; then
            printf "%-15s %-45s %-40s\n" "" "" "$extra"
        fi
    done
    
    echo ""
    read -p "Press Enter to continue..." input
}

# Add this function after the discover_anacron_jobs function
function discover_hidden_tasks() {
    display_header "DISCOVERING HIDDEN SCHEDULED TASKS"
    
    echo -e "Searching for hidden or non-standard task schedulers..."
    local hidden_count=0
    local hidden_tasks=()
    
    # Check if incron is installed
    if command_exists incrontab; then
        status_message "Checking for incron tasks (inotify cron)" "info"
        
        # Check system-wide incrontab
        if [ -f /etc/incron.d ]; then
            for incron_file in /etc/incron.d/*; do
                if [ -f "$incron_file" ]; then
                    hidden_count=$((hidden_count + 1))
                    hidden_tasks+=("incron|$incron_file|System-wide incron task")
                    status_message "Found system incron file: $incron_file" "info"
                fi
            done
        fi
        
        # Check user incrontabs
        if [ -d /var/spool/incron ]; then
            for user_incron in /var/spool/incron/*; do
                if [ -f "$user_incron" ]; then
                    local user=$(basename "$user_incron")
                    hidden_count=$((hidden_count + 1))
                    hidden_tasks+=("incron|$user_incron|User incron task for $user")
                    status_message "Found user incron file: $user_incron" "info"
                fi
            done
        fi
    fi
    
    # Check for fcron
    if command_exists fcrontab; then
        status_message "Checking for fcron tasks" "info"
        
        # Check fcrontab directory
        if [ -d /var/spool/fcron ]; then
            for fcron_file in /var/spool/fcron/*; do
                if [ -f "$fcron_file" ]; then
                    hidden_count=$((hidden_count + 1))
                    hidden_tasks+=("fcron|$fcron_file|Fcron task")
                    status_message "Found fcron file: $fcron_file" "info"
                fi
            done
        fi
    fi
    
    # Check for systemd path units
    if command_exists systemctl; then
        status_message "Checking for systemd path units (file triggers)" "info"
        
        local path_units=$(systemctl list-units --type=path --all 2>/dev/null | grep "\.path" | awk '{print $1}')
        
        if [ -n "$path_units" ]; then
            while IFS= read -r unit; do
                if [ -n "$unit" ]; then
                    local unit_file=$(systemctl show "$unit" -p FragmentPath 2>/dev/null | cut -d= -f2)
                    local description=$(systemctl show "$unit" -p Description 2>/dev/null | cut -d= -f2)
                    
                    hidden_count=$((hidden_count + 1))
                    hidden_tasks+=("systemd-path|$unit|$description|$unit_file")
                    status_message "Found systemd path unit: $unit ($description)" "info"
                fi
            done <<< "$path_units"
        fi
    fi
    
    # Check for LUKS header hooks
    if [ -d /etc/cryptsetup-initramfs/hooks ]; then
        status_message "Checking for LUKS hooks (executed at boot)" "info"
        
        for hook in /etc/cryptsetup-initramfs/hooks/*; do
            if [ -f "$hook" ] && [ -x "$hook" ]; then
                hidden_count=$((hidden_count + 1))
                hidden_tasks+=("luks-hook|$hook|Executed during boot")
                status_message "Found LUKS hook: $hook" "info"
            fi
        done
    fi
    
    # Check for udev rules that run scripts
    if [ -d /etc/udev/rules.d ]; then
        status_message "Checking for udev rules that execute commands" "info"
        
        for rule_file in /etc/udev/rules.d/*.rules; do
            if [ -f "$rule_file" ]; then
                # Check if the rule contains RUN or PROGRAM keywords
                if grep -q "RUN\|PROGRAM" "$rule_file" 2>/dev/null; then
                    hidden_count=$((hidden_count + 1))
                    hidden_tasks+=("udev-rule|$rule_file|Executes on device events")
                    status_message "Found udev rule with command execution: $rule_file" "info"
                fi
            fi
        done
    fi
    
    # Check for startup scripts (.desktop files)
    if [ -d /etc/xdg/autostart ] || [ -d ~/.config/autostart ]; then
        status_message "Checking for desktop environment autostart entries" "info"
        
        # System-wide
        for desktop_file in /etc/xdg/autostart/*.desktop; do
            if [ -f "$desktop_file" ]; then
                hidden_count=$((hidden_count + 1))
                hidden_tasks+=("autostart|$desktop_file|System-wide autostart entry")
                status_message "Found system autostart entry: $desktop_file" "info"
            fi
        done
        
        # User-specific
        for desktop_file in ~/.config/autostart/*.desktop; do
            if [ -f "$desktop_file" ]; then
                hidden_count=$((hidden_count + 1))
                hidden_tasks+=("autostart|$desktop_file|User autostart entry")
                status_message "Found user autostart entry: $desktop_file" "info"
            fi
        done
    fi
    
    # Store the results globally
    DISCOVERED_HIDDEN_TASKS=("${hidden_tasks[@]}")
    
    echo -e "\n${GREEN}${BOLD}Hidden task discovery complete!${NC}"
    echo -e "Found $hidden_count hidden or non-standard scheduled tasks."
    echo ""
    
    read -p "Press Enter to continue..." input
} 