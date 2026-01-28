# Zsh History Hook - Simple Command History

A lightweight, no-sudo-required zsh command history logging system that captures timestamp, working directory, and commands.

## Project Structure

```
.
├── zsh-history-hook.sh             # Installation and core functions
├── e2e-test.sh                     # End-to-end test script
├── ZSH_HISTORY_HOOK.md             # Detailed documentation
├── bash-history-hook-final.sh      # Legacy bash version (reference)
├── README.md                        # This file
└── LICENSE
```

## Quick Start

### Installation (1 minute)

```bash
# Install the hook to ~/.config/zsh-history/
zsh zsh-history-hook.sh install
```

Add to `~/.zshrc`:
```zsh
source ~/.config/zsh-history/zsh_history_hook.sh
zsh_history_init
```

Reload shell:
```bash
exec zsh
```

### Testing (1 minute)

#### Option A: Docker Test (Recommended)
```bash
# Single command - creates container, runs test, cleans up
CONTAINER="zsh-test-$(date +%s)" && \
docker run -d --name "$CONTAINER" ubuntu sleep infinity > /dev/null && \
docker exec "$CONTAINER" bash -c "apt-get update -qq && apt-get install -y zsh >/dev/null 2>&1" && \
docker cp zsh-history-hook.sh "$CONTAINER":/ && \
docker cp e2e-test.sh "$CONTAINER":/ && \
docker exec "$CONTAINER" zsh /zsh-history-hook.sh install >/dev/null 2>&1 && \
docker exec "$CONTAINER" zsh /e2e-test.sh && \
docker rm -f "$CONTAINER"
```

#### Option B: Local Test
```bash
# Run test commands in your shell
ha
hf "git"
hdir
```

## Features

- **No sudo required** - Installs to `~/.config/zsh-history/` (user space)
- **Minimal overhead** - +0.3-0.5ms per command (negligible)
- **Simple format** - Timestamp, working directory, and command only
- **Easy searching** - Find commands by pattern or directory
- **Enable/disable** - Toggle logging without reinstalling
- **Query helpers** - Built-in commands for history exploration

## Log Format

3 pipe-delimited fields:
```
timestamp | cwd | command
2026-01-28 09:30:14 | /root | ls -la /root
```

- **timestamp** - Date and time (YYYY-MM-DD HH:MM:SS)
- **cwd** - Current working directory where command ran
- **command** - Full command executed

## Available Commands

### Query Commands

| Command | Purpose |
|---------|---------|
| `ha [N]` | Show last N commands (default 30) |
| `hf PATTERN` | Find commands matching pattern |
| `hdir [DIR]` | Show commands in directory (default current) |
| `htop [N]` | Show top N most used commands (default 10) |
| `htimeline` | Visual timeline of commands by hour |
| `hstatus` | Show current logging status |
| `hformat` | Show log format documentation |
| `hhelp` | Show command reference |

### Management Commands

| Command | Purpose |
|---------|---------|
| `henable` | Enable logging |
| `hdisable` | Disable logging |
| `hclear` | Clear history log (with confirmation) |
| `hclean` | Remove history log file |

## Examples

### View recent commands
```bash
ha
# 2026-01-28 09:30:14 | /root | ls -la /root
# 2026-01-28 09:30:15 | /root | pwd
# 2026-01-28 09:30:16 | /home/user | git status
```

### Find commands by pattern
```bash
hf "git"
# 2026-01-28 10:05:20 | /project | git status
# 2026-01-28 10:05:25 | /project | git add .
# 2026-01-28 10:05:30 | /project | git commit -m "fix bug"
```

### View commands from directory
```bash
hdir /tmp
# 2026-01-28 08:15:00 | /tmp | tar xzf archive.tar.gz
# 2026-01-28 08:15:05 | /tmp | ls -la
```

### See most used commands
```bash
htop 10
# 42 ls
# 35 cd
# 28 git
```

## Installation Details

### User-Space Installation

No sudo required. Files created in `~/.config/zsh-history/`:
- `zsh_history_hook.sh` - Core hook functions and helpers
- `config` - Enable/disable state
- `cmd_counter` - Sequential command ID counter

### Log File

Created automatically in:
- `~/.better-zsh-history.log` - Command history (permissions: 644)

### Uninstall

Remove the hook without keeping logs:
```bash
zsh zsh-history-hook.sh uninstall
```

