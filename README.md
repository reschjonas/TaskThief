# 🕵️ TaskThief

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-orange.svg)

**Advanced Security Testing Tool for Scheduled Tasks**

</div>

## 📋 Overview

TaskThief is a sophisticated security tool for active testing of scheduled tasks and cron jobs on Linux systems. It helps identify and evaluate misconfigurations in task schedulers that could lead to privilege escalation or persistent backdoors.

<div align="center">
  
```
🔍 Discover → 🛡️ Analyze → 🧪 Test → 📊 Report
```

</div>

## 🌟 Key Features

| Feature | Description |
|---------|-------------|
| 🔍 **Enhanced Discovery** | Systematically detects all scheduled tasks, including hidden ones in udev rules, systemd units, and more |
| 🛡️ **Configuration Analysis** | Evaluates settings against security best practices to identify potential vulnerabilities |
| 🧪 **Simulated Attacks** | Performs controlled modifications to test for privilege escalation vectors |
| 📊 **Comprehensive Reporting** | Generates detailed HTML and text reports with actionable recommendations |
| 📝 **Advanced Logging** | Configurable logging levels with enhanced backup and restore mechanisms |
| 🔐 **Smart Privilege Handling** | Intelligently manages root access requirements for operations |
| 🧩 **Modular Architecture** | Easily extensible with additional modules for other schedulers |
| ⌨️ **CLI Support** | Run specific operations directly from the command line |

## 🔧 Requirements

- Bash 4.0 or higher
- Linux operating system
- Root privileges for full functionality (can be provided via sudo)

## 📥 Installation

```bash
# Clone the repository
git clone https://github.com/reschjonas/TaskThief.git

# Navigate to the directory
cd TaskThief

# Make the script executable
chmod +x taskthief.sh

# Run TaskThief
./taskthief.sh
```

## 🚀 Usage

### Core Functionality

<details>
<summary><b>🔍 Automatic Discovery</b> [Requires Root]</summary>
<br>
• Identifies cron jobs, systemd timers, AT jobs, and anacron jobs<br>
• Discovers hidden scheduled tasks like udev rules, startup scripts, and more<br>
• Gathers detailed information about each scheduled task
</details>

<details>
<summary><b>🛡️ Configuration Analysis</b> [Requires Root]</summary>
<br>
• Analyzes cron jobs and systemd timers for security issues<br>
• Checks for permission problems in configuration files<br>
• Identifies weak configurations that could be exploited
</details>

<details>
<summary><b>🧪 Task Manipulation</b> [Requires Root]</summary>
<br>
• Tests cron job hijacking by attempting controlled modifications<br>
• Tests systemd timer manipulation to identify privilege escalation vectors<br>
• Demonstrates how an attacker might create persistent backdoors
</details>

<details>
<summary><b>📊 Reporting</b></summary>
<br>
• Generates comprehensive HTML or text reports<br>
• Provides detailed findings and recommendations<br>
• Exports results for documentation purposes
</details>

### 💻 Command Line Options

```bash
./taskthief.sh [OPTION]
```

| Option | Description |
|--------|-------------|
| `-h, --help` | Display help message |
| `-v, --version` | Display version information |
| `-d, --discover` | Run full discovery immediately |
| `-a, --analyze` | Run full analysis immediately |
| `-r, --report` | Generate a full report immediately |

### 🔐 Privilege Management

TaskThief automatically detects when root privileges are required and offers options to:

1. Continue without root privileges (limited functionality)
2. Restart with sudo to gain full functionality 
3. Exit the application

For critical operations that require root access, TaskThief will prompt you to elevate privileges when needed.

### 📝 Logging Levels

| Level | Description |
|-------|-------------|
| `DEBUG` | Most verbose, logs all operations |
| `INFO` | Standard information (default) |
| `WARNING` | Only logs warnings and errors |
| `ERROR` | Only logs errors |
| `NONE` | Disables logging |

Configure logging in the Settings menu or by editing the config file.

## ⚠️ Security Considerations

TaskThief is designed for legitimate security testing and educational purposes. When using this tool:

- ✅ Always ensure you have proper authorization to test the target systems
- ✅ Use in a controlled environment when possible
- ✅ Backup important files before running manipulation tests
- ✅ Review all findings and manipulations carefully

## ⚖️ Disclaimer

The tool performs active testing that modifies system files to demonstrate vulnerabilities. You should use this tool cautiously and only on systems you are authorized to test.

## 📄 License

This project is licensed under the MIT License - see the LICENSE.md file for details.

## 👥 Credits

Developed as a penetration testing tool for identifying vulnerabilities in scheduled task systems.

---

<div align="center">
  <sub>Built with ❤️ for security professionals and system administrators</sub>
</div>
