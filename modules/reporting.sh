#!/bin/bash

# TaskThief Reporting Module

# Display reporting menu
function reporting_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}GENERATE REPORT${NC}"
        echo -e "${BLUE}1.${NC} Generate Full Report"
        echo -e "${BLUE}2.${NC} Generate Discovery Report"
        echo -e "${BLUE}3.${NC} Generate Vulnerability Report"
        echo -e "${BLUE}4.${NC} Generate Manipulation Report"
        echo -e "${BLUE}5.${NC} View Reports"
        echo -e "${BLUE}b.${NC} Back to Main Menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) generate_full_report ;;
            2) generate_discovery_report ;;
            3) generate_vulnerability_report ;;
            4) generate_manipulation_report ;;
            5) view_reports ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Generate a full comprehensive report
function generate_full_report() {
    display_header "GENERATING FULL REPORT"
    
    local report_file="$REPORT_PATH/taskthief_full_report_$(get_date).html"
    
    echo -e "Generating comprehensive report to $report_file..."
    
    # Create report header
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>TaskThief Full Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3, h4 {
            color: #0056b3;
        }
        h1 {
            border-bottom: 2px solid #0056b3;
            padding-bottom: 10px;
        }
        h2 {
            border-bottom: 1px solid #ddd;
            padding-bottom: 5px;
            margin-top: 30px;
        }
        .header {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .critical {
            color: #d9534f;
            font-weight: bold;
        }
        .high {
            color: #f0ad4e;
            font-weight: bold;
        }
        .medium {
            color: #5bc0de;
            font-weight: bold;
        }
        .low {
            color: #5cb85c;
        }
        .success {
            color: #5cb85c;
        }
        .failure {
            color: #d9534f;
        }
        .footer {
            margin-top: 30px;
            border-top: 1px solid #ddd;
            padding-top: 10px;
            font-size: 0.8em;
            color: #777;
        }
        .section {
            margin-bottom: 30px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>TaskThief Comprehensive Report</h1>
        <p><strong>Generated:</strong> $(get_timestamp)</p>
        <p><strong>Hostname:</strong> $(get_hostname)</p>
        <p><strong>Distribution:</strong> $(check_distribution)</p>
        <p><strong>Kernel:</strong> $(get_kernel_version)</p>
        <p><strong>User:</strong> $(get_current_user)</p>
    </div>

    <div class="section">
        <h2>Executive Summary</h2>
        <p>This report presents the findings of a comprehensive assessment of scheduled tasks on the system. The assessment included discovery of scheduled tasks, analysis of their configurations, and controlled manipulation tests to identify security vulnerabilities.</p>
EOF
    
    # Add summary counts
    local vuln_count=${#VULNERABILITIES[@]}
    local cron_count=${#DISCOVERED_CRON_JOBS[@]}
    local systemd_count=${#DISCOVERED_SYSTEMD_TIMERS[@]}
    local at_count=${#DISCOVERED_AT_JOBS[@]}
    local anacron_count=${#DISCOVERED_ANACRON_JOBS[@]}
    local manip_count=${#SUCCESSFUL_MANIPULATIONS[@]}
    
    # Count vulnerabilities by severity
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
        <h3>Key Findings</h3>
        <ul>
            <li><strong>Scheduled Tasks Discovered:</strong> $((cron_count + systemd_count + at_count + anacron_count))</li>
            <li><strong>Vulnerabilities Identified:</strong> $vuln_count</li>
            <li><strong>Critical Vulnerabilities:</strong> $critical_count</li>
            <li><strong>High Severity Vulnerabilities:</strong> $high_count</li>
            <li><strong>Medium Severity Vulnerabilities:</strong> $medium_count</li>
            <li><strong>Low Severity Vulnerabilities:</strong> $low_count</li>
            <li><strong>Successful Manipulations:</strong> $manip_count</li>
        </ul>
    </div>
EOF
    
    # Add discovered tasks section
    cat >> "$report_file" << EOF
    <div class="section">
        <h2>Discovered Scheduled Tasks</h2>
        
        <h3>Cron Jobs</h3>
EOF
    
    if [ $cron_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Found $cron_count cron jobs on the system.</p>
        <table>
            <tr>
                <th>Location</th>
                <th>Owner</th>
                <th>Details</th>
            </tr>
EOF
        
        for job in "${DISCOVERED_CRON_JOBS[@]}"; do
            IFS='|' read -r location owner details <<< "$job"
            cat >> "$report_file" << EOF
            <tr>
                <td>$location</td>
                <td>$owner</td>
                <td>$details</td>
            </tr>
EOF
        done
        
        cat >> "$report_file" << EOF
        </table>
EOF
    else
        cat >> "$report_file" << EOF
        <p>No cron jobs were discovered on the system.</p>
EOF
    fi
    
    # Add systemd timers section
    cat >> "$report_file" << EOF
        <h3>Systemd Timers</h3>
EOF
    
    if [ $systemd_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Found $systemd_count systemd timers on the system.</p>
        <table>
            <tr>
                <th>Timer Name</th>
                <th>Next Run</th>
                <th>Service Path</th>
            </tr>
EOF
        
        for timer in "${DISCOVERED_SYSTEMD_TIMERS[@]}"; do
            IFS='|' read -r name next_run path <<< "$timer"
            cat >> "$report_file" << EOF
            <tr>
                <td>$name</td>
                <td>$next_run</td>
                <td>$path</td>
            </tr>
EOF
        done
        
        cat >> "$report_file" << EOF
        </table>
EOF
    else
        cat >> "$report_file" << EOF
        <p>No systemd timers were discovered on the system.</p>
EOF
    fi
    
    # Add AT jobs section
    cat >> "$report_file" << EOF
        <h3>AT Jobs</h3>
EOF
    
    if [ $at_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Found $at_count AT jobs on the system.</p>
        <table>
            <tr>
                <th>Job ID</th>
                <th>Scheduled Time</th>
            </tr>
EOF
        
        for job in "${DISCOVERED_AT_JOBS[@]}"; do
            IFS='|' read -r id scheduled <<< "$job"
            cat >> "$report_file" << EOF
            <tr>
                <td>$id</td>
                <td>$scheduled</td>
            </tr>
EOF
        done
        
        cat >> "$report_file" << EOF
        </table>
EOF
    else
        cat >> "$report_file" << EOF
        <p>No AT jobs were discovered on the system.</p>
EOF
    fi
    
    # Add Anacron jobs section
    cat >> "$report_file" << EOF
        <h3>Anacron Jobs</h3>
EOF
    
    if [ $anacron_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Found $anacron_count Anacron jobs on the system.</p>
        <table>
            <tr>
                <th>Job ID</th>
                <th>Period (days)</th>
                <th>Delay (min)</th>
                <th>Command</th>
            </tr>
EOF
        
        for job in "${DISCOVERED_ANACRON_JOBS[@]}"; do
            if [[ "$job" == *"|"*"|"*"|"* ]]; then
                IFS='|' read -r id period delay command <<< "$job"
                cat >> "$report_file" << EOF
            <tr>
                <td>$id</td>
                <td>$period</td>
                <td>$delay</td>
                <td>$command</td>
            </tr>
EOF
            else
                IFS='|' read -r location owner details <<< "$job"
                cat >> "$report_file" << EOF
            <tr>
                <td colspan="4">$location ($owner): $details</td>
            </tr>
EOF
            fi
        done
        
        cat >> "$report_file" << EOF
        </table>
EOF
    else
        cat >> "$report_file" << EOF
        <p>No Anacron jobs were discovered on the system.</p>
EOF
    fi
    
    # Add Hidden tasks section
    cat >> "$report_file" << EOF
        <h3>Hidden and Non-Standard Tasks</h3>
EOF
    
    local hidden_count=${#DISCOVERED_HIDDEN_TASKS[@]}
    
    if [ $hidden_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Found $hidden_count hidden or non-standard tasks on the system.</p>
        <table>
            <tr>
                <th>Type</th>
                <th>Location</th>
                <th>Details</th>
            </tr>
EOF
        
        for task in "${DISCOVERED_HIDDEN_TASKS[@]}"; do
            IFS='|' read -r type location details extra <<< "$task"
            cat >> "$report_file" << EOF
            <tr>
                <td>$type</td>
                <td>$location</td>
                <td>$details</td>
            </tr>
EOF
            if [ -n "$extra" ]; then
                cat >> "$report_file" << EOF
            <tr>
                <td></td>
                <td colspan="2">$extra</td>
            </tr>
EOF
            fi
        done
        
        cat >> "$report_file" << EOF
        </table>
EOF
    else
        cat >> "$report_file" << EOF
        <p>No hidden or non-standard tasks were discovered on the system.</p>
EOF
    fi
    
    cat >> "$report_file" << EOF
    </div>
EOF
    
    # Add vulnerabilities section
    cat >> "$report_file" << EOF
    <div class="section">
        <h2>Identified Vulnerabilities</h2>
EOF
    
    if [ $vuln_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Found $vuln_count vulnerabilities in scheduled tasks.</p>
        
        <h3>Critical Vulnerabilities</h3>
EOF
        
        if [ $critical_count -gt 0 ]; then
            cat >> "$report_file" << EOF
        <table>
            <tr>
                <th>ID</th>
                <th>Title</th>
                <th>Description</th>
            </tr>
EOF
            
            for vuln in "${VULNERABILITIES[@]}"; do
                IFS='|' read -r id title description severity <<< "$vuln"
                if [[ "$severity" == "critical" ]]; then
                    cat >> "$report_file" << EOF
            <tr>
                <td class="critical">$id</td>
                <td class="critical">$title</td>
                <td>$description</td>
            </tr>
EOF
                fi
            done
            
            cat >> "$report_file" << EOF
        </table>
EOF
        else
            cat >> "$report_file" << EOF
        <p>No critical vulnerabilities were identified.</p>
EOF
        fi
        
        cat >> "$report_file" << EOF
        <h3>High Severity Vulnerabilities</h3>
EOF
        
        if [ $high_count -gt 0 ]; then
            cat >> "$report_file" << EOF
        <table>
            <tr>
                <th>ID</th>
                <th>Title</th>
                <th>Description</th>
            </tr>
EOF
            
            for vuln in "${VULNERABILITIES[@]}"; do
                IFS='|' read -r id title description severity <<< "$vuln"
                if [[ "$severity" == "high" ]]; then
                    cat >> "$report_file" << EOF
            <tr>
                <td class="high">$id</td>
                <td class="high">$title</td>
                <td>$description</td>
            </tr>
EOF
                fi
            done
            
            cat >> "$report_file" << EOF
        </table>
EOF
        else
            cat >> "$report_file" << EOF
        <p>No high severity vulnerabilities were identified.</p>
EOF
        fi
        
        cat >> "$report_file" << EOF
        <h3>Medium Severity Vulnerabilities</h3>
EOF
        
        if [ $medium_count -gt 0 ]; then
            cat >> "$report_file" << EOF
        <table>
            <tr>
                <th>ID</th>
                <th>Title</th>
                <th>Description</th>
            </tr>
EOF
            
            for vuln in "${VULNERABILITIES[@]}"; do
                IFS='|' read -r id title description severity <<< "$vuln"
                if [[ "$severity" == "medium" ]]; then
                    cat >> "$report_file" << EOF
            <tr>
                <td class="medium">$id</td>
                <td class="medium">$title</td>
                <td>$description</td>
            </tr>
EOF
                fi
            done
            
            cat >> "$report_file" << EOF
        </table>
EOF
        else
            cat >> "$report_file" << EOF
        <p>No medium severity vulnerabilities were identified.</p>
EOF
        fi
        
        cat >> "$report_file" << EOF
        <h3>Low Severity Vulnerabilities</h3>
EOF
        
        if [ $low_count -gt 0 ]; then
            cat >> "$report_file" << EOF
        <table>
            <tr>
                <th>ID</th>
                <th>Title</th>
                <th>Description</th>
            </tr>
EOF
            
            for vuln in "${VULNERABILITIES[@]}"; do
                IFS='|' read -r id title description severity <<< "$vuln"
                if [[ "$severity" == "low" ]]; then
                    cat >> "$report_file" << EOF
            <tr>
                <td class="low">$id</td>
                <td class="low">$title</td>
                <td>$description</td>
            </tr>
EOF
                fi
            done
            
            cat >> "$report_file" << EOF
        </table>
EOF
        else
            cat >> "$report_file" << EOF
        <p>No low severity vulnerabilities were identified.</p>
EOF
        fi
    else
        cat >> "$report_file" << EOF
        <p>No vulnerabilities were identified in the system's scheduled tasks.</p>
EOF
    fi
    
    cat >> "$report_file" << EOF
    </div>
EOF
    
    # Add manipulation tests section
    cat >> "$report_file" << EOF
    <div class="section">
        <h2>Manipulation Tests</h2>
EOF
    
    if [ ${#MANIPULATION_RESULTS[@]} -gt 0 ]; then
        cat >> "$report_file" << EOF
        <p>Conducted ${#MANIPULATION_RESULTS[@]} manipulation tests with $manip_count successful manipulations.</p>
        
        <h3>Manipulation Test Results</h3>
        <table>
            <tr>
                <th>#</th>
                <th>Result</th>
            </tr>
EOF
        
        for i in "${!MANIPULATION_RESULTS[@]}"; do
            local result="${MANIPULATION_RESULTS[$i]}"
            local class="failure"
            
            if [[ "$result" == *"Successfully"* ]]; then
                class="success"
            fi
            
            cat >> "$report_file" << EOF
            <tr>
                <td>$((i+1))</td>
                <td class="$class">$result</td>
            </tr>
EOF
        done
        
        cat >> "$report_file" << EOF
        </table>
        
        <h3>Successful Manipulations</h3>
EOF
        
        if [ $manip_count -gt 0 ]; then
            cat >> "$report_file" << EOF
        <table>
            <tr>
                <th>#</th>
                <th>Description</th>
            </tr>
EOF
            
            for i in "${!SUCCESSFUL_MANIPULATIONS[@]}"; do
                IFS='|' read -r path method desc <<< "${SUCCESSFUL_MANIPULATIONS[$i]}"
                cat >> "$report_file" << EOF
            <tr>
                <td>$((i+1))</td>
                <td>$desc</td>
            </tr>
EOF
            done
            
            cat >> "$report_file" << EOF
        </table>
EOF
        else
            cat >> "$report_file" << EOF
        <p>No successful manipulations were performed.</p>
EOF
        fi
    else
        cat >> "$report_file" << EOF
        <p>No manipulation tests were conducted.</p>
EOF
    fi
    
    cat >> "$report_file" << EOF
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <p>Based on the findings of this assessment, the following recommendations are provided to improve the security of scheduled tasks on this system:</p>
        
        <h3>General Recommendations</h3>
        <ul>
            <li>Regularly audit all scheduled tasks to ensure they are necessary and properly configured.</li>
            <li>Follow the principle of least privilege for all scheduled tasks - tasks should run with the minimum privileges required.</li>
            <li>Implement proper logging and monitoring for scheduled task execution.</li>
            <li>Use version control for scripts executed by scheduled tasks.</li>
            <li>Implement file integrity monitoring for critical system directories.</li>
        </ul>
EOF
    
    # Add specific recommendations based on findings
    if [ $vuln_count -gt 0 ]; then
        cat >> "$report_file" << EOF
        
        <h3>Specific Recommendations</h3>
        <ul>
EOF
        
        if [ $critical_count -gt 0 ] || [ $high_count -gt 0 ]; then
            for vuln in "${VULNERABILITIES[@]}"; do
                IFS='|' read -r id title description severity <<< "$vuln"
                if [[ "$severity" == "critical" || "$severity" == "high" ]]; then
                    local recommendation=""
                    
                    case "$id" in
                        "CRN-001"|"CRN-005"|"PRM-002")
                            recommendation="Fix world-writable permissions on $description. Use 'chmod o-w' to remove write permissions for others."
                            ;;
                        "CRN-003")
                            recommendation="Review and secure scripts that may allow command injection. Avoid using eval with untrusted input and sanitize all external data."
                            ;;
                        "TMR-001"|"PRM-001")
                            recommendation="Change ownership of $description to root using 'chown root:root'."
                            ;;
                        "TMR-003")
                            recommendation="Separate privileges by ensuring timer files are owned by root but run as a less privileged user."
                            ;;
                        "TMR-005"|"CRN-004")
                            recommendation="Avoid using world-writable directories for executables or scripts. Move to a secure location with proper permissions."
                            ;;
                        "PRM-003")
                            recommendation="Change group ownership to root or remove group write permissions using 'chgrp root' or 'chmod g-w'."
                            ;;
                        *)
                            recommendation="Address the $severity severity issue: $title."
                            ;;
                    esac
                    
                    cat >> "$report_file" << EOF
            <li><strong>[$id]</strong> $recommendation</li>
EOF
                fi
            done
        fi
        
        if [ $manip_count -gt 0 ]; then
            cat >> "$report_file" << EOF
            <li>Address the successful manipulations identified in the report by securing the affected files and directories.</li>
EOF
        fi
        
        cat >> "$report_file" << EOF
        </ul>
EOF
    fi
    
    # Close the HTML document
    cat >> "$report_file" << EOF
    </div>
    
    <div class="footer">
        <p>Report generated by TaskThief - The Active Scheduled-Task-Manipulator</p>
        <p>© $(date +"%Y") TaskThief. All rights reserved.</p>
    </div>
</body>
</html>
EOF
    
    status_message "Report saved to $report_file" "success"
    echo ""
    
    if confirm_action "Would you like to view the report now?"; then
        if command_exists xdg-open; then
            xdg-open "$report_file" &>/dev/null &
        else
            echo -e "${YELLOW}Cannot open the report automatically. Please open it manually at:${NC}"
            echo -e "$report_file"
        fi
    fi
    
    read -p "Press Enter to continue..." input
}

# Generate discovery-only report
function generate_discovery_report() {
    display_header "GENERATING DISCOVERY REPORT"
    
    # Check if discovery has been run
    if [ ${#DISCOVERED_CRON_JOBS[@]} -eq 0 ] && [ ${#DISCOVERED_SYSTEMD_TIMERS[@]} -eq 0 ] && [ ${#DISCOVERED_AT_JOBS[@]} -eq 0 ] && [ ${#DISCOVERED_ANACRON_JOBS[@]} -eq 0 ]; then
        status_message "No discovery data available. Running discovery first..." "info"
        run_full_discovery
    fi
    
    # Call the export function from discovery module
    export_discovery_results
}

# Generate vulnerability-only report
function generate_vulnerability_report() {
    display_header "GENERATING VULNERABILITY REPORT"
    
    # Check if analysis has been run
    if [ ${#VULNERABILITIES[@]} -eq 0 ]; then
        status_message "No vulnerability data available. Running analysis first..." "info"
        run_full_analysis
    fi
    
    # Call the export function from analysis module
    export_analysis_results
}

# Generate manipulation report
function generate_manipulation_report() {
    display_header "GENERATING MANIPULATION REPORT"
    
    if [ ${#MANIPULATION_RESULTS[@]} -eq 0 ]; then
        status_message "No manipulation data available. Please run manipulation tests first." "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    local report_file="$REPORT_PATH/manipulation_report_$(get_date).txt"
    
    echo -e "Exporting manipulation results to $report_file"
    
    # Create report header
    cat > "$report_file" << EOF
================================
TaskThief Manipulation Report
================================
Generated: $(get_timestamp)
Hostname: $(get_hostname)
Distribution: $(check_distribution)
Kernel: $(get_kernel_version)
User: $(get_current_user)
================================

SUMMARY
================================
Total Manipulation Tests: ${#MANIPULATION_RESULTS[@]}
Successful Manipulations: ${#SUCCESSFUL_MANIPULATIONS[@]}

EOF
    
    # Add manipulation results
    cat >> "$report_file" << EOF
MANIPULATION TEST RESULTS
================================
EOF
    
    for i in "${!MANIPULATION_RESULTS[@]}"; do
        echo "[$((i+1))] ${MANIPULATION_RESULTS[$i]}" >> "$report_file"
    done
    
    # Add successful manipulations
    cat >> "$report_file" << EOF

SUCCESSFUL MANIPULATIONS
================================
EOF
    
    for i in "${!SUCCESSFUL_MANIPULATIONS[@]}"; do
        IFS='|' read -r path method desc <<< "${SUCCESSFUL_MANIPULATIONS[$i]}"
        echo "[$((i+1))] $desc" >> "$report_file"
        echo "    Path: $path" >> "$report_file"
        echo "    Method: $method" >> "$report_file"
        echo "" >> "$report_file"
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

# View all reports
function view_reports() {
    display_header "VIEW REPORTS"
    
    if [ ! -d "$REPORT_PATH" ]; then
        status_message "Report directory not found: $REPORT_PATH" "error"
        read -p "Press Enter to continue..." input
        return
    fi
    
    # Get list of reports
    local reports=()
    local count=0
    
    for report in "$REPORT_PATH"/*; do
        if [ -f "$report" ]; then
            reports+=("$report")
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        status_message "No reports found in $REPORT_PATH" "warning"
        read -p "Press Enter to continue..." input
        return
    fi
    
    echo -e "Found $count reports in $REPORT_PATH:\n"
    
    for i in "${!reports[@]}"; do
        local report="${reports[$i]}"
        local filename=$(basename "$report")
        local size=$(du -h "$report" | cut -f1)
        local date=$(date -r "$report" "+%Y-%m-%d %H:%M:%S")
        
        echo -e "${BLUE}$((i+1)).${NC} $filename"
        echo -e "   Size: $size, Date: $date"
    done
    
    echo ""
    read -p "Enter report number to view (or 'b' to go back): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $count ]; then
        local selected_report="${reports[$((choice-1))]}"
        
        if [[ "$selected_report" == *.html ]]; then
            if command_exists xdg-open; then
                xdg-open "$selected_report" &>/dev/null &
                status_message "Opening report in browser" "info"
            else
                status_message "Cannot open HTML report. No browser found." "error"
            fi
        else
            less "$selected_report"
        fi
    elif [[ "$choice" != "b" && "$choice" != "B" ]]; then
        status_message "Invalid choice" "error"
    fi
    
    read -p "Press Enter to continue..." input
} 