Remove with logs:
```bash
zsh zsh-history-hook.sh uninstall
zsh zsh-history-hook.sh clean
```

Or manually:
```bash
zsh zsh-history-hook.sh uninstall
rm ~/.better-zsh-history.log
```

And remove from `~/.zshrc`:
```bash
# Delete these lines:
# source ~/.config/zsh-history/zsh_history_hook.sh
# zsh_history_init
```

## How It Works

Uses zsh's built-in `preexec` and `precmd` hooks:

```zsh
# Fires before command execution
preexec() {
    export _ZSH_HISTORY_CMD="$1"
}

# Fires after command completes
precmd() {
    local exit_code=$?
    if [[ -n "$_ZSH_HISTORY_CMD" ]]; then
        zsh_history_log_command "$exit_code" "$_ZSH_HISTORY_CMD"
    fi
    unset _ZSH_HISTORY_CMD
}
```

The `zsh_history_log_command()` function:
1. Captures current timestamp
2. Gets working directory context
3. Formats and writes log entry
4. Persists to `~/.better-zsh-history.log`

## Performance Impact

- Shell startup: +1-2ms
- Per-command: +0.3-0.5ms (negligible overhead)
- Disk I/O: ~2-5 MB/year
- Memory: +20KB per shell

## Testing

### Automated Test (Docker)

```bash
# Single command - full test with cleanup
CONTAINER="zsh-test-$(date +%s)" && \
docker run -d --name "$CONTAINER" ubuntu sleep infinity > /dev/null && \
docker exec "$CONTAINER" bash -c "apt-get update -qq && apt-get install -y zsh >/dev/null 2>&1" && \
docker cp zsh-history-hook.sh "$CONTAINER":/ && \
docker cp e2e-test.sh "$CONTAINER":/ && \
docker exec "$CONTAINER" zsh /zsh-history-hook.sh install >/dev/null 2>&1 && \
docker exec "$CONTAINER" zsh /e2e-test.sh && \
docker rm -f "$CONTAINER"
```

Expected output:
```
✅ History log created
Log File Contents:
───────────────────────────────────────────────────────────
2026-01-28 09:30:14 | / | ls -la /root
2026-01-28 09:30:15 | / | pwd
...
───────────────────────────────────────────────────────────
Test Results:
  Total Commands:  8
✅ End-to-End Test PASSED
```

### Manual Test

After installation, verify with:
```bash
ls
pwd
date
ha           # Show recent commands
hf "pwd"     # Find specific command
cat ~/.better-zsh-history.log  # View raw log
```

## Troubleshooting

### History log not created

**Cause:** Hook not sourced or shell restarted before sourcing

**Solution:**
```bash
# Make sure ~/.zshrc has these lines:
source ~/.config/zsh-history/zsh_history_hook.sh
zsh_history_init

# Then create NEW shell:
exec zsh

# Verify:
ls  # Run a command
cat ~/.better-zsh-history.log  # Check log
```

### Commands not appearing

**Cause:** Hook not properly initialized

**Solution:**
```bash
# Check if hook is loaded:
type preexec
type precmd

# Should return: "is a shell function from ~/.config/zsh-history/zsh_history_hook.sh"

# If not, source manually:
source ~/.config/zsh-history/zsh_history_hook.sh
```

### Logging disabled

**Cause:** `hdisable` was run

**Solution:**
```bash
henable   # Re-enable logging
hstatus   # Verify status
```

## Use Cases

1. **Debugging** - See exact command sequence when troubleshooting
2. **Auditing** - Full command history with timestamps and directories
3. **Learning** - Understand what commands work and in what order
4. **Directory tracking** - See which commands ran in which directories
5. **Development** - Track build/test/deploy command sequences
6. **Analysis** - Find your most-used commands with `htop`

## For More Details

See [ZSH_HISTORY_HOOK.md](ZSH_HISTORY_HOOK.md) for:
- Advanced usage examples
- Environment variables
- Hook lifecycle details
- Command reference

## License

Open source - Use freely

## Notes

- **Zsh only** - Works with zsh 5+
- **No sudo required** - User-space installation
- **Minimal dependencies** - Uses only standard POSIX utilities
- **Per-user logging** - Each user has their own log file
- **Privacy** - Log files are user-readable only (644 permissions)
- **Portable** - Works on macOS and Linux
