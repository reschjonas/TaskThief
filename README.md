# TaskThief - Active Scheduled-Task-Manipulator

TaskThief is a tool for active testing of scheduled tasks and cron jobs. It identifies and evaluates misconfigurations in task schedulers (such as Linux Cron) that could lead to privilege escalation or persistent backdoors.

## Features

- **Enhanced Automatic Discovery**: Systematically collects information about existing scheduled tasks, cron jobs, and other schedulers, including permissions, triggers, and execution contexts. Includes detection of hidden tasks in udev rules, systemd path units, incron tasks, and more.
- **Configuration Analysis**: Evaluates the collected settings against best practices and identifies potential vulnerabilities, such as excessive permissions or faulty configurations that could lead to task hijacking.
- **Simulated Task Manipulation**: Performs controlled modifications to test if an attacker could modify existing tasks or insert their own tasks, demonstrating possible privilege escalation scenarios.
- **Comprehensive Reporting**: Generates detailed HTML and text reports that document found vulnerabilities, performed manipulations, and concrete improvement suggestions.
- **Improved Safety and Logging**: Enhanced backup and restore mechanisms along with configurable logging levels to keep track of all actions.
- **Privilege Management**: Smart handling of root privileges with ability to elevate permissions when needed for critical operations.
- **Modular Architecture**: Allows for easy extension with additional modules for other task schedulers or specific test methods, making the tool adaptable to new scenarios.
- **Command Line Interface**: Run specific operations directly from the command line with the new CLI options.

## Requirements

- Bash 4.0 or higher
- Linux operating system
- Root privileges for full functionality (can be provided via sudo)

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/reschjonas/TaskThief.git
   ```

2. Make the main script executable:
   ```
   chmod +x TaskThief/taskthief.sh
   ```

3. Run the tool:
   ```
   cd TaskThief
   ./taskthief.sh
   ```

## Usage

1. **Automatic Discovery** [Requires Root]
   - Identifies cron jobs, systemd timers, AT jobs, and anacron jobs.
   - Discovers hidden scheduled tasks like udev rules, startup scripts, and more.
   - Gathers detailed information about each scheduled task.

2. **Configuration Analysis** [Requires Root]
   - Analyzes cron jobs and systemd timers for security issues.
   - Checks for permission problems in configuration files.
   - Identifies weak configurations that could be exploited.

3. **Task Manipulation** [Requires Root]
   - Tests cron job hijacking by attempting controlled modifications.
   - Tests systemd timer manipulation to identify privilege escalation vectors.
   - Demonstrates how an attacker might create persistent backdoors.

4. **Reporting**
   - Generates comprehensive HTML or text reports.
   - Provides detailed findings and recommendations.
   - Exports results for documentation purposes.

## Privilege Management

TaskThief automatically detects when root privileges are required and offers options to:

1. Continue without root privileges (limited functionality)
2. Restart with sudo to gain full functionality 
3. Exit the application

For critical operations that require root access, TaskThief will prompt you to elevate privileges when needed.

## Command Line Options

TaskThief supports command line options for direct operation:

```
./taskthief.sh [OPTION]
```

**Options:**
- `-h`, `--help` - Display help message
- `-v`, `--version` - Display version information
- `-d`, `--discover` - Run full discovery immediately
- `-a`, `--analyze` - Run full analysis immediately
- `-r`, `--report` - Generate a full report immediately

## Enhanced Logging

TaskThief includes comprehensive logging capabilities with configurable log levels:
- **DEBUG** - Most verbose, logs all operations
- **INFO** - Standard information (default)
- **WARNING** - Only logs warnings and errors
- **ERROR** - Only logs errors
- **NONE** - Disables logging

Configure logging in the Settings menu or by editing the config file.

## Security Considerations

TaskThief is designed for legitimate security testing and educational purposes. When using this tool:

- Always ensure you have proper authorization to test the target systems.
- Use in a controlled environment when possible.
- Backup important files before running manipulation tests.
- Review all findings and manipulations carefully.

## Disclaimer

The tool performs active testing that modifies system files to demonstrate vulnerabilities. You should use this tool cautiously and only on systems you are authorized to test.

## License

MIT License

## Credits

Developed as a penetration testing tool for identifying vulnerabilities in scheduled task systems. 
Version 1.0.0