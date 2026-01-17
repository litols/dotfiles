#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
transcript_path=$(echo "$input" | jq -r '.transcript_path')
model_display=$(echo "$input" | jq -r '.model.display_name')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Function to abbreviate directory path (all but current directory to 1 char)
abbreviate_path() {
    local path="$1"
    local home="$HOME"

    # Replace home with ~
    path="${path/#$home/~}"

    # Split path into components
    IFS='/' read -ra parts <<< "$path"
    local result=""
    local last_idx=$((${#parts[@]} - 1))

    for i in "${!parts[@]}"; do
        if [ $i -eq $last_idx ]; then
            # Last component (current directory) - keep full name
            result+="${parts[$i]}"
        elif [ "${parts[$i]}" = "~" ]; then
            # Keep tilde as-is
            result+="~/"
        elif [ -n "${parts[$i]}" ]; then
            # Abbreviate to first character
            result+="${parts[$i]:0:1}/"
        elif [ $i -eq 0 ]; then
            # Handle leading slash for absolute paths
            result+="/"
        fi
    done

    echo "$result"
}

# Get abbreviated path
abbrev_path=$(abbreviate_path "$cwd")

# Get git branch and status (skip optional locks)
git_branch=""
git_status_indicators=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null || \
                 git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

    if [ -n "$git_branch" ]; then
        # Get git status
        status_output=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)

        # Check for modified/staged files (!)
        has_changes=""
        if echo "$status_output" | grep -q '^[MADRCU]'; then
            has_changes="!"
        elif echo "$status_output" | grep -q '^.[MADRCU]'; then
            has_changes="!"
        fi

        # Check for untracked files (?)
        has_untracked=""
        if echo "$status_output" | grep -q '^??'; then
            has_untracked="?"
        fi

        # Check ahead/behind remote
        upstream=""
        ahead_behind=""
        upstream=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref @{upstream} 2>/dev/null)
        if [ -n "$upstream" ]; then
            count=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count "$upstream"...HEAD 2>/dev/null)
            behind=$(echo "$count" | awk '{print $1}')
            ahead=$(echo "$count" | awk '{print $2}')

            if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
                ahead_behind="⇕"
            elif [ "$ahead" -gt 0 ]; then
                ahead_behind="⇡"
            elif [ "$behind" -gt 0 ]; then
                ahead_behind="⇣"
            fi
        fi

        # Combine status indicators
        if [ -n "$has_changes" ] || [ -n "$has_untracked" ] || [ -n "$ahead_behind" ]; then
            git_status_indicators=" [${has_changes}${has_untracked}${ahead_behind}]"
        fi
    fi
fi

# Calculate context window usage
total_tokens=$((total_input + total_output))
remaining_tokens=$((context_size - total_tokens))

# Format context window display (with 2 decimal places)
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    total_k=$(awk "BEGIN {printf \"%.2f\", $total_tokens / 1000}")
    remaining_k=$(awk "BEGIN {printf \"%.2f\", $remaining_tokens / 1000}")
    context_display=$(printf "%sk/%sk(%.0f%%)" "$total_k" "$remaining_k" "$used_pct")
else
    context_size_k=$(awk "BEGIN {printf \"%.2f\", $context_size / 1000}")
    context_display="0.00k/${context_size_k}k(0%)"
fi

# Get transcript summary (find entry with type: summary)
transcript_summary=""
if [ -f "$transcript_path" ]; then
    transcript_summary=$(jq -r 'select(.type == "summary") | .text // .content // empty' "$transcript_path" 2>/dev/null | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

# Nerd Font icons (using printf for all icons for consistency)
ICON_FOLDER=$(printf '\xef\x81\xbb')
ICON_GIT=$(printf '\xef\x84\xa6')
ICON_ROBOT=$(printf '\xee\xb8\x8d')
ICON_MEMORY=$(printf '\xf3\xb0\x8d\x9b')
ICON_DOC=$(printf '\xef\x85\x9c')

# Line 1: directory | git branch | model | context
# Using starship.toml style colors and Nerd Font icons
line1=""

# Directory (bold green with folder icon)
line1+=$(printf "\033[1;32m%s %s\033[0m" "$ICON_FOLDER" "$abbrev_path")

# Git branch (with branch symbol in purple/magenta)
if [ -n "$git_branch" ]; then
    line1+=$(printf "  \033[35m%s %s%s\033[0m" "$ICON_GIT" "$git_branch" "$git_status_indicators")
fi

# Model display name (blue with robot icon)
line1+=$(printf "  \033[34m%s  %s\033[0m" "$ICON_ROBOT" "$model_display")

# Context window (color based on usage percentage)
# Green (<50%), Yellow (50-80%), Red (>80%)
context_color="\033[32m"  # default green
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    used_pct_int=$(printf "%.0f" "$used_pct")
    if [ "$used_pct_int" -ge 80 ]; then
        context_color="\033[31m"  # red
    elif [ "$used_pct_int" -ge 50 ]; then
        context_color="\033[33m"  # yellow
    fi
fi
line1+=$(printf "  ${context_color}%s %s\033[0m" "$ICON_MEMORY" "$context_display")

# Line 2: transcript summary (dimmed with document icon)
line2=""
if [ -n "$transcript_summary" ]; then
    line2=$(printf "\033[2m%s %s\033[0m" "$ICON_DOC" "$transcript_summary")
fi

# Output both lines
echo "$line1"
if [ -n "$line2" ]; then
    echo "$line2"
fi
