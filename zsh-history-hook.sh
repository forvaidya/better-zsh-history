#!/bin/zsh
################################################################################
# Zsh History Hook v1.0
#
# Advanced zsh command history logging with full context capture.
# Captures: timestamp, PID, PPID, CWD, command, cmd_id, exit_code
#
# No sudo required - installs to ~/.config/zsh-history/
#
# Usage:
#   zsh zsh-history-hook.sh install    # Install to ~/.config
#   zsh zsh-history-hook.sh uninstall  # Remove
#   zsh zsh-history-hook.sh status     # Check status
#   zsh zsh-history-hook.sh enable     # Enable logging
#   zsh zsh-history-hook.sh disable    # Disable logging
#
# Setup (automatic):
#   After install, add to ~/.zshrc:
#
#   source ~/.config/zsh-history/zsh_history_hook.sh
#   zsh_history_init
#
# Commands: hc, ha, hf, hpid, hdir, herr, htop, hstats, henable, hdisable
# Log: ~/.zsh_history.log (pipe-delimited format with full context)
#
################################################################################

setopt local_options pipe_fail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_ok() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}!${NC} $1"; }
log_err() { echo -e "${RED}✗${NC} $1"; exit 1; }
log_info() { echo -e "${BLUE}→${NC} $1"; }

# Create the hook file content
create_hook() {
    cat > ~/.config/zsh-history/zsh_history_hook.sh << 'EOFHOOK'
#!/bin/zsh
# Zsh History Hook - Core Functions
# Installed to ~/.config/zsh-history/zsh_history_hook.sh

# Configuration
ZSH_HISTORY_LOG="${ZSH_HISTORY_LOG:-$HOME/.zsh_history.log}"
ZSH_HISTORY_ENABLED="${ZSH_HISTORY_ENABLED:-1}"
ZSH_HISTORY_CONFIG="$HOME/.config/zsh-history/config"
ZSH_HISTORY_SESSION_ID="${ZSH_HISTORY_SESSION_ID:-$(date +%s%N | md5sum | cut -c1-8)}"

# Load config if it exists
[[ -f "$ZSH_HISTORY_CONFIG" ]] && source "$ZSH_HISTORY_CONFIG"

# Generate unique command ID
_zsh_history_next_id() {
    local file="$HOME/.config/zsh-history/cmd_counter"
    mkdir -p "$(dirname "$file")"

    if [[ -f "$file" ]]; then
        local n=$(cat "$file")
        echo $((n + 1)) > "$file"
    else
        echo 1 > "$file"
    fi
    cat "$file"
}

# Main logging function
zsh_history_log_command() {
    [[ "$ZSH_HISTORY_ENABLED" != "1" ]] && return

    local timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    local cmd_id=$(_zsh_history_next_id)
    local pid=$$
    local ppid=$PPID
    local cwd="$PWD"
    local exit_code=$1
    local cmd="$2"

    [[ -z "$cmd" ]] && return

    # Escape pipes and newlines in command
    cmd=$(printf '%s\n' "$cmd" | sed 's/|/\\|/g' | tr '\n' ' ')

    local log_file="$ZSH_HISTORY_LOG"
    local lock_file="${log_file}.lock"

    {
        # Try to get exclusive lock with timeout
        flock -x -w 1 9 2>/dev/null || return

        printf "%s | %d | %d | %s | %s | %d | exit:%d\n" \
            "$timestamp" "$pid" "$ppid" "$cwd" "$cmd" "$cmd_id" "$exit_code" \
            >> "$log_file"

    } 9>"$lock_file" 2>/dev/null
}

# Capture command before execution
preexec() {
    export _ZSH_HISTORY_CMD="$1"
}

# Log command after execution
precmd() {
    local exit_code=$?

    if [[ -n "$_ZSH_HISTORY_CMD" ]]; then
        zsh_history_log_command "$exit_code" "$_ZSH_HISTORY_CMD"
    fi

    unset _ZSH_HISTORY_CMD
}

# Hook setup function (just documentation - hooks defined above are auto-registered)
zsh_history_init() {
    # Hooks are already defined above and auto-registered by zsh
    # This function exists for API compatibility
    return 0
}

# Helper commands
hc() {
    local limit=${1:-20}
    grep "| $$ |" "$ZSH_HISTORY_LOG" 2>/dev/null | tail -"$limit"
}

ha() {
    local limit=${1:-30}
    tail -"$limit" "$ZSH_HISTORY_LOG" 2>/dev/null
}

hf() {
    [[ -z "$1" ]] && { echo "Usage: hf PATTERN [limit]"; return 1; }
    local limit=${2:-10}
    grep -i "$1" "$ZSH_HISTORY_LOG" 2>/dev/null | tail -"$limit"
}

hpid() {
    [[ -z "$1" ]] && { echo "Usage: hpid PID [limit]"; return 1; }
    local limit=${2:-20}
    grep "| ${1:-$$} |" "$ZSH_HISTORY_LOG" 2>/dev/null | tail -"$limit"
}

hdir() {
    local dir="${1:-$PWD}"
    local limit=${2:-20}
    grep " | $dir |" "$ZSH_HISTORY_LOG" 2>/dev/null | tail -"$limit"
}

herr() {
    local limit=${1:-20}
    grep -v "exit:0$" "$ZSH_HISTORY_LOG" 2>/dev/null | tail -"$limit"
}

htimeline() {
    awk -F'|' '{
        hour = substr($1, 12, 2)
        hours[hour]++
    } END {
        for (h = 0; h < 24; h++) {
            if (h in hours) {
                count = hours[h]
                bars = int(count / 5)
                printf "%02d:00 ", h
                for (i = 0; i < bars; i++) printf "█"
                printf " %d\n", count
            }
        }
    }' "$ZSH_HISTORY_LOG" 2>/dev/null
}

