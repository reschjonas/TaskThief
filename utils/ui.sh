#!/bin/bash

# TaskThief UI utilities

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Display a header for sections
function display_header() {
    local title="$1"
    local width=80
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo ""
    echo -e "${CYAN}${BOLD}$(printf '%*s' $width | tr ' ' '=')"
    echo -e "$(printf '%*s' $padding)${title}$(printf '%*s' $padding)"
    echo -e "$(printf '%*s' $width | tr ' ' '=')${NC}"
    echo ""
}

# Display status message
function status_message() {
    local message="$1"
    local status="$2" # success, warning, error, info
    
    case "$status" in
        success) echo -e "${GREEN}[✓] ${message}${NC}" ;;
        warning) echo -e "${YELLOW}[!] ${message}${NC}" ;;
        error) echo -e "${RED}[✗] ${message}${NC}" ;;
        info|*) echo -e "${BLUE}[i] ${message}${NC}" ;;
    esac
}

# Display progress bar
function progress_bar() {
    local current="$1"
    local total="$2"
    local message="$3"
    local width=50
    local percent=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r${message} [%-${width}s] %d%%" "$(printf '%*s' $completed | tr ' ' '#')" $percent
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Display a simple menu
function display_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    display_header "$title"
    
    for i in "${!options[@]}"; do
        echo -e "${BLUE}$((i+1)).${NC} ${options[i]}"
    done
    
    echo -e "${BLUE}b.${NC} Back"
    echo -e "${BLUE}q.${NC} Quit"
    echo ""
    read -p "Select an option: " choice
    
    echo "$choice"
}

# Wait for user confirmation
function confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        read -p "$message [Y/n]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        else
            return 0
        fi
    else
        read -p "$message [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Display a spinner for long-running tasks
function spinner() {
    local pid=$1
    local message="$2"
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r${BLUE}[%c]${NC} ${message}" "${spin:$i:1}"
        sleep 0.1
    done
    
    printf "\r${GREEN}[✓]${NC} ${message}\n"
}

# Display vulnerability severity level
function display_severity() {
    local severity="$1" # low, medium, high, critical
    
    case "$severity" in
        low) echo -e "${GREEN}${BOLD}[LOW]${NC}" ;;
        medium) echo -e "${YELLOW}${BOLD}[MEDIUM]${NC}" ;;
        high) echo -e "${RED}${BOLD}[HIGH]${NC}" ;;
        critical) echo -e "${RED}${BOLD}[CRITICAL]${NC}" ;;
        *) echo -e "${BLUE}[UNKNOWN]${NC}" ;;
    esac
} 