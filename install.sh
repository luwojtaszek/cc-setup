#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=true; shift ;;
        *) shift ;;
    esac
done

mkdir -p "$CLAUDE_DIR"

# Items to symlink (source in repo -> target in ~/.claude)
SYMLINKS=(
    "claude/settings.json:settings.json"
    "claude/status-line.sh:status-line.sh"
    "claude/skills:skills"
)

for item in "${SYMLINKS[@]}"; do
    src="${item%%:*}"
    dst="${item##*:}"
    src_path="$SCRIPT_DIR/$src"
    dst_path="$CLAUDE_DIR/$dst"

    if [ "$DRY_RUN" = true ]; then
        echo "Would symlink $dst_path -> $src_path"
    else
        # Remove existing file/symlink/directory
        rm -rf "$dst_path"
        ln -s "$src_path" "$dst_path"
        echo "Linked $dst -> $src_path"
    fi
done

echo "Done!"