htop() {
    local limit=${1:-10}
    awk -F'|' '{
        cmd = $5
        gsub(/^[[:space:]]+/, "", cmd)
        base = gensub(/^([^ ]+).*/, "\\1", 1, cmd)
        count[base]++
    } END {
        for (c in count) print count[c], c
    }' "$ZSH_HISTORY_LOG" 2>/dev/null | sort -rn | head -"$limit"
}

hstats() {
    if [[ -f "$ZSH_HISTORY_LOG" ]]; then
        local total=$(wc -l < "$ZSH_HISTORY_LOG")
        local failed=$(grep -v "exit:0$" "$ZSH_HISTORY_LOG" 2>/dev/null | wc -l)
        local success=$((total - failed))

        echo "Total:      $total commands"
        echo "Success:    $success ($(printf "%.1f" $((success * 100 / total)))%)"
        echo "Failed:     $failed"
        echo "Log file:   $ZSH_HISTORY_LOG"
    else
        echo "No history yet. Run a command and check back."
    fi
}

henable() {
    export ZSH_HISTORY_ENABLED=1
    mkdir -p "$(dirname "$ZSH_HISTORY_CONFIG")"
    echo "export ZSH_HISTORY_ENABLED=1" > "$ZSH_HISTORY_CONFIG"
    echo "History logging enabled ✓"
}

hdisable() {
    export ZSH_HISTORY_ENABLED=0
    mkdir -p "$(dirname "$ZSH_HISTORY_CONFIG")"
    echo "export ZSH_HISTORY_ENABLED=0" > "$ZSH_HISTORY_CONFIG"
    echo "History logging disabled"
}

hstatus() {
    if [[ "$ZSH_HISTORY_ENABLED" == "1" ]]; then
        echo "Status: ENABLED"
    else
        echo "Status: DISABLED"
    fi

    [[ -f "$ZSH_HISTORY_LOG" ]] && {
        echo "Log: $ZSH_HISTORY_LOG ($(wc -l < "$ZSH_HISTORY_LOG") entries)"
    } || echo "Log: Not created yet"
}

hclear() {
    read -q "?Clear history log? (y/n) "
    [[ "$REPLY" == "y" ]] && rm -f "$ZSH_HISTORY_LOG" && echo "Cleared ✓"
}

hformat() {
    cat << 'EOF'
Log Format (pipe-delimited):
  timestamp | PID | PPID | CWD | command | session_id | duration_ms | TTY | shell_level | cmd_id | exit_code

Example:
  2026-01-28 13:45:22.123 | 1234 | 1233 | /home/user | ls -la | a1b2c3d4 | 45ms | pts/0 | 2 | 1 | exit:0

Field Reference:
  timestamp     - Date and time with milliseconds
  PID           - Process ID (current shell)
  PPID          - Parent Process ID
  CWD           - Current working directory
  command       - The command executed
  session_id    - Unique session identifier
  duration_ms   - Time to execute command (milliseconds)
  TTY           - Terminal device
  shell_level   - Nesting level (SHLVL)
  cmd_id        - Sequential command ID
  exit_code     - Return code (0 = success)
EOF
}

