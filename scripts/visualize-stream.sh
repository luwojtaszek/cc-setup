#!/bin/bash
# Visualize Claude Code stream-json output
# Parses JSON lines and formats output with colors and structure

# Colors
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

while IFS= read -r line; do
  type=$(echo "$line" | jq -r '.type // empty')

  case "$type" in
    stream_event)
      event_type=$(echo "$line" | jq -r '.event.type // empty')
      case "$event_type" in
        content_block_delta)
          delta_type=$(echo "$line" | jq -r '.event.delta.type // empty')
          if [ "$delta_type" = "text_delta" ]; then
            # Print streaming text without newline
            text=$(echo "$line" | jq -r '.event.delta.text // empty')
            printf '%s' "$text"
          fi
          ;;
      esac
      ;;
    assistant)
      # Check for tool_use in assistant message content
      content_type=$(echo "$line" | jq -r '.message.content[0].type // empty')
      if [ "$content_type" = "tool_use" ]; then
        tool_name=$(echo "$line" | jq -r '.message.content[0].name // empty')
        tool_input=$(echo "$line" | jq -r '.message.content[0].input // empty')

        printf '\n%b▶ Tool: %s%b\n' "$BLUE" "$tool_name" "$RESET"

        # Display tool-specific details
        case "$tool_name" in
          Bash)
            cmd=$(echo "$line" | jq -r '.message.content[0].input.command // empty')
            desc=$(echo "$line" | jq -r '.message.content[0].input.description // empty')
            if [ -n "$desc" ]; then
              printf '%b  Description: %s%b\n' "$DIM" "$desc" "$RESET"
            fi
            if [ -n "$cmd" ]; then
              printf '%b  Command: %s%b\n' "$CYAN" "$cmd" "$RESET"
            fi
            ;;
          Read|Write|Edit)
            file_path=$(echo "$line" | jq -r '.message.content[0].input.file_path // empty')
            if [ -n "$file_path" ]; then
              printf '%b  File: %s%b\n' "$CYAN" "$file_path" "$RESET"
            fi
            # For Edit, show old_string preview
            if [ "$tool_name" = "Edit" ]; then
              old_str=$(echo "$line" | jq -r '.message.content[0].input.old_string // empty' | head -c 100)
              if [ -n "$old_str" ]; then
                printf '%b  Replacing: %s...%b\n' "$DIM" "$old_str" "$RESET"
              fi
            fi
            ;;
          Glob)
            pattern=$(echo "$line" | jq -r '.message.content[0].input.pattern // empty')
            if [ -n "$pattern" ]; then
              printf '%b  Pattern: %s%b\n' "$CYAN" "$pattern" "$RESET"
            fi
            ;;
          Grep)
            pattern=$(echo "$line" | jq -r '.message.content[0].input.pattern // empty')
            path=$(echo "$line" | jq -r '.message.content[0].input.path // empty')
            if [ -n "$pattern" ]; then
              printf '%b  Pattern: %s%b\n' "$CYAN" "$pattern" "$RESET"
            fi
            if [ -n "$path" ]; then
              printf '%b  Path: %s%b\n' "$DIM" "$path" "$RESET"
            fi
            ;;
          Task)
            desc=$(echo "$line" | jq -r '.message.content[0].input.description // empty')
            agent=$(echo "$line" | jq -r '.message.content[0].input.subagent_type // empty')
            if [ -n "$agent" ]; then
              printf '%b  Agent: %s%b\n' "$CYAN" "$agent" "$RESET"
            fi
            if [ -n "$desc" ]; then
              printf '%b  Task: %s%b\n' "$DIM" "$desc" "$RESET"
            fi
            ;;
          *)
            # For other tools, show raw input (truncated)
            if [ -n "$tool_input" ] && [ "$tool_input" != "{}" ]; then
              input_preview=$(echo "$tool_input" | jq -c '.' | head -c 200)
              printf '%b  Input: %s%b\n' "$DIM" "$input_preview" "$RESET"
            fi
            ;;
        esac
      fi
      ;;
    user)
      # Check for tool results
      tool_result=$(echo "$line" | jq -r '.message.content[0].type // empty')
      if [ "$tool_result" = "tool_result" ]; then
        is_error=$(echo "$line" | jq -r '.message.content[0].is_error // false')
        content=$(echo "$line" | jq -r '.message.content[0].content // empty')
        if [ "$is_error" = "true" ]; then
          printf '%b✗ Error: %s%b\n' "$RED" "$content" "$RESET"
        else
          # Truncate long results
          truncated="${content:0:300}"
          if [ ${#content} -gt 300 ]; then
            truncated="${truncated}..."
          fi
          printf '%b✓ Result: %s%b\n' "$GREEN" "$truncated" "$RESET"
        fi
      fi
      ;;
  esac
done
