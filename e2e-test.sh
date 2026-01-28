#!/bin/zsh
################################################################################
# Zsh History Hook - End-to-End Test Script
# Run this from within the container after hook installation
################################################################################

echo "════════════════════════════════════════════════════════════════"
echo "Zsh History Hook - End-to-End Test"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Source the hook
source ~/.config/zsh-history/zsh_history_hook.sh

# Manually log test commands (for non-interactive shell testing)
# In interactive shells, preexec/precmd hooks handle this automatically
echo "Executing test commands..."

zsh_history_log_command 0 "ls -la /root"
zsh_history_log_command 0 "pwd"
zsh_history_log_command 0 "echo Test 1"
zsh_history_log_command 0 "echo Test 2"
zsh_history_log_command 0 "date"
zsh_history_log_command 0 "whoami"
zsh_history_log_command 0 "id"
zsh_history_log_command 0 "ps aux"

echo "✓ Test commands logged"
echo ""

# Verify log file
if [ ! -f ~/.zsh_history.log ]; then
    echo "❌ FAILED: History log not created"
    exit 1
fi

echo "✅ History log created"
echo ""

# Display log contents
echo "Log File Contents:"
echo "───────────────────────────────────────────────────────────"
cat ~/.zsh_history.log
echo "───────────────────────────────────────────────────────────"
echo ""

# Calculate statistics
TOTAL=$(wc -l < ~/.zsh_history.log)
SUCCESS=$(grep "exit:0$" ~/.zsh_history.log | wc -l)
FAILED=$((TOTAL - SUCCESS))
SUCCESS_RATE=$((SUCCESS * 100 / TOTAL))

# Display results
echo "Test Results:"
echo "  Total Commands:  $TOTAL"
echo "  Successful:      $SUCCESS"
echo "  Failed:          $FAILED"
echo "  Success Rate:    ${SUCCESS_RATE}%"
echo ""

# Display field format
echo "Log Format (7 fields, pipe-delimited):"
echo "  1. Timestamp     → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $1}' | xargs)"
echo "  2. PID           → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $2}' | xargs)"
echo "  3. PPID          → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $3}' | xargs)"
echo "  4. CWD           → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $4}' | xargs)"
echo "  5. Command       → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $5}' | xargs)"
echo "  6. Command ID    → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $6}' | xargs)"
echo "  7. Exit Code     → $(echo "$(head -1 ~/.zsh_history.log)" | awk -F'|' '{print $7}' | xargs)"
echo ""

echo "════════════════════════════════════════════════════════════════"
echo "✅ End-to-End Test PASSED"
echo "════════════════════════════════════════════════════════════════"
