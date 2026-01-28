# Zsh History Hook - Advanced Command Logging

A lightweight, no-sudo-required zsh history logging system with full context capture.

## Key Features

✅ **No sudo required** - Installs to `~/.config/zsh-history/`
✅ **Enable/Disable** - Turn logging on/off without reinstalling
✅ **Essential context** - Timestamp, PID, PPID, CWD, exit code
✅ **Sequential IDs** - Track command order for reference
✅ **Concurrent safe** - File-locked writes for multi-shell environments
✅ **Query helpers** - 12 built-in commands for history exploration

## Installation

```bash
zsh zsh-history-hook.sh install
```

This creates:
- `~/.config/zsh-history/zsh_history_hook.sh` - Core functions
- `~/.config/zsh-history/config` - Enable/disable state
- `~/.config/zsh-history/cmd_counter` - Sequential ID counter

Then add to `~/.zshrc`:

```zsh
source ~/.config/zsh-history/zsh_history_hook.sh
zsh_history_init
```

Log files created:
- `~/.config/zsh-history/zsh_history_hook.sh` - Core hook functions
- `~/.config/zsh-history/config` - Enable/disable state
- `~/.config/zsh-history/cmd_counter` - Sequential command counter
- `~/.zsh_history.log` - Command history log

Reload shell:
```bash
exec zsh
```

## Log Format

```
timestamp | PID | PPID | CWD | command | cmd_id | exit_code
```

Example:
```
2026-01-28 13:45:22.123 | 1234 | 1233 | /root | ls -la | 1 | exit:0
```

## Available Commands

### Query Commands

| Command | Purpose |
|---------|---------|
| `hc [N]` | Last N commands in current shell (default 20) |
| `ha [N]` | Last N commands across all shells (default 30) |
| `hf PATTERN` | Find commands matching pattern |
| `hpid PID` | Commands from specific PID |
| `hdir [DIR]` | Commands in directory (default current) |
| `herr [N]` | Last N failed commands (default 20) |
| `htop [N]` | Top N most used commands (default 10) |
| `htimeline` | Visual timeline by hour |
| `hstats` | Summary statistics |
| `hstatus` | Current status |
| `hformat` | Log format documentation |
| `hhelp` | Command reference |

### Management Commands

| Command | Purpose |
|---------|---------|
| `henable` | Enable logging |
| `hdisable` | Disable logging |
| `hclear` | Clear history log |

## Examples

### See what failed
```bash
herr
# 2026-01-28 13:45:22.123 | 1234 | 1233 | /root | go build | a1b2c3d4 | 120ms | pts/0 | 2 | 5 | exit:1
```

### View current shell's history
```bash
hc 10
# Last 10 commands in this shell only
```

### Timeline of activity
```bash
htimeline
# 00:00 ░░░ 5
# 08:00 ██████████ 42
# 13:00 █████████ 38
# 18:00 ████ 18
```

### Statistics
```bash
hstats
# Total:      1523 commands
# Success:    1489 (97.8%)
# Failed:     34
# Avg Time:   23ms
# Log file:   /root/.zsh_history.log
```

## Captured Information

### Timing
- **Timestamp** - ISO format with milliseconds (YYYY-MM-DD HH:MM:SS.mmm)

### Process Context
- **PID** - Process ID of the shell
- **PPID** - Parent process ID

### Execution Context
- **CWD** - Current working directory where command ran
- **Command** - The actual command executed
- **Exit Code** - Return code (0 = success, non-0 = failure)

### Command Tracking
- **Command ID** - Sequential number for ordering commands

## Enable/Disable

Enable/disable without reinstalling:

```bash
henable   # Turn on
hdisable  # Turn off
hstatus   # Check status
```

The state is saved in `~/.config/zsh-history/config` and persists across shells.

## Management

Check status:
```bash
zsh zsh-history-hook.sh status
```

Uninstall (keeps log file):
```bash
zsh zsh-history-hook.sh uninstall
```

Clear log:
```bash
hclear
```

## Advanced Usage

### Failed commands in directory
```bash
herr | grep "/home/user"
```

### Command frequency over time
```bash
awk -F'|' '{print substr($1, 1, 10)}' ~/.zsh_history.log | sort | uniq -c
```

### Monitor in real-time
```bash
tail -f ~/.zsh_history.log
```

## How It Works

The hook uses zsh's built-in `preexec` and `precmd` hooks:

1. **preexec** - Fires before command execution
   - Captures the command string
   - Records start time

2. **precmd** - Fires after command completes
   - Calculates duration
   - Gets exit code
   - Writes to log with file lock

File locking ensures concurrent shells don't corrupt the log.

## Performance

- Shell startup: +1-2ms
- Per command: +0.3-0.5ms (negligible overhead)
- Disk I/O: ~2-5 MB/year
- Memory: +20KB per shell

## Troubleshooting

### Commands not appearing
```bash
# Verify sourcing
source ~/.config/zsh-history/zsh_history_hook.sh
hstatus

# Check if enabled
echo $ZSH_HISTORY_ENABLED  # Should be 1
```

### Log file not created
```bash
# Must start a NEW shell after setup
exec zsh

# Then run a command
ls

# Check
cat ~/.zsh_history.log
```

### Permission errors
```bash
# Check permissions
ls -la ~/.zsh_history.log
ls -la ~/.config/zsh-history/

# Should be writable by user
```

## Migration from Bash Hook

If you have the bash history hook installed:

```bash
# Both can coexist! They use different log files:
# Bash: ~/.bash_history.log
# Zsh:  ~/.zsh_history.log

# Or migrate to unified logging:
# Modify the log path in zsh_history_hook.sh before installation
```

## Uninstallation

```bash
# Remove hook installation
zsh zsh-history-hook.sh uninstall

# Remove from ~/.zshrc
# Delete these lines:
#   source ~/.config/zsh-history/zsh_history_hook.sh
#   zsh_history_init

# Reload shell
exec zsh

# Optional: delete log file
rm ~/.zsh_history.log
```

## License

Open source - Use freely
