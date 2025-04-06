#!/bin/bash

# TaskThief Analysis Module

# Global variables to store analysis results
ANALYSIS_RESULTS=()
VULNERABILITIES=()

# Display analysis menu
function analysis_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}CONFIGURATION ANALYSIS${NC}"
        echo -e "${BLUE}1.${NC} Analyze Cron Jobs"
        echo -e "${BLUE}2.${NC} Analyze Systemd Timers"
        echo -e "${BLUE}3.${NC} Analyze Permission Issues"
        echo -e "${BLUE}4.${NC} Identify Weak Task Configurations"
        echo -e "${BLUE}5.${NC} Full Analysis (All Checks)"
        echo -e "${BLUE}6.${NC} View Analysis Results"
        echo -e "${BLUE}b.${NC} Back to Main Menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) analyze_cron_jobs ;;
            2) analyze_systemd_timers ;;
            3) analyze_permissions ;;
            4) identify_weak_configs ;;
            5) run_full_analysis ;;
            6) view_analysis_results ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Run a full analysis
function run_full_analysis() {
    display_header "FULL ANALYSIS"
    
    # Reset analysis results
    ANALYSIS_RESULTS=()
    VULNERABILITIES=()
    
    echo -e "Starting comprehensive analysis of scheduled tasks..."
    
    # Run all analysis functions
    analyze_cron_jobs
    analyze_systemd_timers
    analyze_permissions
    identify_weak_configs
    
    echo -e "\n${GREEN}${BOLD}Analysis complete!${NC}"
    echo -e "Found ${#VULNERABILITIES[@]} potential vulnerabilities."
    echo ""
    
    read -p "Press Enter to continue..." input
}

