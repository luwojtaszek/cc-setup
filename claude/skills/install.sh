#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"

echo "Installing skills..."

# --- 1. Local skills (symlinks) ---
mkdir -p "$TARGET_DIR"

installed=0
existing_local=()

for skill_dir in "$SCRIPT_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"

  target="$TARGET_DIR/$skill_name"

  if [ -L "$target" ]; then
    existing_local+=("$skill_name")
    continue
  fi

  if [ -e "$target" ]; then
    echo "WARN: $skill_name — non-symlink file exists at $target, skipping"
    continue
  fi

  ln -s "$skill_dir" "$target"
  installed=$((installed + 1))
  echo "link: $skill_name"
done

if [ ${#existing_local[@]} -gt 0 ]; then
  local_list=$(printf '%s, ' "${existing_local[@]}")
  echo "local: ${local_list%, }"
fi

# --- 2. External skills (npx skills add) ---
externals=(
  "vercel-labs/skills --skill find-skills"
  "vercel-labs/agent-browser --skill agent-browser"
  "anthropics/claude-plugins-official --skill frontend-design"
  "vercel-labs/ai --skill ai-sdk"
)

ext_ok=0
ext_fail=0

_skill_log=$(mktemp)
trap 'rm -f "$_skill_log"' EXIT

for entry in "${externals[@]}"; do
  skill_name="${entry##*--skill }"

  if npx skills add $entry -a claude-code -g -y >"$_skill_log" 2>&1; then
    ext_ok=$((ext_ok + 1))
    echo "synced: $skill_name"
  else
    ext_fail=$((ext_fail + 1))
    echo "FAIL: $skill_name"
    cat "$_skill_log"
  fi
done

# --- 3. Summary ---
if [ "$installed" -gt 0 ] || [ "$ext_ok" -gt 0 ] || [ "$ext_fail" -gt 0 ]; then
  echo "=============================="
  echo "Local:    $installed linked"
  echo "External: $ext_ok installed, $ext_fail failed"
  echo "=============================="
fi
