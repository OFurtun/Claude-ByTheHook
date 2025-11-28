#!/bin/bash
# git-safety.sh - Git operation safety checks in bypass mode
# Part of Claude-ByTheHook

input=$(cat)

# ONLY RUN IN BYPASS MODE
permission_mode=$(echo "$input" | jq -r '.permission_mode // empty')
if [[ "$permission_mode" != "bypassPermissions" ]]; then
  exit 0
fi

# ============================================
# BYPASS MODE - Git safety checks
# ============================================
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# === BLOCK: Force push to main/master ===
if [[ "$command" == *"git push"* ]] && \
   [[ "$command" == *"--force"* || "$command" == *"-f"* ]] && \
   [[ "$command" == *"main"* || "$command" == *"master"* ]]; then
  echo "BLOCKED: Force push to main/master not allowed" >&2
  exit 2
fi

# === WARN: Force push to other branches ===
if [[ "$command" == *"git push"* ]] && \
   [[ "$command" == *"--force"* || "$command" == *"-f"* ]]; then
  echo "WARNING: Force push detected - ensure you're on the right branch" >&2
fi

# === WARN: Dangerous git operations ===
if [[ "$command" == *"git reset --hard"* ]]; then
  echo "WARNING: git reset --hard may lose uncommitted changes" >&2
fi

if [[ "$command" == *"git clean -fd"* ]] || [[ "$command" == *"git clean -xfd"* ]]; then
  echo "WARNING: git clean will permanently delete untracked files" >&2
fi

if [[ "$command" == *"git stash drop"* ]] || [[ "$command" == *"git stash clear"* ]]; then
  echo "WARNING: Dropping stashes permanently deletes them" >&2
fi

exit 0
