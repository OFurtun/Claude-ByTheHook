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

# Copy hooks
echo "Installing hooks..."
cp "$SCRIPT_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh

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
