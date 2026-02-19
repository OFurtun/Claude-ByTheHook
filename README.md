# Claude-ByTheHook

Safety hooks for Claude Code's bypass permissions mode (`--dangerously-skip-permissions`).

## Why This Exists

Claude Code's bypass mode (`--dangerously-skip-permissions`) removes all permission prompts for maximum speed. But this means Claude can execute any command without asking.

**Claude-ByTheHook** adds a safety layer using Claude Code's hooks system:
- **Deny rules** block truly catastrophic operations (always, in all modes)
- **Hooks** block risky operations (only in bypass mode)
- **Audit logging** tracks everything for review

## Features

- **Minimal deny rules** - Only block truly catastrophic operations (rm -rf /, fork bombs, disk destruction)
- **Smart hooks** - Bypass-mode-only protection for risky operations
- **Audit logging** - Track all operations for review
- **WSL-aware** - Protects Windows system directories from WSL access
- **Non-intrusive** - In normal mode, you can still approve any operation

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `jq` for JSON parsing: `sudo apt install jq` (Ubuntu) or `brew install jq` (macOS)

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/Claude-ByTheHook.git
cd Claude-ByTheHook
./install.sh
```

Then merge `config/settings.json` into your `~/.claude/settings.json`.

## Protection Layers

| Layer | When Active | What It Does | Can Override? |
|-------|-------------|--------------|---------------|
| **Deny Rules** | ALL modes | Block catastrophic ops | No - never |
| **Hooks** | BYPASS only | Block risky ops, warn on others | No in bypass |
| **Prompts** | NORMAL only | You approve everything | Yes - you decide |

## What's Protected

### Always Blocked (Deny Rules)
- `rm -rf /` and `rm -rf /*`
- Fork bombs
- Disk destruction (`dd of=/dev/sda`, `mkfs /dev/sda`)
- Windows system files from WSL (`/mnt/c/Windows`, `/mnt/c/Program Files`)
- Killing init process

### Blocked in Bypass Mode (Hooks)
- `chmod 777` and similar dangerous permissions
- Package publishing (`npm publish`, etc.)
- Force push to main/master
- Editing sensitive files (`.env`, credentials, SSH keys, etc.)
- Windows executable access (`cmd.exe`, `powershell.exe`)
- Piping downloads to shell (`curl | sh`)
- System directory modifications
- Edit/Write to mounted drives (`/mnt/`) — except `Desktop` directories (read-only access still allowed everywhere)

### Warnings in Bypass Mode
- `sudo` commands
- Force push to non-main branches
- `git reset --hard`, `git clean`
- Accessing `/mnt/` (Windows filesystem)

## Hooks Included

| Hook | Purpose |
|------|---------|
| `security-bash.sh` | Block dangerous bash commands |
| `protect-files.sh` | Protect sensitive files from editing; restrict mounted drive writes to Desktop only |
| `git-safety.sh` | Git operation safety checks |
| `audit-logger.sh` | Log all operations |
| `rate-limit.sh` | Prevent runaway loops (>500 ops/session) |

## Testing

After installation, test the hooks:

```bash
# Should exit 0 (normal mode - hooks skip)
echo '{"permission_mode":"default","tool_input":{"command":"rm -rf /"}}' | \
  bash ~/.claude/hooks/security-bash.sh
echo "Exit code: $?"

# Should exit 2 (bypass mode - blocked)
echo '{"permission_mode":"bypassPermissions","tool_input":{"command":"rm -rf /"}}' | \
  bash ~/.claude/hooks/security-bash.sh
echo "Exit code: $?"
```

## Viewing Audit Logs

```bash
# Today's log
cat ~/.claude/logs/audit-$(date +%Y-%m-%d).jsonl | jq .

# Filter by mode
grep '"mode":"bypassPermissions"' ~/.claude/logs/*.jsonl | jq .

# Count by tool type
cat ~/.claude/logs/*.jsonl | jq -r '.tool' | sort | uniq -c | sort -rn
```

## Customization

### Adding Protected Patterns

Edit `~/.claude/hooks/protect-files.sh` and add patterns to `PROTECTED_PATTERNS`:

```bash
PROTECTED_PATTERNS=(
  # ... existing patterns ...
  "my_custom_secret"
)
```

### Adjusting Rate Limits

Edit `~/.claude/hooks/rate-limit.sh`:

```bash
WARN_THRESHOLD=100   # Warn after this many ops
BLOCK_THRESHOLD=500  # Block after this many ops
```

## License

MIT
