#!/bin/bash
# install.sh - Add cc-setup scripts to PATH

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
EXPORT_LINE="export PATH=\"$SCRIPT_DIR:\$PATH\""
MARKER="# cc-setup scripts"

add_to_rc() {
  local rc_file="$1"
  if [ -f "$rc_file" ]; then
    if grep -q "$MARKER" "$rc_file"; then
      echo "Already installed in $rc_file"
    else
      echo "" >> "$rc_file"
      echo "$MARKER" >> "$rc_file"
      echo "$EXPORT_LINE" >> "$rc_file"
      echo "Added to $rc_file"
    fi
  fi
}

add_to_rc "$HOME/.bashrc"
add_to_rc "$HOME/.zshrc"

echo ""
echo "Done! Restart your shell or run:"
echo "  source ~/.bashrc  # or source ~/.zshrc"
