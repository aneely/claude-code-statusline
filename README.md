# Claude Code Custom Status Line

A custom status line configuration for [Claude Code](https://github.com/anthropics/claude-code) that displays session metrics and context usage visualization.

## What It Displays

The status line shows real-time session information in a robbyrussell-inspired format:

1. **Directory Name** (cyan) - Basename of the current working directory
2. **Git Branch & Status** (blue/red/yellow) - Branch name, dirty indicator if uncommitted changes
3. **Model Name** (cyan) - Current Claude model in use
4. **Output Style** (yellow) - Current output style (default/explanatory/concise)
5. **Context Window Usage** (green) - Percentage used/remaining
6. **Token Counts** (magenta) - Total input/output tokens
7. **Estimated Cost** (red) - Session cost estimate based on API pricing
8. **Vim Mode** (blue) - INSERT/NORMAL if vim mode is enabled

### Example Output

```
my-project git:(main) | Model: Sonnet 4.6 | Style: default | Context: 2.0% used (98.0% free) | Tokens: 4075 in / 766 out | Cost: $0.0234
```

Dirty repo:
```
my-project git:(main) x | Model: Sonnet 4.6 | Style: default | Context: 5.1% used (94.9% free) | Tokens: 9823 in / 1204 out | Cost: $0.0476
```

## How It Works

The status line is **event-driven**, not polling-based. The script executes when:
- A message is sent to Claude
- A message is received from Claude
- (Throttled to 300ms to prevent excessive runs)

This efficient design avoids constant background processes while keeping the display current with conversation flow.

## Installation

### 1. Copy the Script

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

### 2. Update Settings

Add this to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

If you already have other settings, merge the `statusLine` section into your existing JSON.

### 3. Restart Claude Code

Exit your current Claude Code session and start a new one. The status line should appear at the bottom of your terminal.

## Requirements

- **jq** - JSON processor for parsing Claude's state
  - macOS: `brew install jq`
  - Linux: `apt-get install jq` or `yum install jq`
- **bc** - Calculator for cost estimation (usually pre-installed)

## Customization

See [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) for:
- Changing colors
- Adding/removing metrics
- Adjusting formatting
- Available variables

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for:
- Status line not updating after settings changes
- Common escaping issues
- Debugging tips

## Cost Estimation

The cost is calculated using current API pricing (as of January 2025):
- Input tokens: $3 per million
- Output tokens: $15 per million

This is an **estimate** and may not reflect your actual costs if you have different pricing or enterprise agreements.

## Cursor CLI Support

**⚠️ Status Line Not Supported in Cursor CLI**

Unfortunately, Cursor CLI does not currently support status line configuration. This project was designed for Claude Code, which has built-in status line support.

## License

MIT License - feel free to modify and distribute.

## Contributing

Contributions welcome! If you have improvements or find bugs, please open an issue or pull request.
