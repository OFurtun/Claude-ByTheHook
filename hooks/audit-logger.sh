#!/bin/bash
# audit-logger.sh - Log all tool operations for review
# Part of Claude-ByTheHook

input=$(cat)

# ============================================
# AUDIT LOGGING - Runs in ALL modes
# (Logging has no security impact, useful always)
# ============================================
permission_mode=$(echo "$input" | jq -r '.permission_mode // "normal"')
tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cwd=$(echo "$input" | jq -r '.cwd // "unknown"')

# Create log directory
mkdir -p ~/.claude/logs

# Daily log file
log_file="$HOME/.claude/logs/audit-$(date +%Y-%m-%d).jsonl"

# Truncate tool input for log (avoid huge entries)
tool_input=$(echo "$input" | jq -c '.tool_input // {}' | head -c 500)

# Write audit entry
echo "{\"ts\":\"$timestamp\",\"mode\":\"$permission_mode\",\"session\":\"$session_id\",\"tool\":\"$tool_name\",\"cwd\":\"$cwd\",\"input\":$tool_input}" >> "$log_file"

exit 0
