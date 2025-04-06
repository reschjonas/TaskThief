#!/bin/bash

# TaskThief Manipulation Module

# Global variables to store manipulation results
MANIPULATION_RESULTS=()
SUCCESSFUL_MANIPULATIONS=()

# Display manipulation menu
function manipulation_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}TASK MANIPULATION${NC}"
        echo -e "${BLUE}1.${NC} Test Cron Job Hijacking"
        echo -e "${BLUE}2.${NC} Test Systemd Timer Manipulation"
        echo -e "${BLUE}3.${NC} Test AT Job Manipulation"
        echo -e "${BLUE}4.${NC} Create Persistent Backdoor Task"
        echo -e "${BLUE}5.${NC} View Manipulation Results"
        echo -e "${BLUE}6.${NC} Restore Original Files (Cleanup)"
        echo -e "${BLUE}b.${NC} Back to Main Menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) test_cron_hijacking ;;
            2) test_systemd_manipulation ;;
            3) test_at_manipulation ;;
            4) create_backdoor_task ;;
            5) view_manipulation_results ;;
            6) restore_original_files ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Test cron job hijacking
function test_cron_hijacking() {
    display_header "TESTING CRON JOB HIJACKING"
    
    # Check if discovery has been run
    if [ ${#DISCOVERED_CRON_JOBS[@]} -eq 0 ]; then
        status_message "No cron jobs discovered yet. Running discovery first..." "info"
        discover_cron_jobs
    fi
    
    # Create a directory to store original files for restoration
    local backup_dir="$SCRIPT_DIR/config/backups/cron_$(get_date)"
    ensure_directory "$backup_dir"
    
    echo -e "Testing cron job hijacking on ${#DISCOVERED_CRON_JOBS[@]} discovered jobs..."
    echo -e "${YELLOW}${BOLD}WARNING: This will attempt to modify cron files in controlled ways.${NC}"
    echo -e "Backups will be created in $backup_dir"
    echo ""
    
    if confirm_action "Do you want to proceed with the cron job hijacking test?" "n"; then
        local manipulated_count=0
        local success_count=0
        
        # Loop through discovered cron jobs
        for job in "${DISCOVERED_CRON_JOBS[@]}"; do
            IFS='|' read -r location owner details <<< "$job"
            
            # Skip summary entries
            if [[ "$details" == *"entries"* ]]; then
                continue
            fi
            
            # Check if the file exists and is writable
            if [ -f "$location" ] && is_writable "$location"; then
                manipulated_count=$((manipulated_count + 1))
                
                # Create a backup
                cp "$location" "$backup_dir/$(basename "$location").bak"
                
                # Determine which manipulation to use based on the file type
                if [[ "$location" == *"/cron."* || "$location" == *"/crontab"* ]]; then
                    # Try to append a harmless command that logs to a file
                    local temp_file=$(create_temp_file)
                    cat "$location" > "$temp_file"
                    echo "# TaskThief test entry - This is a simulated attack" >> "$temp_file"
                    echo "* * * * * root echo \"Cron hijacked by TaskThief at \$(date)\" >> $SCRIPT_DIR/reports/cron_hijack_test.log" >> "$temp_file"
                    
                    # Try to replace the file
                    if cat "$temp_file" > "$location" 2>/dev/null; then
                        success_count=$((success_count + 1))
                        SUCCESSFUL_MANIPULATIONS+=("$location|cron_append|Appended a test entry to $location")
                        MANIPULATION_RESULTS+=("Successfully hijacked cron job: $location (append method)")
                        status_message "Successfully hijacked cron file: $location" "success"
                    else
                        MANIPULATION_RESULTS+=("Failed to hijack cron job: $location (append method)")
                        status_message "Failed to hijack cron file: $location" "error"
                    fi
                    
                    # Clean up
                    rm "$temp_file"
                elif [[ "$location" == *"/cron.d/"* ]]; then
                    # Try to create a new file in cron.d
                    local new_cron_file="/etc/cron.d/taskthief_test"
                    echo "# TaskThief test entry - This is a simulated attack" > "$new_cron_file" 2>/dev/null
                    echo "* * * * * root echo \"Cron.d hijacked by TaskThief at \$(date)\" >> $SCRIPT_DIR/reports/cron_hijack_test.log" >> "$new_cron_file" 2>/dev/null
                    
                    if [ -f "$new_cron_file" ]; then
                        success_count=$((success_count + 1))
                        SUCCESSFUL_MANIPULATIONS+=("$new_cron_file|cron_new_file|Created a new cron file at $new_cron_file")
                        MANIPULATION_RESULTS+=("Successfully created a new cron file: $new_cron_file")
                        status_message "Successfully created new cron file: $new_cron_file" "success"
                    else
                        MANIPULATION_RESULTS+=("Failed to create a new cron file at: $new_cron_file")
                        status_message "Failed to create new cron file: $new_cron_file" "error"
                    fi
                else
                    # Try to modify an executable script
                    local temp_file=$(create_temp_file)
                    cat "$location" > "$temp_file"
                    
                    # Add a benign command at the beginning that logs execution
                    echo '#!/bin/bash' > "$location" 2>/dev/null
                    echo "# TaskThief test modification - This is a simulated attack" >> "$location" 2>/dev/null
                    echo "echo \"Script hijacked by TaskThief at \$(date)\" >> $SCRIPT_DIR/reports/script_hijack_test.log" >> "$location" 2>/dev/null
                    cat "$temp_file" >> "$location" 2>/dev/null
                    
                    if grep -q "TaskThief test modification" "$location" 2>/dev/null; then
                        success_count=$((success_count + 1))
                        SUCCESSFUL_MANIPULATIONS+=("$location|script_modify|Modified script $location")
                        MANIPULATION_RESULTS+=("Successfully modified script: $location")
                        status_message "Successfully modified script: $location" "success"
                    else
                        MANIPULATION_RESULTS+=("Failed to modify script: $location")
                        status_message "Failed to modify script: $location" "error"
                    fi
                    
                    # Clean up
                    rm "$temp_file"
                fi
            fi
        done
        
        echo -e "\n${GREEN}${BOLD}Cron job hijacking test complete!${NC}"
        echo -e "Attempted to manipulate $manipulated_count cron jobs."
        echo -e "Successfully manipulated $success_count cron jobs."
        echo -e "Original files have been backed up to $backup_dir"
        echo ""
        
        if [ $success_count -gt 0 ]; then
            if confirm_action "Do you want to restore original files now?" "y"; then
                restore_cron_files "$backup_dir"
            else
                echo -e "${YELLOW}You can restore files later using the 'Restore Original Files' option.${NC}"
            fi
        fi
    else
        echo -e "Test cancelled by user."
    fi
    
    read -p "Press Enter to continue..." input
}

# Restore cron files from backup
function restore_cron_files() {
    local backup_dir="$1"
    
    if [ -d "$backup_dir" ]; then
        echo -e "Restoring cron files from backup..."
        
        for backup_file in "$backup_dir"/*.bak; do
            if [ -f "$backup_file" ]; then
                local original_file=$(basename "$backup_file" .bak)
                
                # Find the original path in the successful manipulations
                local original_path=""
                for manip in "${SUCCESSFUL_MANIPULATIONS[@]}"; do
                    IFS='|' read -r path method desc <<< "$manip"
                    if [[ "$(basename "$path")" == "$original_file" ]]; then
                        original_path="$path"
                        break
                    fi
                done
                
                if [ -n "$original_path" ] && [ -f "$original_path" ]; then
                    # Restore the file
                    if cp "$backup_file" "$original_path" 2>/dev/null; then
                        status_message "Restored: $original_path" "success"
                    else
                        status_message "Failed to restore: $original_path" "error"
                    fi
                fi
            fi
        done
        
        # Remove the taskthief test file if it exists
        if [ -f "/etc/cron.d/taskthief_test" ]; then
            if rm "/etc/cron.d/taskthief_test" 2>/dev/null; then
                status_message "Removed: /etc/cron.d/taskthief_test" "success"
            else
                status_message "Failed to remove: /etc/cron.d/taskthief_test" "error"
            fi
        fi
        
        echo -e "${GREEN}${BOLD}Restoration complete!${NC}"
    else
        status_message "Backup directory not found: $backup_dir" "error"
    fi
}

# Test systemd timer manipulation
function test_systemd_manipulation() {
    display_header "TESTING SYSTEMD TIMER MANIPULATION"
    
    # Check if systemctl is available
    if ! command_exists systemctl; then
        status_message "systemctl command not found. Systemd may not be installed." "error"
        read -p "Press Enter to continue..." input
        return
    fi
    
    # Check if discovery has been run
    if [ ${#DISCOVERED_SYSTEMD_TIMERS[@]} -eq 0 ]; then
        status_message "No systemd timers discovered yet. Running discovery first..." "info"
        discover_systemd_timers
    fi
    
    # Create a directory to store original files for restoration
    local backup_dir="$SCRIPT_DIR/config/backups/systemd_$(get_date)"
    ensure_directory "$backup_dir"
    
    echo -e "Testing systemd timer manipulation on ${#DISCOVERED_SYSTEMD_TIMERS[@]} discovered timers..."
    echo -e "${YELLOW}${BOLD}WARNING: This will attempt to modify systemd timer files in controlled ways.${NC}"
    echo -e "Backups will be created in $backup_dir"
    echo ""
    
    if confirm_action "Do you want to proceed with the systemd timer manipulation test?" "n"; then
        local manipulated_count=0
        local success_count=0
        
        # Loop through discovered systemd timers
        for timer in "${DISCOVERED_SYSTEMD_TIMERS[@]}"; do
            IFS='|' read -r name next_run path <<< "$timer"
            
            # Extract the service name (without .timer suffix)
            local service_name="${name%.timer}"
            local service_file=""
            
            # Find the corresponding service file
            if [[ "$path" == *"/system/"* ]]; then
                service_file="${path%.timer}.service"
            else
                # Try to locate the service file
                local timer_dir=$(dirname "$path")
                service_file="$timer_dir/$service_name.service"
                
                if [ ! -f "$service_file" ]; then
                    # Check common systemd directories
                    for sdir in "/etc/systemd/system" "/usr/lib/systemd/system"; do
                        if [ -f "$sdir/$service_name.service" ]; then
                            service_file="$sdir/$service_name.service"
                            break
                        fi
                    done
                fi
            fi
            
            # Check if we found a service file
            if [ -n "$service_file" ] && [ -f "$service_file" ] && is_writable "$service_file"; then
                manipulated_count=$((manipulated_count + 1))
                
                # Create backups
                cp "$path" "$backup_dir/$(basename "$path").bak"
                cp "$service_file" "$backup_dir/$(basename "$service_file").bak"
                
                # Try to modify the service file
                local temp_file=$(create_temp_file)
                cat "$service_file" > "$temp_file"
                
                # Check if we can add a harmless ExecStartPre command
                if ! grep -q "ExecStartPre=" "$service_file"; then
                    # Add the command before ExecStart
                    sed -i "/\[Service\]/a ExecStartPre=/bin/bash -c 'echo \"Timer service hijacked by TaskThief at \$(date)\" >> $SCRIPT_DIR/reports/systemd_hijack_test.log'" "$service_file" 2>/dev/null
                    
                    if grep -q "TaskThief" "$service_file" 2>/dev/null; then
                        success_count=$((success_count + 1))
                        SUCCESSFUL_MANIPULATIONS+=("$service_file|systemd_modify|Modified service file $service_file")
                        MANIPULATION_RESULTS+=("Successfully modified systemd service: $service_file")
                        status_message "Successfully modified service file: $service_file" "success"
                    else
                        MANIPULATION_RESULTS+=("Failed to modify service file: $service_file")
                        status_message "Failed to modify service file: $service_file" "error"
                        
                        # Restore from backup if modification failed
                        cp "$temp_file" "$service_file" 2>/dev/null
                    fi
                else
                    # Try to create a new service file
                    local new_service_dir="/etc/systemd/system"
                    local new_service_name="taskthief_test"
                    local new_service_file="$new_service_dir/$new_service_name.service"
                    local new_timer_file="$new_service_dir/$new_service_name.timer"
                    
                    # Create the service file
                    cat > "$new_service_file" 2>/dev/null << EOF
[Unit]
Description=TaskThief Test Service
Documentation=https://taskthief.example.org

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "TaskThief systemd service executed at \$(date)" >> $SCRIPT_DIR/reports/systemd_hijack_test.log'
User=root

[Install]
WantedBy=multi-user.target
EOF
                    
                    # Create the timer file
                    cat > "$new_timer_file" 2>/dev/null << EOF
[Unit]
Description=TaskThief Test Timer
Documentation=https://taskthief.example.org

[Timer]
OnBootSec=999d
OnUnitActiveSec=999d
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF
                    
                    if [ -f "$new_service_file" ] && [ -f "$new_timer_file" ]; then
                        success_count=$((success_count + 1))
                        SUCCESSFUL_MANIPULATIONS+=("$new_service_file|systemd_new|Created new service $new_service_file")
                        SUCCESSFUL_MANIPULATIONS+=("$new_timer_file|systemd_new|Created new timer $new_timer_file")
                        MANIPULATION_RESULTS+=("Successfully created new systemd service and timer: $new_service_name")
                        status_message "Successfully created new systemd service and timer" "success"
                        
                        # Try to reload systemd
                        systemctl daemon-reload 2>/dev/null
                    else
                        MANIPULATION_RESULTS+=("Failed to create new systemd service and timer")
                        status_message "Failed to create new systemd service and timer" "error"
                    fi
                fi
                
                # Clean up
                rm "$temp_file"
            fi
        done
        
        echo -e "\n${GREEN}${BOLD}Systemd timer manipulation test complete!${NC}"
        echo -e "Attempted to manipulate $manipulated_count systemd timers."
        echo -e "Successfully manipulated $success_count timer configurations."
        echo -e "Original files have been backed up to $backup_dir"
        echo ""
        
        if [ $success_count -gt 0 ]; then
            if confirm_action "Do you want to restore original files now?" "y"; then
                restore_systemd_files "$backup_dir"
            else
                echo -e "${YELLOW}You can restore files later using the 'Restore Original Files' option.${NC}"
            fi
        fi
    else
        echo -e "Test cancelled by user."
    fi
    
    read -p "Press Enter to continue..." input
}

# Restore systemd files from backup
function restore_systemd_files() {
    local backup_dir="$1"
    
    if [ -d "$backup_dir" ]; then
        echo -e "Restoring systemd files from backup..."
        
        for backup_file in "$backup_dir"/*.bak; do
            if [ -f "$backup_file" ]; then
                local original_file=$(basename "$backup_file" .bak)
                
                # Find the original path in the successful manipulations
                local original_path=""
                for manip in "${SUCCESSFUL_MANIPULATIONS[@]}"; do
                    IFS='|' read -r path method desc <<< "$manip"
                    if [[ "$(basename "$path")" == "$original_file" ]]; then
                        original_path="$path"
                        break
                    fi
                done
                
                if [ -n "$original_path" ] && [ -f "$original_path" ]; then
                    # Restore the file
                    if cp "$backup_file" "$original_path" 2>/dev/null; then
                        status_message "Restored: $original_path" "success"
                    else
                        status_message "Failed to restore: $original_path" "error"
                    fi
                fi
            fi
        done
        
        # Remove the taskthief test files if they exist
        for test_file in "/etc/systemd/system/taskthief_test.service" "/etc/systemd/system/taskthief_test.timer"; do
            if [ -f "$test_file" ]; then
                if rm "$test_file" 2>/dev/null; then
                    status_message "Removed: $test_file" "success"
                else
                    status_message "Failed to remove: $test_file" "error"
                fi
            fi
        done
        
        # Reload systemd
        systemctl daemon-reload 2>/dev/null
        
        echo -e "${GREEN}${BOLD}Restoration complete!${NC}"
    else
        status_message "Backup directory not found: $backup_dir" "error"
    fi
}

# Test AT job manipulation
function test_at_manipulation() {
    display_header "TESTING AT JOB MANIPULATION"
    
    # Check if at command is available
    if ! command_exists at; then
        status_message "at command not found. AT job scheduler may not be installed." "error"
        read -p "Press Enter to continue..." input
        return
    fi
    
    # Check if discovery has been run
    if [ ${#DISCOVERED_AT_JOBS[@]} -eq 0 ]; then
        status_message "No AT jobs discovered yet. Running discovery first..." "info"
        discover_at_jobs
    fi
    
    echo -e "Testing AT job manipulation..."
    echo -e "${YELLOW}${BOLD}WARNING: This will attempt to create a new AT job for testing purposes.${NC}"
    echo ""
    
    if confirm_action "Do you want to proceed with the AT job manipulation test?" "n"; then
        # Try to create a new AT job
        local test_job_file=$(create_temp_file)
        local success=false
        
        echo "echo \"AT job executed by TaskThief at \$(date)\" >> $SCRIPT_DIR/reports/at_hijack_test.log" > "$test_job_file"
        
        # Schedule the job to run in 1 minute
        local job_output=$(at -f "$test_job_file" now + 1 minute 2>&1)
        
        if [[ "$job_output" == *"job"* ]]; then
            SUCCESSFUL_MANIPULATIONS+=("at_job|at_new|Created new AT job")
            MANIPULATION_RESULTS+=("Successfully created new AT job: $job_output")
            status_message "Successfully created new AT job: $job_output" "success"
            success=true
        else
            MANIPULATION_RESULTS+=("Failed to create new AT job")
            status_message "Failed to create new AT job" "error"
        fi
        
        # Clean up
        rm "$test_job_file"
        
        echo -e "\n${GREEN}${BOLD}AT job manipulation test complete!${NC}"
        
        if [ "$success" = true ]; then
            if confirm_action "Do you want to remove the test AT job now?" "y"; then
                # Extract job number from output
                local job_number=$(echo "$job_output" | grep -o '[0-9]\+')
                
                if [ -n "$job_number" ]; then
                    atrm "$job_number" 2>/dev/null
                    status_message "Removed AT job: $job_number" "success"
                else
                    status_message "Could not extract job number to remove" "error"
                fi
            else
                echo -e "${YELLOW}The AT job will run once and then be automatically removed.${NC}"
            fi
        fi
    else
        echo -e "Test cancelled by user."
    fi
    
    read -p "Press Enter to continue..." input
}

# Create a persistent backdoor task
function create_backdoor_task() {
    display_header "CREATING PERSISTENT BACKDOOR TASK"
    
    echo -e "This function simulates creating a persistent backdoor task."
    echo -e "${RED}${BOLD}WARNING: This is designed to show how attackers could establish persistence.${NC}"
    echo -e "${YELLOW}All actions are benign and for demonstration purposes only.${NC}"
    echo ""
    
    if confirm_action "Do you want to proceed with the backdoor task demonstration?" "n"; then
        local backdoor_type=""
        
        echo -e "Select backdoor type:"
        echo -e "${BLUE}1.${NC} Cron Job Backdoor"
        echo -e "${BLUE}2.${NC} Systemd Timer Backdoor"
        echo -e "${BLUE}3.${NC} Hidden Script In Standard Location"
        echo ""
        read -p "Select an option: " backdoor_choice
        
        case $backdoor_choice in
            1) 
                backdoor_type="cron"
                create_cron_backdoor
                ;;
            2) 
                if ! command_exists systemctl; then
                    status_message "systemctl command not found. Cannot create systemd backdoor." "error"
                    read -p "Press Enter to continue..." input
                    return
                fi
                backdoor_type="systemd"
                create_systemd_backdoor
                ;;
            3) 
                backdoor_type="hidden_script"
                create_hidden_script_backdoor
                ;;
            *) 
                echo -e "${RED}Invalid option${NC}"
                read -p "Press Enter to continue..." input
                return
                ;;
        esac
        
        echo -e "\n${GREEN}${BOLD}Backdoor task demonstration complete!${NC}"
        echo -e "Created a simulated $backdoor_type backdoor for demonstration purposes."
        
        if confirm_action "Do you want to remove the backdoor now?" "y"; then
            remove_backdoor "$backdoor_type"
        else
            echo -e "${YELLOW}You can remove the backdoor later using the 'Restore Original Files' option.${NC}"
        fi
    else
        echo -e "Demonstration cancelled by user."
    fi
    
    read -p "Press Enter to continue..." input
}

# Create a cron backdoor
function create_cron_backdoor() {
    local cron_dir="/etc/cron.d"
    local cron_file="$cron_dir/system-update" # Innocuous name
    
    # Check if we have write access
    if [ -d "$cron_dir" ] && is_writable "$cron_dir"; then
        # Create the cron job that logs its execution
        echo "# System update scheduler - DO NOT REMOVE" > "$cron_file" 2>/dev/null
        echo "# Installed by system maintenance on $(date)" >> "$cron_file" 2>/dev/null
        echo "*/30 * * * * root echo \"Backdoor cron executed at \$(date)\" >> $SCRIPT_DIR/reports/backdoor_test.log" >> "$cron_file" 2>/dev/null
        
        if [ -f "$cron_file" ]; then
            SUCCESSFUL_MANIPULATIONS+=("$cron_file|backdoor_cron|Created backdoor cron job")
            MANIPULATION_RESULTS+=("Successfully created backdoor cron job: $cron_file")
            status_message "Successfully created backdoor cron job" "success"
        else
            MANIPULATION_RESULTS+=("Failed to create backdoor cron job")
            status_message "Failed to create backdoor cron job" "error"
        fi
    else
        MANIPULATION_RESULTS+=("No write access to create backdoor cron job in $cron_dir")
        status_message "No write access to create backdoor cron job" "error"
    fi
}

# Create a systemd backdoor
function create_systemd_backdoor() {
    local systemd_dir="/etc/systemd/system"
    local service_name="system-monitor" # Innocuous name
    local service_file="$systemd_dir/$service_name.service"
    local timer_file="$systemd_dir/$service_name.timer"
    
    # Check if we have write access
    if [ -d "$systemd_dir" ] && is_writable "$systemd_dir"; then
        # Create the service file
        cat > "$service_file" 2>/dev/null << EOF
[Unit]
Description=System Resource Monitor
Documentation=https://example.org/sys-monitor

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Backdoor systemd service executed at \$(date)" >> $SCRIPT_DIR/reports/backdoor_test.log'
User=root

[Install]
WantedBy=multi-user.target
EOF
        
        # Create the timer file
        cat > "$timer_file" 2>/dev/null << EOF
[Unit]
Description=Run System Resource Monitor periodically
Documentation=https://example.org/sys-monitor

[Timer]
OnBootSec=1min
OnUnitActiveSec=30min
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF
        
        if [ -f "$service_file" ] && [ -f "$timer_file" ]; then
            SUCCESSFUL_MANIPULATIONS+=("$service_file|backdoor_systemd|Created backdoor systemd service")
            SUCCESSFUL_MANIPULATIONS+=("$timer_file|backdoor_systemd|Created backdoor systemd timer")
            MANIPULATION_RESULTS+=("Successfully created backdoor systemd service and timer: $service_name")
            status_message "Successfully created backdoor systemd service and timer" "success"
            
            # Enable and start the timer (without actually activating it)
            # systemctl enable "$service_name.timer" 2>/dev/null
            # systemctl start "$service_name.timer" 2>/dev/null
            
            # For demonstration, just reload systemd
            systemctl daemon-reload 2>/dev/null
        else
            MANIPULATION_RESULTS+=("Failed to create backdoor systemd service and timer")
            status_message "Failed to create backdoor systemd service and timer" "error"
        fi
    else
        MANIPULATION_RESULTS+=("No write access to create backdoor systemd files in $systemd_dir")
        status_message "No write access to create backdoor systemd files" "error"
    fi
}

# Create a hidden script backdoor
function create_hidden_script_backdoor() {
    local script_dir="/usr/local/sbin"
    local hidden_dir="$script_dir/.update"
    local script_file="$hidden_dir/update-check.sh"
    
    # Check if we have write access
    if [ -d "$script_dir" ] && is_writable "$script_dir"; then
        # Create hidden directory
        mkdir -p "$hidden_dir" 2>/dev/null
        
        if [ -d "$hidden_dir" ]; then
            # Create the backdoor script
            cat > "$script_file" 2>/dev/null << EOF
#!/bin/bash

# This script checks for system updates
# Do not remove - part of system maintenance

echo "Hidden script backdoor executed at \$(date)" >> $SCRIPT_DIR/reports/backdoor_test.log
EOF
            
            # Make it executable
            chmod +x "$script_file" 2>/dev/null
            
            if [ -f "$script_file" ] && is_executable "$script_file"; then
                SUCCESSFUL_MANIPULATIONS+=("$script_file|backdoor_script|Created hidden backdoor script")
                MANIPULATION_RESULTS+=("Successfully created hidden backdoor script: $script_file")
                status_message "Successfully created hidden backdoor script" "success"
                
                # For a real backdoor, would also add to a legitimate cron job or alter an existing one
                # For demonstration, create a launcher in cron.daily
                local launcher="/etc/cron.daily/system-update-check"
                echo "#!/bin/bash" > "$launcher" 2>/dev/null
                echo "# System update checker" >> "$launcher" 2>/dev/null
                echo "$script_file" >> "$launcher" 2>/dev/null
                chmod +x "$launcher" 2>/dev/null
                
                if [ -f "$launcher" ] && is_executable "$launcher" ]; then
                    SUCCESSFUL_MANIPULATIONS+=("$launcher|backdoor_launcher|Created backdoor launcher")
                    MANIPULATION_RESULTS+=("Successfully created backdoor launcher: $launcher")
                    status_message "Successfully created backdoor launcher" "success"
                fi
            else
                MANIPULATION_RESULTS+=("Failed to create hidden backdoor script")
                status_message "Failed to create hidden backdoor script" "error"
            fi
        else
            MANIPULATION_RESULTS+=("Failed to create hidden directory $hidden_dir")
            status_message "Failed to create hidden directory" "error"
        fi
    else
        MANIPULATION_RESULTS+=("No write access to create hidden script in $script_dir")
        status_message "No write access to create hidden script" "error"
    fi
}

# Remove backdoor
function remove_backdoor() {
    local backdoor_type="$1"
    
    echo -e "Removing $backdoor_type backdoor..."
    
    case $backdoor_type in
        cron)
            local cron_file="/etc/cron.d/system-update"
            if [ -f "$cron_file" ]; then
                if rm "$cron_file" 2>/dev/null; then
                    status_message "Removed backdoor cron job: $cron_file" "success"
                else
                    status_message "Failed to remove backdoor cron job: $cron_file" "error"
                fi
            fi
            ;;
        systemd)
            local service_file="/etc/systemd/system/system-monitor.service"
            local timer_file="/etc/systemd/system/system-monitor.timer"
            
            # Disable and stop the timer
            # systemctl stop "system-monitor.timer" 2>/dev/null
            # systemctl disable "system-monitor.timer" 2>/dev/null
            
            # Remove files
            for file in "$service_file" "$timer_file"; do
                if [ -f "$file" ]; then
                    if rm "$file" 2>/dev/null; then
                        status_message "Removed backdoor file: $file" "success"
                    else
                        status_message "Failed to remove backdoor file: $file" "error"
                    fi
                fi
            done
            
            # Reload systemd
            systemctl daemon-reload 2>/dev/null
            ;;
        hidden_script)
            local script_file="/usr/local/sbin/.update/update-check.sh"
            local hidden_dir="/usr/local/sbin/.update"
            local launcher="/etc/cron.daily/system-update-check"
            
            # Remove launcher
            if [ -f "$launcher" ]; then
                if rm "$launcher" 2>/dev/null; then
                    status_message "Removed backdoor launcher: $launcher" "success"
                else
                    status_message "Failed to remove backdoor launcher: $launcher" "error"
                fi
            fi
            
            # Remove script
            if [ -f "$script_file" ]; then
                if rm "$script_file" 2>/dev/null; then
                    status_message "Removed backdoor script: $script_file" "success"
                else
                    status_message "Failed to remove backdoor script: $script_file" "error"
                fi
            fi
            
            # Remove hidden directory
            if [ -d "$hidden_dir" ]; then
                if rmdir "$hidden_dir" 2>/dev/null; then
                    status_message "Removed hidden directory: $hidden_dir" "success"
                else
                    status_message "Failed to remove hidden directory: $hidden_dir" "error"
                fi
            fi
            ;;
    esac
    
    echo -e "${GREEN}${BOLD}Backdoor removal complete!${NC}"
}