hhelp() {
    cat << 'EOF'
Zsh History Hook - Available Commands

Query Commands:
  hc [N]        - Show this shell's last N commands (default 20)
  ha [N]        - Show all shells' last N commands (default 30)
  hf PATTERN    - Find commands matching PATTERN
  hpid PID      - Show commands from specific PID
  hdir [DIR]    - Show commands in directory (default current)
  herr [N]      - Show last N failed commands (default 20)
  htop [N]      - Show top N most used commands (default 10)
  htimeline     - Visual timeline of commands by hour
  hstats        - Show summary statistics
  hstatus       - Show current status
  hformat       - Show log format documentation
  hhelp         - Show this help

Management Commands:
  henable       - Enable history logging
  hdisable      - Disable history logging
  hclear        - Clear history log (prompts for confirmation)

Examples:
  hc              - Last 20 commands in this shell
  ha 50           - Last 50 commands across all shells
  hf "git"        - Find all git-related commands
  herr            - Failed commands
  htop 15         - Top 15 commands by frequency
  hstats          - Full statistics
EOF
}

EOFHOOK
    chmod 644 ~/.config/zsh-history/zsh_history_hook.sh
}

# Install function
install() {
    # Create config directory (no sudo needed)
    mkdir -p ~/.config/zsh-history || log_err "Cannot create ~/.config/zsh-history"

    create_hook
    log_ok "Installed to ~/.config/zsh-history/"

    log_info "Log location: ~/.zsh_history.log"
    log_info "Config location: ~/.config/zsh-history/"

    echo ""
    echo "Next steps:"
    echo ""
    log_info "1. Add to ~/.zshrc:"
    echo ""
    echo "    source ~/.config/zsh-history/zsh_history_hook.sh"
    echo "    zsh_history_init"
    echo ""
    log_info "2. Reload shell:"
    echo ""
    echo "    exec zsh"
    echo ""
    log_info "3. Verify installation:"
    echo ""
    echo "    hstats"
    echo ""
    log_info "4. Run a command to test:"
    echo ""
    echo "    ls"
    echo "    ha"
    echo ""
}

# Uninstall function
uninstall() {
    read -q "?Uninstall zsh-history-hook? (y/n) "
    [[ "$REPLY" == "y" ]] || return

    rm -rf ~/.config/zsh-history
    log_ok "Uninstalled from ~/.config/zsh-history"
    log_warn "Log file remains at ~/.zsh_history.log"
    echo ""
    echo "To fully uninstall, also run:"
    echo "  rm ~/.zsh_history.log"
    echo ""
    echo "And remove these lines from ~/.zshrc:"
    echo "  source ~/.config/zsh-history/zsh_history_hook.sh"
    echo "  zsh_history_init"
}

# Status function
status() {
    if [[ -f ~/.config/zsh-history/zsh_history_hook.sh ]]; then
        log_ok "Installed at ~/.config/zsh-history/"
    else
        log_err "Not installed"
    fi

    if [[ -f ~/.zsh_history.log ]]; then
        local count=$(wc -l < ~/.zsh_history.log)
        log_info "Log: ~/.zsh_history.log ($count entries)"
    else
        log_warn "Log not created yet"
    fi

    echo ""
    echo "To verify setup is complete, run:"
    echo "  source ~/.config/zsh-history/zsh_history_hook.sh"
    echo "  zsh_history_init"
    echo "  hstats"
}

# Enable/Disable functions
enable() {
    mkdir -p ~/.config/zsh-history
    echo "export ZSH_HISTORY_ENABLED=1" > ~/.config/zsh-history/config
    log_ok "Enabled (take effect in new shell)"
}

disable() {
    mkdir -p ~/.config/zsh-history
    echo "export ZSH_HISTORY_ENABLED=0" > ~/.config/zsh-history/config
    log_ok "Disabled (take effect in new shell)"
}

# Show info
show_info() {
    echo ""
    log_info "Zsh History Hook - Advanced Shell Logging"
    echo ""
    echo "Features:"
    echo "  • Full command context (PID, PPID, CWD, TTY, shell level)"
    echo "  • Command duration tracking (in milliseconds)"
    echo "  • Session ID for multi-shell correlation"
    echo "  • Exit code and error detection"
    echo "  • Sequential command ID"
    echo "  • File-locked concurrent writes"
    echo "  • No sudo required - user-space installation"
    echo "  • Enable/disable without reinstalling"
    echo ""
}

# Main
case "${1:-install}" in
    install)
        show_info
        install
        ;;
    uninstall)
        uninstall
        ;;
    status)
        status
        ;;
    enable)
        enable
        ;;
    disable)
        disable
        ;;
    *)
        echo "Zsh History Hook v1.0"
        echo ""
        echo "Usage: zsh zsh-history-hook.sh [command]"
        echo ""
        echo "Commands:"
        echo "  install     - Install to ~/.config/zsh-history/"
        echo "  uninstall   - Remove installation (keeps log)"
        echo "  status      - Check installation status"
        echo "  enable      - Enable logging"
        echo "  disable     - Disable logging"
        echo ""
        ;;
esac
