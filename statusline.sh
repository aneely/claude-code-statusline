#!/bin/bash

# Read JSON from stdin
input=$(cat)

# Extract values using jq
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
style=$(echo "$input" | jq -r '.output_style.name // .outputStyle.name // "default"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# ESC character for embedding ANSI codes in variables (printf only interprets \033 in the format string, not in %s arguments)
ESC=$'\033'

# Calculate cost
cost=$(echo "scale=4; ($total_in * 3 + $total_out * 15) / 1000000" | bc 2>/dev/null || echo "0")

# Get current directory name (robbyrussell uses %c = basename of cwd)
if [ -n "$cwd" ]; then
  dir_name=$(basename "$cwd")
else
  dir_name=$(basename "$(pwd)")
fi

# Get git branch and status (robbyrussell style), skipping optional locks
git_str=""
if git -C "${cwd:-$(pwd)}" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "${cwd:-$(pwd)}" symbolic-ref --short HEAD 2>/dev/null || git -C "${cwd:-$(pwd)}" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if git -C "${cwd:-$(pwd)}" status --porcelain 2>/dev/null | grep -q .; then
      # dirty: blue "git:(" red branch blue ")" yellow "x"
      git_str=" ${ESC}[34mgit:(${ESC}[31m${branch}${ESC}[34m)${ESC}[33m x${ESC}[0m"
    else
      # clean: blue "git:(" red branch blue ")"
      git_str=" ${ESC}[34mgit:(${ESC}[31m${branch}${ESC}[34m)${ESC}[0m"
    fi
  fi
fi

# Build vim mode string if present
vim_str=""
if [ -n "$vim_mode" ]; then
  vim_str=" | ${ESC}[34m$vim_mode${ESC}[0m"
fi

# Print formatted status line:
# robbyrussell-style shell info, then Claude session info
printf "\033[36m%s\033[0m%s | Model: \033[36m%s\033[0m | Style: \033[33m%s\033[0m | Context: \033[32m%.1f%%\033[0m used (\033[32m%.1f%%\033[0m free) | Tokens: \033[35m%s\033[0m in / \033[35m%s\033[0m out | Cost: \033[31m\$%s\033[0m%s" \
  "$dir_name" "$git_str" "$model" "$style" "$used" "$remaining" "$total_in" "$total_out" "$cost" "$vim_str"
