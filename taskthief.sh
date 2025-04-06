#!/bin/bash

# TaskThief - Active Scheduled-Task-Manipulator
# Main script file
# Version 1.0.0

# Set colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Version info
VERSION="1.0.0"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Include utility functions
source "$SCRIPT_DIR/utils/ui.sh"
source "$SCRIPT_DIR/utils/common.sh"

# Include modules
source "$SCRIPT_DIR/modules/discovery.sh"
source "$SCRIPT_DIR/modules/analysis.sh"
source "$SCRIPT_DIR/modules/manipulation.sh"
source "$SCRIPT_DIR/modules/reporting.sh"

# Print banner
function print_banner() {
    clear
    echo -e "${RED}${BOLD}"
    echo -e "████████╗ █████╗ ███████╗██╗  ██╗████████╗██╗  ██╗██╗███████╗███████╗"
    echo -e "╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝╚══██╔══╝██║  ██║██║██╔════╝██╔════╝"
    echo -e "   ██║   ███████║███████╗█████╔╝    ██║   ███████║██║█████╗  █████╗  "
    echo -e "   ██║   ██╔══██║╚════██║██╔═██╗    ██║   ██╔══██║██║██╔══╝  ██╔══╝  "
    echo -e "   ██║   ██║  ██║███████║██║  ██╗   ██║   ██║  ██║██║███████╗██║     "
    echo -e "   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝╚═╝     "
    echo -e "${NC}"
    echo -e "${YELLOW}${BOLD}Active Scheduled-Task-Manipulator${NC}"
    echo -e "${BLUE}A penetration testing tool for scheduled tasks${NC}"
    echo -e "${CYAN}Version $VERSION${NC}"
    echo ""
}

# Print help information
function print_help() {
    print_banner
    echo -e "${CYAN}${BOLD}USAGE:${NC}"
    echo -e "  ./taskthief.sh [OPTION]"
    echo ""
    echo -e "${CYAN}${BOLD}OPTIONS:${NC}"
    echo -e "  ${BLUE}-h, --help${NC}       Display this help message"
    echo -e "  ${BLUE}-v, --version${NC}    Display version information"
    echo -e "  ${BLUE}-d, --discover${NC}   Run full discovery immediately"
    echo -e "  ${BLUE}-a, --analyze${NC}    Run full analysis immediately"
    echo -e "  ${BLUE}-r, --report${NC}     Generate a full report immediately"
    echo ""
    echo -e "${CYAN}${BOLD}EXAMPLES:${NC}"
    echo -e "  ./taskthief.sh              Start the interactive menu"
    echo -e "  ./taskthief.sh --discover   Run discovery and exit"
    echo -e "  ./taskthief.sh --report     Generate a full report and exit"
    echo ""
    echo -e "${CYAN}${BOLD}NOTE:${NC}"
    echo -e "  Some features require root privileges to function properly."
    echo -e "  Consider running with sudo for full functionality."
    echo ""
}

# Check for required dependencies
function check_dependencies() {
    local missing_deps=()
    local required_deps=("grep" "awk" "sed" "curl" "find" "ls" "cat" "chmod" "chown" "stat")
    
    for dep in "${required_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}${BOLD}ERROR: Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "  - $dep"
        done
        echo -e "\nPlease install these dependencies and try again."
        exit 1
    fi
}

# Check if running as root
function check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}${BOLD}WARNING:${NC} TaskThief is not running with root privileges."
        echo -e "Some features may be limited. Full functionality requires root privileges."
        echo ""
        echo -e "Options:"
        echo -e "1. Continue without root privileges (limited functionality)"
        echo -e "2. Restart with sudo (recommended)"
        echo -e "3. Exit"
        echo ""
        read -p "Select an option [1-3]: " privilege_choice
        
        case $privilege_choice in
            1)
                # Continue without sudo
                echo -e "${YELLOW}Continuing with limited functionality...${NC}"
                sleep 1
                ;;
            2)
                # Restart with sudo
                elevate_privileges "$@"
                ;;
            3|*)
                # Exit
                echo -e "${RED}Exiting TaskThief.${NC}"
                exit 0
                ;;
        esac
    else
        echo -e "${GREEN}${BOLD}Running with root privileges. Full functionality available.${NC}"
        sleep 1
    fi
}

