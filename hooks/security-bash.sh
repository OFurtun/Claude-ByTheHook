#!/bin/bash
# security-bash.sh - Block dangerous bash commands in bypass mode
# Part of Claude-ByTheHook

input=$(cat)

# ============================================
# ONLY RUN IN BYPASS MODE
# In normal mode, permission prompts protect you
# ============================================
permission_mode=$(echo "$input" | jq -r '.permission_mode // empty')
if [[ "$permission_mode" != "bypassPermissions" ]]; then
  exit 0
fi

# ============================================
# BYPASS MODE - Enforce safety checks
# ============================================
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# === BLOCK: Dangerous patterns ===
BLOCK_PATTERNS=(
  "rm -rf ~"
  "rm -rf *"
  "sudo rm -rf"
  "mv /* "
  "chmod -R 000"
  "chmod 777"
  "chmod -R 777"
)

for pattern in "${BLOCK_PATTERNS[@]}"; do
  if [[ "$command" == *"$pattern"* ]]; then
    echo "BLOCKED: Dangerous pattern '$pattern'" >&2
    exit 2
  fi
done

# === BLOCK: Windows executables from WSL ===
if [[ "$command" == *"cmd.exe"* ]] || \
   [[ "$command" == *"powershell.exe"* ]] || \
   [[ "$command" == *"pwsh.exe"* ]] || \
   [[ "$command" == *"reg.exe"* ]] || \
   [[ "$command" == *"wmic.exe"* ]]; then
  echo "BLOCKED: Windows executable access not allowed" >&2
  exit 2
fi

# === BLOCK: Network exfiltration patterns ===
if [[ "$command" =~ curl.*\|.*(sh|bash) ]] || \
   [[ "$command" =~ wget.*\|.*(sh|bash) ]]; then
  echo "BLOCKED: Piping download to shell not allowed" >&2
  exit 2
fi

# === BLOCK: Package publishing ===
if [[ "$command" == *"npm publish"* ]] || \
   [[ "$command" == *"yarn publish"* ]] || \
   [[ "$command" == *"twine upload"* ]]; then
  echo "BLOCKED: Package publishing not allowed in bypass mode" >&2
  exit 2
fi

# === BLOCK: System directory modifications ===
if [[ "$command" =~ (rm|mv|cp|chmod|chown).*/etc/ ]] || \
   [[ "$command" =~ (rm|mv|cp|chmod|chown).*/usr/ ]] || \
   [[ "$command" =~ (rm|mv|cp|chmod|chown).*/bin/ ]] || \
   [[ "$command" =~ (rm|mv|cp|chmod|chown).*/sbin/ ]]; then
  echo "BLOCKED: System directory modification not allowed" >&2
  exit 2
fi

# === BLOCK: History tampering ===
if [[ "$command" == *"history -c"* ]] || \
   [[ "$command" == *"> ~/.bash_history"* ]]; then
  echo "BLOCKED: History tampering not allowed" >&2
  exit 2
fi

# === WARN: sudo commands ===
if [[ "$command" == sudo* ]]; then
  echo "WARNING: sudo command detected - review carefully" >&2
fi

# === WARN: /mnt/ access (Windows filesystem) ===
if [[ "$command" == *"/mnt/"* ]]; then
  echo "WARNING: Accessing Windows filesystem" >&2
fi

exit 0
