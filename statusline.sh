#!/bin/bash

# Read JSON from stdin
input=$(cat)

# Extract values using jq
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
style=$(echo "$input" | jq -r '.output_style.name // .outputStyle.name // "default"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Calculate cost
cost=$(echo "scale=4; ($total_in * 3 + $total_out * 15) / 1000000" | bc 2>/dev/null || echo "0")

# Build vim mode string if present
vim_str=""
if [ -n "$vim_mode" ]; then
  vim_str=" | \033[34m$vim_mode\033[0m"
fi

# Print formatted status line
printf "Model: \033[36m%s\033[0m | Output Style: \033[33m%s\033[0m | Context: \033[32m%.1f%%\033[0m used (\033[32m%.1f%%\033[0m free) | Tokens: \033[35m%s\033[0m in / \033[35m%s\033[0m out | Cost: \033[31m\$%s\033[0m%s" \
  "$model" "$style" "$used" "$remaining" "$total_in" "$total_out" "$cost" "$vim_str"