# Elevate privileges with sudo
function elevate_privileges() {
    echo -e "${BLUE}Restarting TaskThief with root privileges...${NC}"
    
    # Reconstruct the command line with all arguments
    local cmd="sudo $SCRIPT_DIR/taskthief.sh"
    if [ $# -gt 0 ]; then
        cmd="$cmd $*"
    fi
    
    # Execute the command
    exec $cmd
    
    # If exec fails, exit with error
    echo -e "${RED}Failed to restart with sudo.${NC}"
    exit 1
}

# Main menu
function main_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}MAIN MENU${NC}"
        echo -e "${BLUE}1.${NC} Automatic Discovery     - Identify scheduled tasks and cron jobs ${YELLOW}${BOLD}[ROOT]${NC}"
        echo -e "${BLUE}2.${NC} Configuration Analysis  - Evaluate permissions and settings ${YELLOW}${BOLD}[ROOT]${NC}"
        echo -e "${BLUE}3.${NC} Task Manipulation       - Test task hijacking and modifications ${RED}${BOLD}[ROOT]${NC}"
        echo -e "${BLUE}4.${NC} Generate Report         - Create detailed findings report"
        echo -e "${BLUE}5.${NC} Settings                - Configure application settings"
        echo -e "${BLUE}h.${NC} Help                    - Show help information"
        echo -e "${BLUE}q.${NC} Quit"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) 
                if verify_root_for_operation "Automatic Discovery"; then
                    discovery_menu
                else
                    read -p "Press Enter to continue..." input
                fi 
                ;;
            2) 
                if verify_root_for_operation "Configuration Analysis"; then
                    analysis_menu
                else
                    read -p "Press Enter to continue..." input
                fi 
                ;;
            3) 
                if verify_root_for_operation "Task Manipulation"; then
                    manipulation_menu
                else
                    read -p "Press Enter to continue..." input
                fi 
                ;;
            4) reporting_menu ;;
            5) settings_menu ;;
            h|H) print_help; read -p "Press Enter to continue..." input ;;
            q|Q) exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Settings menu
function settings_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}${BOLD}SETTINGS${NC}"
        echo -e "${BLUE}1.${NC} Configure Report Path"
        echo -e "${BLUE}2.${NC} Toggle Verbose Mode"
        echo -e "${BLUE}3.${NC} Set Manipulation Safety Level"
        echo -e "${BLUE}4.${NC} Configure Logging"
        echo -e "${BLUE}5.${NC} Configure Sudo Preferences"
        echo -e "${BLUE}b.${NC} Back to Main Menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1) configure_report_path ;;
            2) toggle_verbose_mode ;;
            3) set_safety_level ;;
            4) configure_logging ;;
            5) configure_sudo_preferences ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Configure report path
function configure_report_path() {
    print_banner
    echo -e "${CYAN}${BOLD}CONFIGURE REPORT PATH${NC}"
    echo -e "Current report path: $REPORT_PATH"
    echo ""
    read -p "Enter new report path (or press Enter to keep current): " new_path
    
    if [ -n "$new_path" ]; then
        # Check if path exists, create if not
        if [ ! -d "$new_path" ]; then
            if confirm_action "Directory does not exist. Create it?" "y"; then
                mkdir -p "$new_path"
                if [ $? -ne 0 ]; then
                    status_message "Failed to create directory: $new_path" "error"
                    read -p "Press Enter to continue..." input
                    return
                fi
            else
                status_message "Operation cancelled" "warning"
                read -p "Press Enter to continue..." input
                return
            fi
        fi
        
        # Update config file
        sed -i "s|REPORT_PATH=.*|REPORT_PATH=\"$new_path\"|" "$SCRIPT_DIR/config/settings.conf"
        REPORT_PATH="$new_path"
        status_message "Report path updated to: $new_path" "success"
    else
        status_message "Report path unchanged" "info"
    fi
    
    read -p "Press Enter to continue..." input
}

