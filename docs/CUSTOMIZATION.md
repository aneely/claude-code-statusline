# Customization Guide

This guide shows you how to customize the status line to fit your preferences.

## Available Variables

Claude Code provides these variables via JSON input to your script:

| Variable | jq Path | Description | Example |
|----------|---------|-------------|---------|
| Model Name | `.model.display_name` | Current Claude model | "Sonnet 4.5" |
| Output Style | `.output_style.name` | Current output style | "default", "explanatory", "concise" |
| Context Used % | `.context_window.used_percentage` | Percentage of context used | 12.5 |
| Context Free % | `.context_window.remaining_percentage` | Percentage remaining | 87.5 |
| Input Tokens | `.context_window.total_input_tokens` | Total input tokens | 21015 |
| Output Tokens | `.context_window.total_output_tokens` | Total output tokens | 5224 |
| Vim Mode | `.vim.mode` | Vim mode if enabled | "INSERT", "NORMAL", empty |

## Changing Colors

The status line uses ANSI escape codes for colors. Here's the color reference:

```bash
# Color codes
\033[30m  # Black
\033[31m  # Red
\033[32m  # Green
\033[33m  # Yellow
\033[34m  # Blue
\033[35m  # Magenta
\033[36m  # Cyan
\033[37m  # White
\033[0m   # Reset to default
```

### Example: Change Model Name to Green

Find this line in `statusline.sh`:
```bash
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
```

And change the printf line from `\033[36m%s\033[0m` (cyan) to `\033[32m%s\033[0m` (green):
```bash
printf "Model: \033[32m%s\033[0m | ..." "$model" ...
```

## Adding New Metrics

### Example: Add Message Count

1. Extract the value from JSON:
```bash
# Add after existing extractions
msg_count=$(echo "$input" | jq -r '.message_count // 0')
```

2. Add to the printf statement:
```bash
printf "... | Messages: \033[35m%s\033[0m ..." \
  ... "$msg_count" ...
```

## Removing Metrics

### Example: Remove Cost Display

1. Delete or comment out the cost calculation:
```bash
# cost=$(echo "scale=4; ($total_in * 3 + $total_out * 15) / 1000000" | bc 2>/dev/null || echo "0")
```

2. Remove from printf:
```bash
# Before:
printf "... | Cost: \033[31m\$%s\033[0m%s" ... "$cost" "$vim_str"

# After:
printf "... %s" ... "$vim_str"
```

## Adjusting Number Formatting

### Change Decimal Places

For context percentage, change `%.1f` to `%.2f` for 2 decimal places:

```bash
# Before: Context: 2.0% used
printf "Context: \033[32m%.1f%%\033[0m used" "$used"

# After: Context: 2.00% used
printf "Context: \033[32m%.2f%%\033[0m used" "$used"
```

### Add Comma Separators to Token Counts

Replace the token display with formatted numbers:

```bash
# Add this function at the top of the script
format_number() {
  printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# Then use it:
formatted_in=$(format_number "$total_in")
formatted_out=$(format_number "$total_out")

printf "... | Tokens: \033[35m%s\033[0m in / \033[35m%s\033[0m out ..." \
  "$formatted_in" "$formatted_out"
```

## Common Customizations

### Minimal Status Line

Show only model and context:

```bash
#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

printf "Model: \033[36m%s\033[0m | Context: \033[32m%.1f%%\033[0m" "$model" "$used"
```

### Verbose Status Line

Add session duration, current file, etc. (if Claude provides these):

```bash
session_time=$(echo "$input" | jq -r '.session_duration // "0:00"')
current_file=$(echo "$input" | jq -r '.current_file // "none"')

printf "... | Time: %s | File: %s ..." "$session_time" "$current_file"
```

## Testing Your Changes

After editing `~/.claude/statusline.sh`:

1. Save the file
2. Send any message to Claude (even just "hi")
3. The status line will refresh with your changes

You don't need to restart Claude Code - the script is re-executed on every conversation event.

## Escaping Gotchas

### Variable Interpolation

When using variables in the printf format string, they must NOT be escaped in the variable assignment:

```bash
# WRONG - causes trailing quotes
vim_str=" | \033[34m\"${vim_mode}\"\033[0m"

# CORRECT
vim_str=" | \033[34m${vim_mode}\033[0m"
```

The printf itself handles all necessary escaping.

### Special Characters in Output

If you want to display literal `$` or `%` characters:

```bash
# Escape % in printf format
printf "Usage: 50%%"  # Displays: Usage: 50%

# Escape $ with backslash in strings
printf "Cost: \$%s" "$cost"  # Displays: Cost: $0.0234
```

## Advanced: Conditional Display

### Show Cost Only If Over Threshold

```bash
cost=$(echo "scale=4; ($total_in * 3 + $total_out * 15) / 1000000" | bc)

cost_str=""
if (( $(echo "$cost > 0.10" | bc -l) )); then
  cost_str=" | \033[31m⚠ Cost: \$${cost}\033[0m"
fi

printf "... %s" ... "$cost_str"
```

### Change Color Based on Context Usage

```bash
# Red if over 80%, yellow if over 50%, green otherwise
if (( $(echo "$used > 80" | bc -l) )); then
  color="\033[31m"  # Red
elif (( $(echo "$used > 50" | bc -l) )); then
  color="\033[33m"  # Yellow
else
  color="\033[32m"  # Green
fi

printf "Context: ${color}%.1f%%\033[0m used" "$used"
```

## Need Help?

If you're stuck or want to add a custom metric not documented here, check the troubleshooting guide or open an issue in the repository.
