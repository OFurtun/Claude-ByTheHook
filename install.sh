#!/bin/bash
# Claude-ByTheHook Installer
# Installs safety hooks for Claude Code's bypass permissions mode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "========================================"
echo "  Claude-ByTheHook Installer"
echo "========================================"
echo ""

# Check for jq dependency
if ! command -v jq &> /dev/null; then
  echo "WARNING: 'jq' is not installed. Hooks require jq to parse JSON."
  echo "Install with: sudo apt install jq (Ubuntu/Debian) or brew install jq (macOS)"
  echo ""
fi

# Create directories
echo "Creating directories..."
mkdir -p "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/logs"

# Install hooks with existing file detection
echo "Installing hooks..."
echo ""

install_hook() {
  local src="$1"
  local filename=$(basename "$src")
  local dest="$CLAUDE_DIR/hooks/$filename"

  if [[ -f "$dest" ]]; then
    # Check if files differ
    if diff -q "$src" "$dest" &>/dev/null; then
      echo "  [OK] $filename - already up to date"
      return
    fi

    echo "  [!!] $filename - existing hook differs from repo version"
    echo ""
    echo "  Existing: $dest"
    echo "  New:      $src"
    echo ""

    # Show diff summary
    echo "  Changes:"
    diff --color=auto -u "$dest" "$src" | head -30 || true
    echo ""

    while true; do
      read -rp "  Replace existing $filename? [r]eplace / [s]kip / [b]ackup & replace: " choice
      case "$choice" in
        r|R|replace)
          cp "$src" "$dest"
          chmod +x "$dest"
          echo "  [OK] $filename - replaced"
          break
          ;;
        s|S|skip)
          echo "  [--] $filename - skipped"
          break
          ;;
        b|B|backup)
          backup="$dest.backup.$(date +%Y%m%d%H%M%S)"
          cp "$dest" "$backup"
          cp "$src" "$dest"
          chmod +x "$dest"
          echo "  [OK] $filename - backed up to $(basename "$backup") and replaced"
          break
          ;;
        *)
          echo "  Please enter r, s, or b"
          ;;
      esac
    done
  else
    cp "$src" "$dest"
    chmod +x "$dest"
    echo "  [OK] $filename - installed"
  fi

  echo ""
}

for hook_file in "$SCRIPT_DIR/hooks/"*.sh; do
  install_hook "$hook_file"
done

# Backup existing settings if present
if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
  backup_file="$CLAUDE_DIR/settings.json.backup.$(date +%Y%m%d%H%M%S)"
  cp "$CLAUDE_DIR/settings.json" "$backup_file"
  echo "Backed up existing settings to: $backup_file"
fi

echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Hooks installed to: $CLAUDE_DIR/hooks/"
echo ""
echo "Installed hooks:"
ls -la "$CLAUDE_DIR/hooks/"*.sh
echo ""
echo "========================================"
echo "  Next Steps"
echo "========================================"
echo ""
echo "1. Merge the hooks config into your settings.json:"
echo "   cat $SCRIPT_DIR/config/settings.json"
echo ""
echo "2. Test the hooks:"
echo "   # Should exit 0 (normal mode - skipped)"
echo "   echo '{\"permission_mode\":\"default\",\"tool_input\":{\"command\":\"rm -rf /\"}}' | bash ~/.claude/hooks/security-bash.sh; echo \"Exit code: \$?\""
echo ""
echo "   # Should exit 2 (bypass mode - blocked)"
echo "   echo '{\"permission_mode\":\"bypassPermissions\",\"tool_input\":{\"command\":\"rm -rf /\"}}' | bash ~/.claude/hooks/security-bash.sh; echo \"Exit code: \$?\""
echo ""
echo "3. Run Claude Code in bypass mode:"
echo "   claude --dangerously-skip-permissions"
echo ""