# Toggle verbose mode
function toggle_verbose_mode() {
    print_banner
    echo -e "${CYAN}${BOLD}TOGGLE VERBOSE MODE${NC}"
    echo -e "Current verbose mode: $(if $VERBOSE_MODE; then echo "Enabled"; else echo "Disabled"; fi)"
    echo ""
    
    if confirm_action "Toggle verbose mode?" "y"; then
        if $VERBOSE_MODE; then
            sed -i "s|VERBOSE_MODE=.*|VERBOSE_MODE=false|" "$SCRIPT_DIR/config/settings.conf"
            VERBOSE_MODE=false
            status_message "Verbose mode disabled" "success"
        else
            sed -i "s|VERBOSE_MODE=.*|VERBOSE_MODE=true|" "$SCRIPT_DIR/config/settings.conf"
            VERBOSE_MODE=true
            status_message "Verbose mode enabled" "success"
        fi
    else
        status_message "Verbose mode unchanged" "info"
    fi
    
    read -p "Press Enter to continue..." input
}

# Set safety level
function set_safety_level() {
    print_banner
    echo -e "${CYAN}${BOLD}SET MANIPULATION SAFETY LEVEL${NC}"
    echo -e "Current safety level: $SAFETY_LEVEL (1=Low, 2=Medium, 3=High)"
    echo ""
    echo -e "Safety level controls how aggressive manipulation tests are:"
    echo -e "${RED}1. Low${NC} - Most aggressive, allows all manipulations"
    echo -e "${YELLOW}2. Medium${NC} - Balanced, some limitations on manipulations"
    echo -e "${GREEN}3. High${NC} - Most conservative, minimal system impact"
    echo ""
    read -p "Enter new safety level (1-3): " new_level
    
    if [[ "$new_level" =~ ^[1-3]$ ]]; then
        sed -i "s|SAFETY_LEVEL=.*|SAFETY_LEVEL=$new_level  # 1=Low, 2=Medium, 3=High|" "$SCRIPT_DIR/config/settings.conf"
        SAFETY_LEVEL=$new_level
        status_message "Safety level updated to: $new_level" "success"
    else
        status_message "Invalid safety level. Must be 1, 2, or 3." "error"
    fi
    
    read -p "Press Enter to continue..." input
}

# Configure logging
function configure_logging() {
    print_banner
    echo -e "${CYAN}${BOLD}CONFIGURE LOGGING${NC}"
    echo -e "Current log level: $LOG_LEVEL"
    echo -e "Current log file: $LOG_FILE"
    echo ""
    echo -e "1. Change log level"
    echo -e "2. Change log file location"
    echo -e "3. View logs"
    echo -e "b. Back"
    echo ""
    read -p "Select an option: " choice
    
    case $choice in
        1)
            echo ""
            echo -e "Available log levels:"
            echo -e "1. DEBUG (most verbose)"
            echo -e "2. INFO (standard information)"
            echo -e "3. WARNING (only warnings and errors)"
            echo -e "4. ERROR (only errors)"
            echo -e "5. NONE (disable logging)"
            echo ""
            read -p "Select log level: " level_choice
            
            case $level_choice in
                1) new_level="DEBUG" ;;
                2) new_level="INFO" ;;
                3) new_level="WARNING" ;;
                4) new_level="ERROR" ;;
                5) new_level="NONE" ;;
                *) 
                    status_message "Invalid choice. Keeping current setting." "error"
                    read -p "Press Enter to continue..." input
                    return
                    ;;
            esac
            
            sed -i "s|LOG_LEVEL=.*|LOG_LEVEL=\"$new_level\"|" "$SCRIPT_DIR/config/settings.conf"
            LOG_LEVEL="$new_level"
            status_message "Log level updated to: $new_level" "success"
            ;;
        2)
            echo ""
            read -p "Enter new log file path (or press Enter to keep current): " new_log_file
            
            if [ -n "$new_log_file" ]; then
                # Create directory if it doesn't exist
                log_dir=$(dirname "$new_log_file")
                if [ ! -d "$log_dir" ]; then
                    if mkdir -p "$log_dir" 2>/dev/null; then
                        status_message "Created log directory: $log_dir" "success"
                    else
                        status_message "Failed to create log directory. Keeping current setting." "error"
                        read -p "Press Enter to continue..." input
                        return
                    fi
                fi
                
                sed -i "s|LOG_FILE=.*|LOG_FILE=\"$new_log_file\"|" "$SCRIPT_DIR/config/settings.conf"
                LOG_FILE="$new_log_file"
                status_message "Log file updated to: $new_log_file" "success"
            fi
            ;;
        3)
            if [ -f "$LOG_FILE" ]; then
                less "$LOG_FILE"
            else
                status_message "Log file does not exist: $LOG_FILE" "error"
            fi
            ;;
        b|B) return ;;
        *) status_message "Invalid option" "error" ;;
    esac
    
    read -p "Press Enter to continue..." input
}

