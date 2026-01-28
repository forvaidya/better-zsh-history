#!/bin/bash
################################################################################
# Bash History Hook v1.0
# 
# A lightweight, zero-dependency command history logging system.
# Captures: timestamp, PID, PPID, CWD, command, exit_code
#
# Usage:
#   bash bash-history-hook.sh install    # Install
#   bash bash-history-hook.sh uninstall  # Uninstall  
#   bash bash-history-hook.sh status     # Check status
#
# Setup after install:
#   Add to ~/.zshrc or ~/.bashrc:
#
#   source /usr/local/lib/bash_history_hook.sh
#   preexec() { export _LAST_CMD="$1"; }
#   precmd() {
#       local code=$?
#       [[ -n "$_LAST_CMD" ]] && log_command_with_pid "$_LAST_CMD" $code
#       unset _LAST_CMD
#   }
#
#   Then: exec zsh
#
# Commands: hc, ha, hf, hpid, hdir, herr, htop, hstats
# Log: ~/.bash_history.log (timestamp | PID | PPID | CWD | cmd | exit_code)
#
################################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_ok() { echo -e "${GREEN}✓${NC} $1"; }
log_err() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Create the hook file content
create_hook() {
    cat > /usr/local/lib/bash_history_hook.sh << 'EOF'
#!/bin/bash
log_command_with_pid() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local pid=$$
    local ppid=$PPID
    local cwd="$PWD"
    local log_file="$HOME/.bash_history.log"
    local lock_file="${log_file}.lock"
    
    local exit_code="${@: -1}"
    local cmd="${@:1:$(($#-1))}"
    [[ $# -eq 1 ]] && { cmd="$1"; exit_code=0; }
    [[ -z "$cmd" ]] && return
    
    {
        flock -x -w 1 9 2>/dev/null || return
        echo "$timestamp | $pid | $ppid | $cwd | $cmd | exit:$exit_code" >> "$log_file"
    } 9>"$lock_file" 2>/dev/null
}

hc() { grep "| $$ |" ~/.bash_history.log 2>/dev/null | tail -${1:-20}; }
ha() { tail -${1:-30} ~/.bash_history.log 2>/dev/null; }
hf() { grep -i "$1" ~/.bash_history.log 2>/dev/null | tail -${2:-10}; }
hpid() { grep "| ${1:-$$} |" ~/.bash_history.log 2>/dev/null | tail -20; }
hdir() { grep " | $PWD |" ~/.bash_history.log 2>/dev/null | tail -20; }
herr() { grep -v "exit:0$" ~/.bash_history.log 2>/dev/null | tail -${1:-20}; }
htimeline() {
    grep "^" ~/.bash_history.log 2>/dev/null | awk -F'|' '{print substr($1,12,2)}' | \
    sort | uniq -c | awk '{for(i=0;i<$1/10;i++)printf "■"; print " " $2 ":00 (" $1 ")"}'
}
htop() {
    awk -F'|' '{cmd=$5; gsub(/^[[:space:]]+/,"",cmd); base=gensub(/^([^ ]+).*/,"\\1",1,cmd); count[base]++} END {for(c in count) print count[c], c}' \
    ~/.bash_history.log 2>/dev/null | sort -rn | head -${1:-10}
}
hstats() {
    [[ -f ~/.bash_history.log ]] && {
        echo "Entries: $(wc -l < ~/.bash_history.log) | Failed: $(grep -v "exit:0$" ~/.bash_history.log 2>/dev/null | wc -l)"
    } || echo "No history yet"
}
EOF
    chmod 644 /usr/local/lib/bash_history_hook.sh
}

# Install
install() {
    mkdir -p /usr/local/lib
    create_hook
    log_ok "Installed /usr/local/lib/bash_history_hook.sh"
    
    echo ""
    echo "Setup (add to ~/.zshrc or ~/.bashrc):"
    echo ""
    echo "  source /usr/local/lib/bash_history_hook.sh"
    echo "  preexec() { export _LAST_CMD=\"\$1\"; }"
    echo "  precmd() {"
    echo "      local code=\$?"
    echo "      [[ -n \"\$_LAST_CMD\" ]] && log_command_with_pid \"\$_LAST_CMD\" \$code"
    echo "      unset _LAST_CMD"
    echo "  }"
    echo ""
    echo "Then: exec zsh"
    echo ""
    echo "Commands: hc ha hf hpid hdir herr htop hstats"
    echo "Log: ~/.bash_history.log"
}

# Uninstall
uninstall() {
    rm -f /usr/local/lib/bash_history_hook.sh
    log_ok "Uninstalled"
    echo "Note: ~/.bash_history.log remains"
}

# Status
status() {
    [[ -f /usr/local/lib/bash_history_hook.sh ]] && log_ok "Installed" || log_err "Not installed"
    [[ -f ~/.bash_history.log ]] && echo "Log: $(wc -l < ~/.bash_history.log) entries"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    status) status ;;
    *) echo "Usage: $0 [install|uninstall|status]" ;;
esac
