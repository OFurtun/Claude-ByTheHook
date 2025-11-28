#!/bin/bash
# rate-limit.sh - Prevent runaway operations in bypass mode
# Part of Claude-ByTheHook

input=$(cat)

# ONLY RUN IN BYPASS MODE
permission_mode=$(echo "$input" | jq -r '.permission_mode // empty')
if [[ "$permission_mode" != "bypassPermissions" ]]; then
  exit 0
fi

# ============================================
# BYPASS MODE - Rate limiting
# ============================================
session_id=$(echo "$input" | jq -r '.session_id // "default"')

# Rate file per session
rate_file="/tmp/claude-rate-${session_id}.count"

# Increment counter
if [[ -f "$rate_file" ]]; then
  count=$(<"$rate_file")
  ((count++))
else
  count=1
fi
echo "$count" > "$rate_file"

# Thresholds
WARN_THRESHOLD=100
BLOCK_THRESHOLD=500

if [[ $count -gt $BLOCK_THRESHOLD ]]; then
  echo "BLOCKED: Rate limit ($count ops). Possible infinite loop." >&2
  exit 2
fi

if [[ $count -gt $WARN_THRESHOLD ]] && [[ $((count % 50)) -eq 0 ]]; then
  echo "WARNING: High operation count ($count)" >&2
fi

exit 0