# Configure sudo preferences
function configure_sudo_preferences() {
    print_banner
    echo -e "${CYAN}${BOLD}CONFIGURE SUDO PREFERENCES${NC}"
    echo -e "Current sudo auto-ask setting: $(if $SUDO_AUTOASK; then echo "Enabled"; else echo "Disabled"; fi)"
    echo ""
    echo -e "When enabled, TaskThief will automatically prompt to elevate privileges for"
    echo -e "operations that require root access. When disabled, you will need to manually"
    echo -e "restart the application with sudo to perform these operations."
    echo ""
    
    if confirm_action "Toggle sudo auto-ask setting?" "y"; then
        if $SUDO_AUTOASK; then
            sed -i "s|SUDO_AUTOASK=.*|SUDO_AUTOASK=false|" "$SCRIPT_DIR/config/settings.conf"
            SUDO_AUTOASK=false
            status_message "Sudo auto-ask disabled" "success"
        else
            sed -i "s|SUDO_AUTOASK=.*|SUDO_AUTOASK=true|" "$SCRIPT_DIR/config/settings.conf"
            SUDO_AUTOASK=true
            status_message "Sudo auto-ask enabled" "success"
        fi
    else
        status_message "Sudo preferences unchanged" "info"
    fi
    
    read -p "Press Enter to continue..." input
}

# Verify root privileges for operations that require them
function verify_root_for_operation() {
    local operation_name="$1"
    local retry_option="${2:-true}"  # Whether to offer retry option

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}${BOLD}ERROR:${NC} The '$operation_name' operation requires root privileges."
        
        # Check if auto-ask is enabled and retry option is allowed
        if $SUDO_AUTOASK && $retry_option; then
            echo -e "${YELLOW}Would you like to restart with sudo to perform this operation?${NC}"
            if confirm_action "Restart with sudo?" "y"; then
                elevate_privileges "$@"
            else
                status_message "Operation cancelled." "warning"
                return 1
            fi
        else
            # If auto-ask is disabled, just inform the user
            if ! $SUDO_AUTOASK; then
                echo -e "${YELLOW}Note: Sudo auto-ask is disabled. You can enable it in Settings.${NC}"
                echo -e "${YELLOW}Restart TaskThief with sudo to access full functionality.${NC}"
            fi
            status_message "Operation cannot be completed without root privileges." "error"
            return 1
        fi
    fi
    
    return 0  # Root privileges confirmed
}

# Initialize application
function initialize() {
    # Create necessary directories if they don't exist
    mkdir -p "$SCRIPT_DIR/reports"
    mkdir -p "$SCRIPT_DIR/logs"
    
    # Load configuration
    if [ -f "$SCRIPT_DIR/config/settings.conf" ]; then
        source "$SCRIPT_DIR/config/settings.conf"
    else
        # Create default configuration
        mkdir -p "$SCRIPT_DIR/config"
        cat > "$SCRIPT_DIR/config/settings.conf" << EOF
# TaskThief Configuration
REPORT_PATH="$SCRIPT_DIR/reports"
VERBOSE_MODE=false
SAFETY_LEVEL=2  # 1=Low, 2=Medium, 3=High
LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR, NONE
LOG_FILE="$SCRIPT_DIR/logs/taskthief.log"
SUDO_AUTOASK=true  # Whether to automatically ask for sudo elevation
EOF
        source "$SCRIPT_DIR/config/settings.conf"
    fi
    
    # Initialize logging
    log_message "TaskThief started (version $VERSION)" "INFO"
}

# Process command line arguments
function process_args() {
    if [ $# -eq 0 ]; then
        return
    fi
    
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        -v|--version)
            echo "TaskThief version $VERSION"
            exit 0
            ;;
        -d|--discover)
            initialize
            run_full_discovery
            exit 0
            ;;
        -a|--analyze)
            initialize
            run_full_analysis
            exit 0
            ;;
        -r|--report)
            initialize
            generate_full_report
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
}

# Main entry point
check_dependencies
process_args "$@"
check_privileges "$@"
initialize
main_menu 