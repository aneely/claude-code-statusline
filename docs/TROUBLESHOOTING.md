# Troubleshooting Guide

Common issues and solutions when working with Claude Code status lines.

## Status Line Not Updating After Settings Changes

### Problem

You run `/output-style` or other settings commands, but the status line still shows the old value.

### Why This Happens

The status line is **event-driven**, not polling-based. It only updates when:
- A message is sent to Claude
- A message is received from Claude

Commands like `/output-style` modify the settings JSON file directly, but this doesn't trigger a conversation event, so the status line doesn't refresh.

### Solution

**Send any message** to Claude after changing settings. Even just typing "hi" will trigger a conversation event and refresh the status line with the updated settings.

### This Is Expected Behavior

This is not a bug - it's how Claude Code's status line system works. The refresh mechanism is tied to conversation flow, not file system changes. There's no way to force immediate updates when settings change via commands.

**The one-message delay is normal and unavoidable.**

## Trailing Quotes or Escaped Characters in Output

### Problem

Your status line shows weird characters like trailing quotes:

```
... | Vim Mode: "NORMAL" ...
```

Or escaped sequences:

```
... | Vim Mode: \"NORMAL\" ...
```

### Why This Happens

Shell variable interpolation and printf escaping can conflict. When you assign a variable with escaped quotes, those escape characters may appear literally in the output.

### Solution

**Don't escape variables in assignments.** The printf statement handles all necessary escaping.

```bash
# WRONG - causes trailing quotes
vim_str=" | \033[34m\"${vim_mode}\"\033[0m"

# CORRECT
vim_str=" | \033[34m${vim_mode}\033[0m"
```

### Fixed in Version

This issue was identified and fixed in commit `settings.json:5` on 2026-01-20.

## Status Line Not Showing At All

### Problem

No status line appears at the bottom of your terminal.

### Checklist

1. **Is the script executable?**
   ```bash
   chmod +x ~/.claude/statusline.sh
   ```

2. **Is jq installed?**
   ```bash
   which jq
   # If not found, install it:
   # macOS: brew install jq
   # Linux: apt-get install jq
   ```

3. **Is settings.json valid?**
   ```bash
   jq . ~/.claude/settings.json
   # Should parse without errors
   ```

4. **Is the path correct in settings?**
   - Settings use `~/.claude/statusline.sh`
   - Script is actually at `/Users/yourname/.claude/statusline.sh`
   - The `~` should expand correctly, but try absolute path if issues persist

5. **Did you restart Claude Code?**
   - Settings changes require a restart
   - Exit completely and start a new session

### Debug the Script Manually

Test the script directly:

```bash
# Create test input
echo '{"model":{"display_name":"Test"},"output_style":{"name":"default"},"context_window":{"used_percentage":10,"remaining_percentage":90,"total_input_tokens":1000,"total_output_tokens":500},"vim":{"mode":"NORMAL"}}' | ~/.claude/statusline.sh
```

This should output a formatted status line. If it errors, you'll see what's wrong.

## Cost Calculation Shows 0 or Wrong Value

### Problem

Cost always shows `$0.0000` or an incorrect amount.

### Possible Causes

1. **bc not installed** - The script uses `bc` for floating-point math
   ```bash
   which bc
   # If not found, install it (usually pre-installed on macOS/Linux)
   ```

2. **bc calculation failing silently** - The `2>/dev/null || echo "0"` suppresses errors
   - Remove the error suppression temporarily to debug:
   ```bash
   cost=$(echo "scale=4; ($total_in * 3 + $total_out * 15) / 1000000" | bc)
   ```

3. **Token counts are 0** - Early in a session, costs may be negligible
   - Check the actual token counts in the status line
   - If those are 0, the cost calculation is correct

### Update Pricing

The script uses:
- $3 per million input tokens
- $15 per million output tokens

If pricing changes, update line 16 in `statusline.sh`:

```bash
# Old pricing
cost=$(echo "scale=4; ($total_in * 3 + $total_out * 15) / 1000000" | bc)

# New pricing (example: $5 in, $20 out)
cost=$(echo "scale=4; ($total_in * 5 + $total_out * 20) / 1000000" | bc)
```

## Colors Not Showing

### Problem

Status line displays with escape codes visible instead of colors:

```
Model: \033[36mSonnet 4.5\033[0m | ...
```