# Analyze cron jobs
function analyze_cron_jobs() {
    display_header "ANALYZING CRON JOBS"
    
    # Check if discovery has been run
    if [ ${#DISCOVERED_CRON_JOBS[@]} -eq 0 ]; then
        status_message "No cron jobs discovered yet. Running discovery first..." "info"
        discover_cron_jobs
    fi
    
    echo -e "Analyzing ${#DISCOVERED_CRON_JOBS[@]} cron jobs for security issues..."
    
    local vuln_count=0
    local analyzed_count=0
    
    for job in "${DISCOVERED_CRON_JOBS[@]}"; do
        IFS='|' read -r location owner details <<< "$job"
        
        # Skip system crontab summaries
        if [[ "$details" == *"entries"* ]]; then
            continue
        fi
        
        analyzed_count=$((analyzed_count + 1))
        progress_bar $analyzed_count ${#DISCOVERED_CRON_JOBS[@]} "Analyzing cron jobs"
        
        # Check if the cron file/directory has insecure permissions
        if [ -f "$location" ]; then
            local perms=$(get_numeric_permissions "$location")
            local file_owner=$(get_owner "$location")
            local file_group=$(get_group "$location")
            
            # Check for world-writable cron files
            if [[ "${perms: -1}" =~ [2367] ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("CRN-001|World-writable cron file|$location is world-writable (permissions: $perms)|high")
                ANALYSIS_RESULTS+=("World-writable cron file: $location (permissions: $perms)")
            fi
            
            # Check for group-writable cron files with dangerous group
            if [[ "${perms: -2:1}" =~ [2367] ]]; then
                if [[ "$file_group" != "root" && "$file_group" != "$file_owner" ]]; then
                    vuln_count=$((vuln_count + 1))
                    VULNERABILITIES+=("CRN-002|Group-writable cron file with non-root group|$location is writable by group $file_group (permissions: $perms)|medium")
                    ANALYSIS_RESULTS+=("Group-writable cron file: $location (permissions: $perms, group: $file_group)")
                fi
            fi
            
            # Check if the cron script has an unsafe script or command
            if [[ "$location" == *"/cron."* ]]; then
                local content=$(cat "$location" 2>/dev/null)
                
                # Check for command injection possibilities
                if [[ "$content" == *"\$(curl"* || "$content" == *"\$(wget"* || 
                      "$content" == *"\`curl"* || "$content" == *"\`wget"* ||
                      "$content" == *"eval"* ]]; then
                    vuln_count=$((vuln_count + 1))
                    VULNERABILITIES+=("CRN-003|Cron job with potential command injection|$location contains commands that could allow command injection|high")
                    ANALYSIS_RESULTS+=("Cron job with command injection risk: $location")
                fi
                
                # Check for unsafe path usage
                if [[ "$content" == *"/tmp/"* || "$content" == *"/var/tmp/"* ]]; then
                    vuln_count=$((vuln_count + 1))
                    VULNERABILITIES+=("CRN-004|Cron job using unsafe path|$location references files in /tmp or other world-writable directories|medium")
                    ANALYSIS_RESULTS+=("Cron job using unsafe path: $location")
                fi
            fi
        fi
    done
    
    # Check directory permissions for key cron directories
    local cron_dirs=("/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.weekly" "/etc/cron.monthly")
    
    for dir in "${cron_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local dir_perms=$(get_numeric_permissions "$dir")
            
            # Check for world-writable cron directories
            if [[ "${dir_perms: -1}" =~ [2367] ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("CRN-005|World-writable cron directory|$dir is world-writable (permissions: $dir_perms)|critical")
                ANALYSIS_RESULTS+=("World-writable cron directory: $dir (permissions: $dir_perms)")
            fi
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}Cron job analysis complete!${NC}"
    echo -e "Analyzed $analyzed_count cron jobs and found $vuln_count potential vulnerabilities."
    echo ""
    
    read -p "Press Enter to continue..." input
}

# Analyze systemd timers
function analyze_systemd_timers() {
    display_header "ANALYZING SYSTEMD TIMERS"
    
    # Check if discovery has been run
    if [ ${#DISCOVERED_SYSTEMD_TIMERS[@]} -eq 0 ]; then
        status_message "No systemd timers discovered yet. Running discovery first..." "info"
        discover_systemd_timers
    fi
    
    echo -e "Analyzing ${#DISCOVERED_SYSTEMD_TIMERS[@]} systemd timers for security issues..."
    
    local vuln_count=0
    local analyzed_count=0
    
    for timer in "${DISCOVERED_SYSTEMD_TIMERS[@]}"; do
        IFS='|' read -r name next_run path <<< "$timer"
        
        analyzed_count=$((analyzed_count + 1))
        progress_bar $analyzed_count ${#DISCOVERED_SYSTEMD_TIMERS[@]} "Analyzing systemd timers"
        
        # Check if the timer service file exists and analyze it
        if [ -f "$path" ]; then
            local perms=$(get_numeric_permissions "$path")
            local file_owner=$(get_owner "$path")
            
            # Check for non-root owned timer files
            if [[ "$file_owner" != "root" ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("TMR-001|Non-root owned timer file|$path is owned by $file_owner instead of root|high")
                ANALYSIS_RESULTS+=("Non-root owned timer file: $path (owner: $file_owner)")
            fi
            
            # Check for insecure permissions
            if [[ "$perms" != "644" && "$perms" != "640" && "$perms" != "600" ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("TMR-002|Timer file with insecure permissions|$path has permissions $perms (should be 644, 640, or 600)|medium")
                ANALYSIS_RESULTS+=("Timer file with insecure permissions: $path (permissions: $perms)")
            fi
            
            # Check service file content
            local content=$(cat "$path" 2>/dev/null)
            
            # Check if the service runs as a specific user
            if [[ "$content" == *"User="* ]] && ! [[ "$content" == *"User=root"* ]]; then
                local user=$(echo "$content" | grep -oP 'User=\K[^\s]+')
                
                # Verify if the user exists
                if user_exists "$user"; then
                    # This is informational, not necessarily a vulnerability
                    ANALYSIS_RESULTS+=("Timer service running as non-root user: $path (User: $user)")
                    
                    # Check if the timer is modifiable by that user
                    if [[ "$file_owner" == "$user" ]]; then
                        vuln_count=$((vuln_count + 1))
                        VULNERABILITIES+=("TMR-003|Timer owned by the user it runs as|$path is owned by $user and also runs as $user, allowing privilege escalation|high")
                    fi
                else
                    vuln_count=$((vuln_count + 1))
                    VULNERABILITIES+=("TMR-004|Timer configured with non-existent user|$path is configured to run as $user, which does not exist|medium")
                fi
            fi
            
            # Check for unsafe ExecStart commands
            if [[ "$content" == *"ExecStart="* ]]; then
                local exec_cmd=$(echo "$content" | grep -oP 'ExecStart=\K[^\s]+')
                
                # Check if the command has unsafe patterns
                if [[ "$exec_cmd" == *"/tmp/"* || "$exec_cmd" == *"/var/tmp/"* ]]; then
                    vuln_count=$((vuln_count + 1))
                    VULNERABILITIES+=("TMR-005|Timer executing command from unsafe location|$path executes $exec_cmd from a world-writable directory|high")
                    ANALYSIS_RESULTS+=("Timer with unsafe command path: $path (Command: $exec_cmd)")
                fi
            fi
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}Systemd timer analysis complete!${NC}"
    echo -e "Analyzed $analyzed_count systemd timers and found $vuln_count potential vulnerabilities."
    echo ""
    
    read -p "Press Enter to continue..." input
}

# Analyze permissions
function analyze_permissions() {
    display_header "ANALYZING PERMISSIONS"
    
    echo -e "Checking for permission issues in scheduled task configurations..."
    
    local vuln_count=0
    
    # Check permissions of key scheduling directories
    local critical_dirs=(
        "/etc/cron.d" 
        "/etc/cron.daily" 
        "/etc/cron.hourly" 
        "/etc/cron.weekly" 
        "/etc/cron.monthly"
        "/var/spool/cron"
        "/var/spool/cron/crontabs"
        "/etc/crontab"
        "/usr/lib/systemd/system"
        "/etc/systemd/system"
    )
    
    for dir in "${critical_dirs[@]}"; do
        if [ -e "$dir" ]; then
            local perms=$(get_numeric_permissions "$dir")
            local owner=$(get_owner "$dir")
            local group=$(get_group "$dir")
            
            # Check if the directory/file is owned by root
            if [[ "$owner" != "root" ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("PRM-001|Critical scheduler path not owned by root|$dir is owned by $owner instead of root|critical")
                ANALYSIS_RESULTS+=("Critical path not owned by root: $dir (owner: $owner)")
            fi
            
            # Check for world-writable directories
            if [[ "${perms: -1}" =~ [2367] ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("PRM-002|World-writable scheduler directory/file|$dir is world-writable (permissions: $perms)|critical")
                ANALYSIS_RESULTS+=("World-writable critical path: $dir (permissions: $perms)")
            fi
            
            # Check group permissions if not owned by root group
            if [[ "$group" != "root" && "${perms: -2:1}" =~ [2367] ]]; then
                vuln_count=$((vuln_count + 1))
                VULNERABILITIES+=("PRM-003|Group-writable scheduler directory/file with non-root group|$dir is writable by group $group (permissions: $perms)|high")
                ANALYSIS_RESULTS+=("Group-writable critical path: $dir (permissions: $perms, group: $group)")
            fi
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}Permission analysis complete!${NC}"
    echo -e "Found $vuln_count permission-related vulnerabilities."
    echo ""
    
    read -p "Press Enter to continue..." input
}

# Identify weak configurations
function identify_weak_configs() {
    display_header "IDENTIFYING WEAK CONFIGURATIONS"
    
    echo -e "Checking for weak configurations in scheduled tasks..."
    
    local vuln_count=0
    
    # Check PATH configuration in crontab
    if [ -f "/etc/crontab" ]; then
        local path_setting=$(grep "^PATH" /etc/crontab 2>/dev/null)
        
        if [ -z "$path_setting" ]; then
            vuln_count=$((vuln_count + 1))
            VULNERABILITIES+=("CFG-001|Missing PATH in crontab|/etc/crontab does not set a secure PATH variable|medium")
            ANALYSIS_RESULTS+=("Missing PATH in crontab: /etc/crontab")
        elif [[ "$path_setting" == *".:"* || "$path_setting" == *":."* ]]; then
            vuln_count=$((vuln_count + 1))
            VULNERABILITIES+=("CFG-002|Insecure PATH in crontab|/etc/crontab includes current directory in PATH: $path_setting|high")
            ANALYSIS_RESULTS+=("Insecure PATH in crontab: $path_setting")
        fi
    fi
    
    # Check for scripts in cron directories without proper shebang
    local cron_dirs=("/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.weekly" "/etc/cron.monthly")
    
    for dir in "${cron_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for script in "$dir"/*; do
                if [ -f "$script" ] && [ -x "$script" ]; then
                    # Check for missing shebang
                    local first_line=$(head -n 1 "$script" 2>/dev/null)
                    
                    if [[ ! "$first_line" =~ ^#! ]]; then
                        vuln_count=$((vuln_count + 1))
                        VULNERABILITIES+=("CFG-003|Cron script without shebang|$script does not begin with a proper interpreter directive|medium")
                        ANALYSIS_RESULTS+=("Cron script without shebang: $script")
                    fi
                    
                    # Check for script with unsafe environment handling
                    local content=$(cat "$script" 2>/dev/null)
                    
                    # Look for environment variable usage without proper sanitization
                    if [[ "$content" == *"$"*"$"* ]]; then
                        vuln_count=$((vuln_count + 1))
                        VULNERABILITIES+=("CFG-004|Cron script with potentially unsafe variable handling|$script contains patterns that may indicate unsafe variable usage|medium")
                        ANALYSIS_RESULTS+=("Unsafe variable handling: $script")
                    fi
                fi
            done
        fi
    done
    
    # Check for risky systemd timer configurations
    local systemd_dirs=("/usr/lib/systemd/system" "/etc/systemd/system")
    
    for dir in "${systemd_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for timer_file in "$dir"/*.timer; do
                if [ -f "$timer_file" ]; then
                    local service_name=$(basename "$timer_file" .timer)
                    local service_file="$dir/$service_name.service"
                    
                    if [ -f "$service_file" ]; then
                        local service_content=$(cat "$service_file" 2>/dev/null)
                        
                        # Check for timers that run without specific user
                        if ! [[ "$service_content" == *"User="* ]]; then
                            # Running as root isn't always a vulnerability, but it's worth noting
                            ANALYSIS_RESULTS+=("Timer running as root (implicit): $timer_file")
                            
                            # Check if the service has no protection settings
                            if ! [[ "$service_content" == *"ProtectSystem="* || 
                                    "$service_content" == *"ProtectHome="* || 
                                    "$service_content" == *"PrivateTmp="* ]]; then
                                vuln_count=$((vuln_count + 1))
                                VULNERABILITIES+=("CFG-005|Systemd timer with minimal protection|$timer_file runs a service without protection settings|medium")
                            fi
                        fi
                        
                        # Check for unsafe working directory
                        if [[ "$service_content" == *"WorkingDirectory=/tmp"* || 
                              "$service_content" == *"WorkingDirectory=/var/tmp"* ]]; then
                            vuln_count=$((vuln_count + 1))
                            VULNERABILITIES+=("CFG-006|Systemd service with unsafe working directory|$service_file uses an unsafe working directory|high")
                            ANALYSIS_RESULTS+=("Unsafe working directory: $service_file")
                        fi
                    fi
                fi
            done
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}Weak configuration analysis complete!${NC}"
    echo -e "Found $vuln_count configuration weaknesses."
    echo ""
    
    read -p "Press Enter to continue..." input
}

# View analysis results
function view_analysis_results() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}ANALYSIS RESULTS${NC}"
        echo -e "${BLUE}1.${NC} View All Findings (${#ANALYSIS_RESULTS[@]})"
        echo -e "${BLUE}2.${NC} View Vulnerabilities by Severity (${#VULNERABILITIES[@]})"
        echo -e "${BLUE}3.${NC} Export Results to File"
        echo -e "${BLUE}b.${NC} Back"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) view_all_findings ;;
            2) view_vulnerabilities_by_severity ;;
            3) export_analysis_results ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# View all findings
function view_all_findings() {
    display_header "ALL FINDINGS"
    
    if [ ${#ANALYSIS_RESULTS[@]} -eq 0 ]; then
        status_message "No analysis results available. Run an analysis first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#ANALYSIS_RESULTS[@]} findings:${NC}\n"
    
    # Display findings
    for i in "${!ANALYSIS_RESULTS[@]}"; do
        echo -e "${BLUE}[$((i+1))]${NC} ${ANALYSIS_RESULTS[$i]}"
    done
    
    echo ""
    read -p "Press Enter to continue..." input
}

# View vulnerabilities by severity
function view_vulnerabilities_by_severity() {
    display_header "VULNERABILITIES BY SEVERITY"
    
    if [ ${#VULNERABILITIES[@]} -eq 0 ]; then
        status_message "No vulnerabilities identified. Run an analysis first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "${CYAN}Found ${#VULNERABILITIES[@]} vulnerabilities:${NC}\n"
    
    # Sort and display by severity
    echo -e "${RED}${BOLD}CRITICAL:${NC}"
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "critical" ]]; then
            echo -e "  ${BOLD}[$id]${NC} $title - $description"
        fi
    done
    
    echo -e "\n${RED}${BOLD}HIGH:${NC}"
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "high" ]]; then
            echo -e "  ${BOLD}[$id]${NC} $title - $description"
        fi
    done
    
    echo -e "\n${YELLOW}${BOLD}MEDIUM:${NC}"
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "medium" ]]; then
            echo -e "  ${BOLD}[$id]${NC} $title - $description"
        fi
    done
    
    echo -e "\n${GREEN}${BOLD}LOW:${NC}"
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "low" ]]; then
            echo -e "  ${BOLD}[$id]${NC} $title - $description"
        fi
    done
    
    echo ""
    read -p "Press Enter to continue..." input
}

# Export analysis results to file
function export_analysis_results() {
    local report_file="$REPORT_PATH/analysis_report_$(get_date).txt"
    
    display_header "EXPORTING ANALYSIS RESULTS"
    
    if [ ${#ANALYSIS_RESULTS[@]} -eq 0 ] && [ ${#VULNERABILITIES[@]} -eq 0 ]; then
        status_message "No analysis results available. Run an analysis first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "Exporting results to $report_file"
    
    # Create report header
    cat > "$report_file" << EOF
================================
TaskThief Analysis Report
================================
Generated: $(get_timestamp)
Hostname: $(get_hostname)
Distribution: $(check_distribution)
Kernel: $(get_kernel_version)
User: $(get_current_user)
================================

SUMMARY
================================
Total Findings: ${#ANALYSIS_RESULTS[@]}
Total Vulnerabilities: ${#VULNERABILITIES[@]}

EOF
    
    # Add vulnerability summary by severity
    local critical_count=0
    local high_count=0
    local medium_count=0
    local low_count=0
    
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        case "$severity" in
            critical) critical_count=$((critical_count + 1)) ;;
            high) high_count=$((high_count + 1)) ;;
            medium) medium_count=$((medium_count + 1)) ;;
            low) low_count=$((low_count + 1)) ;;
        esac
    done
    
    cat >> "$report_file" << EOF
VULNERABILITY SEVERITY DISTRIBUTION
================================
Critical: $critical_count
High: $high_count
Medium: $medium_count
Low: $low_count

EOF
    
    # Add vulnerabilities section
    cat >> "$report_file" << EOF
VULNERABILITIES
================================
EOF
    
    # Critical vulnerabilities
    cat >> "$report_file" << EOF

CRITICAL
--------
EOF
    
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "critical" ]]; then
            cat >> "$report_file" << EOF
[$id] $title
Description: $description
Severity: CRITICAL

EOF
        fi
    done
    
    # High vulnerabilities
    cat >> "$report_file" << EOF
HIGH
----
EOF
    
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "high" ]]; then
            cat >> "$report_file" << EOF
[$id] $title
Description: $description
Severity: HIGH

EOF
        fi
    done
    
    # Medium vulnerabilities
    cat >> "$report_file" << EOF
MEDIUM
------
EOF
    
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "medium" ]]; then
            cat >> "$report_file" << EOF
[$id] $title
Description: $description
Severity: MEDIUM

EOF
        fi
    done
    
    # Low vulnerabilities
    cat >> "$report_file" << EOF
LOW
---
EOF
    
    for vuln in "${VULNERABILITIES[@]}"; do
        IFS='|' read -r id title description severity <<< "$vuln"
        if [[ "$severity" == "low" ]]; then
            cat >> "$report_file" << EOF
[$id] $title
Description: $description
Severity: LOW

EOF
        fi
    done
    
    # Add all findings
    cat >> "$report_file" << EOF

ALL FINDINGS
================================
EOF
    
    for finding in "${ANALYSIS_RESULTS[@]}"; do
        echo "- $finding" >> "$report_file"
    done
    
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