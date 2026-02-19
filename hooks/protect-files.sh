#!/bin/bash
# protect-files.sh - Protect sensitive files in bypass mode
# Part of Claude-ByTheHook

input=$(cat)

# ONLY RUN IN BYPASS MODE
permission_mode=$(echo "$input" | jq -r '.permission_mode // empty')
if [[ "$permission_mode" != "bypassPermissions" ]]; then
  exit 0
fi

# ============================================
# BYPASS MODE - Protect sensitive files
# ============================================
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# Extended protection patterns (hooks can do substring matching)
PROTECTED_PATTERNS=(
  ".env"
  "password"
  "secret"
  "credential"
  "token"
  "apikey"
  "api_key"
  "private"
  ".pem"
  ".key"
  ".p12"
  ".pfx"
  "id_rsa"
  "id_ed25519"
  "id_ecdsa"
  ".npmrc"
  ".pypirc"
  ".netrc"
  ".docker/config"
  ".aws/credentials"
  ".ssh/config"
)

if [[ "$tool_name" == "Edit" ]] || [[ "$tool_name" == "Write" ]]; then
  file_lower=$(echo "$file_path" | tr '[:upper:]' '[:lower:]')
  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$file_lower" == *"$pattern"* ]]; then
      echo "BLOCKED: Protected file pattern '$pattern' in path" >&2
      exit 2
    fi
  done

  # Block Edit/Write on mounted drives, except Desktop directories
  if [[ "$file_path" == /mnt/* ]]; then
    if [[ "$file_path" == */Desktop/* ]]; then
      exit 0
    fi
    echo "BLOCKED: Write access to mounted drives restricted to Desktop only" >&2
    exit 2
  fi
fi

exit 0
