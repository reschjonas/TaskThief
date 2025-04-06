#!/bin/bash

# TaskThief common utilities

# Check if a command exists
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get current timestamp
function get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Get current date in YYYY-MM-DD format
function get_date() {
    date +"%Y-%m-%d"
}

# Enhanced logging with log levels
function log_message() {
    local message="$1"
    local level="${2:-INFO}"
    local log_file="${3:-$LOG_FILE}"
    
    # Skip logging if LOG_LEVEL is NONE
    if [[ "$LOG_LEVEL" == "NONE" ]]; then
        return
    fi
    
    # Check if log level is appropriate based on configured level
    case "$LOG_LEVEL" in
        "DEBUG")
            # Log everything
            ;;
        "INFO")
            # Skip DEBUG logs
            if [[ "$level" == "DEBUG" ]]; then
                return
            fi
            ;;
        "WARNING")
            # Skip DEBUG and INFO logs
            if [[ "$level" == "DEBUG" || "$level" == "INFO" ]]; then
                return
            fi
            ;;
        "ERROR")
            # Only log ERRORs
            if [[ "$level" != "ERROR" ]]; then
                return
            fi
            ;;
    esac
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$log_file")"
    
    # Log message with timestamp
    echo "[$(get_timestamp)] [$level] $message" >> "$log_file"
    
    # If verbose mode is on, also print to stdout
    if $VERBOSE_MODE; then
        case "$level" in
            "ERROR")
                echo -e "${RED}[$level] $message${NC}" >&2
                ;;
            "WARNING")
                echo -e "${YELLOW}[$level] $message${NC}" >&2
                ;;
            "INFO")
                echo -e "${BLUE}[$level] $message${NC}"
                ;;
            "DEBUG")
                echo -e "${CYAN}[$level] $message${NC}"
                ;;
        esac
    fi
}

# Validate if a user exists
function user_exists() {
    id "$1" &>/dev/null
}

# Get current user ID
function get_current_user() {
    whoami
}

# Check if a file is executable
function is_executable() {
    [[ -x "$1" ]]
}

# Check if a file is writable
function is_writable() {
    [[ -w "$1" ]]
}

# Check if a file is readable
function is_readable() {
    [[ -r "$1" ]]
}

# Check if a path is a valid directory
function is_directory() {
    [[ -d "$1" ]]
}

# Check if a file exists
function file_exists() {
    [[ -f "$1" ]]
}

# Get file permissions in human-readable format
function get_permissions() {
    ls -la "$1" | awk '{print $1}'
}

# Get file owner
function get_owner() {
    stat -c '%U' "$1"
}

# Get file group
function get_group() {
    stat -c '%G' "$1"
}

# Convert permissions to numeric format (e.g. 0755)
function get_numeric_permissions() {
    stat -c '%a' "$1"
}

# Get last modified time of a file
function get_file_modified_time() {
    stat -c '%y' "$1"
}

# Calculate SHA256 hash of a file
function get_file_hash() {
    if command_exists sha256sum; then
        sha256sum "$1" | cut -d' ' -f1
    elif command_exists shasum; then
        shasum -a 256 "$1" | cut -d' ' -f1
    else
        log_message "Hash calculation not available - sha256sum or shasum required" "WARNING"
        echo "hash-unavailable"
    fi
}

# Safely create a temporary file
function create_temp_file() {
    local prefix="${1:-taskthief}"
    mktemp "/tmp/${prefix}.XXXXXX"
}

# Safely create a temporary directory
function create_temp_dir() {
    local prefix="${1:-taskthief}"
    mktemp -d "/tmp/${prefix}.XXXXXX"
}

# Clean up temporary files
function cleanup_temp_files() {
    local pattern="${1:-/tmp/taskthief.*}"
    rm -rf $pattern 2>/dev/null
}

# Escape special characters in strings for safe command usage
function escape_string() {
    echo "$1" | sed 's/["\$\`\\]/\\&/g'
}

# Check if running on a supported Linux distribution
function check_distribution() {
    if command_exists lsb_release; then
        lsb_release -d | cut -f2-
    elif [ -f /etc/os-release ]; then
        cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2- | tr -d '"'
    else
        echo "Unknown"
    fi
}

# Get kernel version
function get_kernel_version() {
    uname -r
}

# Check if a string is a valid IP address
function is_valid_ip() {
    local ip="$1"
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    
    return $stat
}

# Get system hostname
function get_hostname() {
    hostname
}

# Create a directory if it doesn't exist
function ensure_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# Check if the script is being run as root
function is_root() {
    [[ $EUID -eq 0 ]]
}

# Generate a random string
function generate_random_string() {
    local length="${1:-12}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Safely backup a file before modifying it
function safe_backup() {
    local file="$1"
    local backup_dir="$2"
    local backup_file
    
    # Create backup directory if it doesn't exist
    ensure_directory "$backup_dir"
    
    # Generate backup filename with timestamp
    backup_file="${backup_dir}/$(basename "$file").$(get_date).$(date +%H%M%S).bak"
    
    # Copy the file
    if cp "$file" "$backup_file" 2>/dev/null; then
        log_message "Created backup of $file at $backup_file" "INFO"
        echo "$backup_file"
    else
        log_message "Failed to create backup of $file" "ERROR"
        return 1
    fi
}

# Verify file integrity by comparing with a backup
function verify_file_integrity() {
    local file="$1"
    local backup="$2"
    
    if [ ! -f "$file" ] || [ ! -f "$backup" ]; then
        return 1
    fi
    
    local file_hash=$(get_file_hash "$file")
    local backup_hash=$(get_file_hash "$backup")
    
    [[ "$file_hash" == "$backup_hash" ]]
}

# Safely write content to a file
function safe_write_file() {
    local file="$1"
    local content="$2"
    local temp_file
    
    # Create a temporary file
    temp_file=$(create_temp_file)
    
    # Write content to temporary file
    echo "$content" > "$temp_file"
    
    # Move temporary file to destination
    if mv "$temp_file" "$file" 2>/dev/null; then
        log_message "Successfully wrote to $file" "INFO"
        return 0
    else
        log_message "Failed to write to $file" "ERROR"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
}

# Check if a file has SUID or SGID bit set
function has_suid_sgid() {
    local file="$1"
    local perms
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    perms=$(get_numeric_permissions "$file")
    
    # Check for SUID (4) or SGID (2) in the first digit
    [[ "${perms:0:1}" =~ [4-7] ]] || [[ "${perms:1:1}" =~ [2367] ]]
} 