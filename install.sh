#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
STATE_FILE="$CLAUDE_DIR/.cc-setup-state"

# Parse arguments
FORCE=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force) FORCE=true; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        *) shift ;;
    esac
done

# Skill commands to run (paste any command format directly)
SKILL_COMMANDS=(
    "npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser"
    "npx skills add https://github.com/anthropics/skills --skill frontend-design"
)

mkdir -p "$CLAUDE_DIR"

# Copy settings
if [ "$DRY_RUN" = true ]; then
    echo "Would copy settings.json to $CLAUDE_DIR/settings.json"
else
    cp "$SCRIPT_DIR/setup/settings.json" "$CLAUDE_DIR/settings.json"
    echo "Copied settings.json"
fi

# Load previous state (or empty if force)
INSTALLED=()
if [ "$FORCE" = false ] && [ -f "$STATE_FILE" ]; then
    mapfile -t INSTALLED < "$STATE_FILE"
fi

# Install skills
for cmd in "${SKILL_COMMANDS[@]}"; do
    if [[ ! " ${INSTALLED[*]} " =~ " ${cmd} " ]]; then
        if [ "$DRY_RUN" = true ]; then
            echo "Would run: $cmd"
        else
            echo "Running: $cmd"
            eval "$cmd"
        fi
    fi
done

# Save new state
if [ "$DRY_RUN" = true ]; then
    echo "Would save state to $STATE_FILE"
else
    printf '%s\n' "${SKILL_COMMANDS[@]}" > "$STATE_FILE"
fi

echo "Done!"
