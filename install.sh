#!/bin/bash

# TaskThief Installer Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print banner
echo -e "${RED}${BOLD}"
echo -e "████████╗ █████╗ ███████╗██╗  ██╗████████╗██╗  ██╗██╗███████╗███████╗"
echo -e "╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝╚══██╔══╝██║  ██║██║██╔════╝██╔════╝"
echo -e "   ██║   ███████║███████╗█████╔╝    ██║   ███████║██║█████╗  █████╗  "
echo -e "   ██║   ██╔══██║╚════██║██╔═██╗    ██║   ██╔══██║██║██╔══╝  ██╔══╝  "
echo -e "   ██║   ██║  ██║███████║██║  ██╗   ██║   ██║  ██║██║███████╗██║     "
echo -e "   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝╚═╝     "
echo -e "${NC}"
echo -e "${YELLOW}${BOLD}Der aktive Scheduled-Task-Manipulator${NC}"
echo -e "${BLUE}Installation Script${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check system requirements
echo -e "${BOLD}Checking system requirements...${NC}"

# Check for Bash version
BASH_VERSION=$(bash --version | head -n1 | cut -d' ' -f4 | cut -d'.' -f1)
if [ "$BASH_VERSION" -lt 4 ]; then
    echo -e "${RED}[✗] Bash version 4.0 or higher is required. Found version $BASH_VERSION${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] Bash version $BASH_VERSION detected${NC}"
fi

# Check for Linux
if [ "$(uname)" != "Linux" ]; then
    echo -e "${RED}[✗] TaskThief requires a Linux operating system${NC}"
    exit 1
else
    echo -e "${GREEN}[✓] Linux detected: $(uname -sr)${NC}"
fi

# Make scripts executable
echo -e "\n${BOLD}Setting up TaskThief...${NC}"

chmod +x "$SCRIPT_DIR/taskthief.sh"

# Create necessary directories
mkdir -p "$SCRIPT_DIR/reports"
mkdir -p "$SCRIPT_DIR/config"
mkdir -p "$SCRIPT_DIR/logs"
mkdir -p "$SCRIPT_DIR/config/backups"

echo -e "${GREEN}[✓] Created necessary directories${NC}"

# Create default configuration if it doesn't exist
if [ ! -f "$SCRIPT_DIR/config/settings.conf" ]; then
    cat > "$SCRIPT_DIR/config/settings.conf" << EOF
# TaskThief Configuration
REPORT_PATH="$SCRIPT_DIR/reports"
VERBOSE_MODE=false
SAFETY_LEVEL=2  # 1=Low, 2=Medium, 3=High
EOF
    echo -e "${GREEN}[✓] Created default configuration${NC}"
else
    echo -e "${BLUE}[i] Configuration already exists${NC}"
fi

# Create symlink to /usr/local/bin if requested
echo -e "\n${BOLD}Would you like to create a symlink to TaskThief in /usr/local/bin?${NC}"
echo -e "${YELLOW}This will allow you to run TaskThief from anywhere by typing 'taskthief'${NC}"
echo -e "${YELLOW}Requires sudo/root privileges${NC}"
read -p "Create symlink? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Requesting sudo privileges to create symlink...${NC}"
        sudo ln -sf "$SCRIPT_DIR/taskthief.sh" /usr/local/bin/taskthief
    else
        ln -sf "$SCRIPT_DIR/taskthief.sh" /usr/local/bin/taskthief
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Created symlink at /usr/local/bin/taskthief${NC}"
    else
        echo -e "${RED}[✗] Failed to create symlink${NC}"
    fi
fi

# Installation complete
echo -e "\n${GREEN}${BOLD}TaskThief installation complete!${NC}"
echo -e "You can now run TaskThief by executing:"
echo -e "  ${BOLD}$SCRIPT_DIR/taskthief.sh${NC}"

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "Or simply type:"
    echo -e "  ${BOLD}taskthief${NC}"
fi

echo -e "\n${YELLOW}${BOLD}Note:${NC} Some features require root privileges to function properly."
echo -e "Consider running with sudo for full functionality."
echo -e "" 