# Restore original files
function restore_original_files() {
    display_header "RESTORING ORIGINAL FILES"
    
    if [ ${#SUCCESSFUL_MANIPULATIONS[@]} -eq 0 ]; then
        status_message "No manipulations have been performed yet." "info"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "The following manipulations were performed:"
    
    for i in "${!SUCCESSFUL_MANIPULATIONS[@]}"; do
        IFS='|' read -r path method desc <<< "${SUCCESSFUL_MANIPULATIONS[$i]}"
        echo -e "${BLUE}[$((i+1))]${NC} $desc"
    done
    
    echo ""
    if confirm_action "Do you want to restore all files to their original state?" "y"; then
        # Find all backup directories
        local backup_dirs=()
        
        if [ -d "$SCRIPT_DIR/config/backups" ]; then
            for dir in "$SCRIPT_DIR/config/backups"/*; do
                if [ -d "$dir" ]; then
                    backup_dirs+=("$dir")
                fi
            done
        fi
        
        # Restore from backups
        for dir in "${backup_dirs[@]}"; do
            if [[ "$dir" == *"cron_"* ]]; then
                restore_cron_files "$dir"
            elif [[ "$dir" == *"systemd_"* ]]; then
                restore_systemd_files "$dir"
            fi
        done
        
        # Check for backdoors
        local backdoor_cron="/etc/cron.d/system-update"
        local backdoor_systemd_service="/etc/systemd/system/system-monitor.service"
        local backdoor_systemd_timer="/etc/systemd/system/system-monitor.timer"
        local backdoor_script="/usr/local/sbin/.update/update-check.sh"
        local backdoor_launcher="/etc/cron.daily/system-update-check"
        
        # Remove cron backdoor
        if [ -f "$backdoor_cron" ]; then
            remove_backdoor "cron"
        fi
        
        # Remove systemd backdoor
        if [ -f "$backdoor_systemd_service" ] || [ -f "$backdoor_systemd_timer" ]; then
            remove_backdoor "systemd"
        fi
        
        # Remove hidden script backdoor
        if [ -f "$backdoor_script" ] || [ -f "$backdoor_launcher" ]; then
            remove_backdoor "hidden_script"
        fi
        
        # Remove any leftover AT jobs
        for manip in "${SUCCESSFUL_MANIPULATIONS[@]}"; do
            if [[ "$manip" == "at_job|"* ]]; then
                echo -e "Note: AT jobs are temporary and are automatically removed after execution."
                break
            fi
        done
        
        echo -e "${GREEN}${BOLD}All files have been restored!${NC}"
    else
        echo -e "Restoration cancelled by user."
    fi
    
    read -p "Press Enter to continue..." input
}

# View manipulation results
function view_manipulation_results() {
    display_header "MANIPULATION RESULTS"
    
    if [ ${#MANIPULATION_RESULTS[@]} -eq 0 ]; then
        status_message "No manipulation tests have been performed yet." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Results of manipulation tests:${NC}\n"
    
    for i in "${!MANIPULATION_RESULTS[@]}"; do
        echo -e "${BLUE}[$((i+1))]${NC} ${MANIPULATION_RESULTS[$i]}"
    done
    
    echo -e "\n${CYAN}Successfully manipulated items:${NC}\n"
    
    for i in "${!SUCCESSFUL_MANIPULATIONS[@]}"; do
        IFS='|' read -r path method desc <<< "${SUCCESSFUL_MANIPULATIONS[$i]}"
        echo -e "${GREEN}[$((i+1))]${NC} $desc"
    done
    
    echo ""
    read -p "Press Enter to continue..." input
} 