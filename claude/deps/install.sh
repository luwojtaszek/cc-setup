#!/usr/bin/env bash
set -euo pipefail

echo "Installing dependencies..."

# agent-browser (browser automation CLI + Chromium)
install_agent_browser() {
  echo "agent-browser: installing CLI..."
  npm install -g agent-browser 2>&1 | tail -1

  if [ "$(id -u)" -eq 0 ]; then
    # Root: install browsers + system apt deps (fonts, libs for Chromium)
    echo "agent-browser: installing browsers + system deps (root)..."
    agent-browser install --with-deps 2>&1 | tail -3
  else
    # Non-root: install browser binaries only
    echo "agent-browser: installing browsers for $(whoami)..."
    agent-browser install 2>&1 | tail -3
  fi
}

# --- Run all installers ---
# Add future install_<name> functions above and call them here
install_agent_browser

echo "Dependencies done."