### Why This Happens

Your terminal doesn't support ANSI color codes, or color output is disabled.

### Solutions

1. **Use a modern terminal**
   - macOS: Terminal.app, iTerm2
   - Linux: GNOME Terminal, Konsole, Alacritty
   - Windows: Windows Terminal, WSL2

2. **Enable color support**
   ```bash
   export TERM=xterm-256color
   ```

3. **Check if colors work**
   ```bash
   printf "\033[31mRed\033[0m \033[32mGreen\033[0m \033[34mBlue\033[0m\n"
   ```

If colors still don't work, your terminal may not support them. Consider switching terminals or removing color codes from the script.

## Status Line Too Long

### Problem

Status line wraps to multiple lines or gets cut off.

### Solutions

1. **Remove less important metrics** - See CUSTOMIZATION.md for removing fields

2. **Abbreviate labels**
   ```bash
   # Before: "Output Style:"
   # After:  "Style:"
   ```

3. **Use shorter color names**
   ```bash
   # Before: "Model: Sonnet 4.5"
   # After:  "Sonnet 4.5"
   ```

4. **Conditional display** - Only show some metrics when relevant
   ```bash
   # Only show cost if over $0.10
   if (( $(echo "$cost > 0.10" | bc -l) )); then
     cost_str=" | Cost: \$${cost}"
   fi
   ```

## jq Parse Errors

### Problem

Errors like:
```
jq: parse error: Invalid numeric literal at line 1, column 10
```

### Why This Happens

The JSON input from Claude is malformed or the jq path doesn't exist.

### Solutions

1. **Add fallback values** - Already implemented in the script with `// "default"`:
   ```bash
   style=$(echo "$input" | jq -r '.output_style.name // .outputStyle.name // "default"')
   ```

2. **Debug the input**
   ```bash
   # Add this at the top of statusline.sh temporarily
   echo "$input" > /tmp/statusline-debug.json
   ```

   Then inspect `/tmp/statusline-debug.json` to see what Claude is sending.

3. **Handle missing fields**
   ```bash
   # Use 'empty' for fields that might not exist
   vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
   ```

## Vim Mode Not Showing

### Problem

Vim mode is enabled but doesn't appear in the status line.

### Checklist

1. **Is vim mode actually enabled in settings?**
   ```bash
   jq '.vim.enabled' ~/.claude/settings.json
   # Should return: true
   ```

2. **Is vim mode active?**
   - Vim mode only shows when you're in INSERT or NORMAL mode
   - If Claude is processing, mode might be empty

3. **Check the conditional**
   ```bash
   # The script only shows vim mode if the variable is non-empty
   if [ -n "$vim_mode" ]; then
     vim_str=" | \033[34m$vim_mode\033[0m"
   fi
   ```

## Script Works But Settings Don't Apply

### Problem

You edit `~/.claude/statusline.sh` but changes don't appear.

### Possible Causes

1. **Editing wrong file**
   - Make sure you're editing the same file referenced in settings.json
   - Check: `cat ~/.claude/settings.json | grep command`

2. **Script cached**
   - Unlikely, but try clearing any shell caches
   - Or rename the script and update settings.json

3. **Settings.json not reloaded**
   - Restart Claude Code completely
   - Confirm settings with: `cat ~/.claude/settings.json`

4. **Syntax error in script**
   - Test script manually (see "Debug the Script Manually" above)
   - Bash will silently fail if there's a syntax error

## Performance Issues

### Problem

Claude Code feels slow or laggy.

### Is it the status line?

Unlikely - the script is very lightweight. But to test:

1. **Temporarily disable it**
   ```json
   {
     "statusLine": {
       "type": "none"
     }
   }
   ```

2. **Restart and test performance**

If performance improves significantly, the issue might be:
- Complex calculations in your custom script
- External API calls (don't do this!)
- Large data processing

The default script runs in ~10ms and shouldn't cause any perceptible slowdown.

## Still Stuck?

If you're experiencing an issue not covered here:

1. **Test the script manually** (see above) to isolate the problem
2. **Check Claude Code documentation** for status line requirements
3. **Open an issue** in this repository with:
   - Your `~/.claude/settings.json` (redact any sensitive data)
   - Your `~/.claude/statusline.sh` script
   - The error message or unexpected behavior
   - Output from testing the script manually
