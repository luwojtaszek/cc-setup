#!/usr/bin/env bash

manifest_superpowers() {
  python3 - "$(repo_root)/.agent/install/manifest.json" <<'PY'
from pathlib import Path
import json
import sys

data = json.loads(Path(sys.argv[1]).read_text())
superpowers = data["superpowers"]
print(f'{superpowers["repoUrl"]}\t{Path(superpowers["target"]).expanduser()}')
PY
}

superpowers_cache_dir() {
  printf '%s\n' "$HOME/.cache/cc-setup/superpowers"
}

ensure_superpowers_cache() {
  local repo_url="$1"
  local cache_dir
  cache_dir="$(superpowers_cache_dir)"

  if [ -d "$cache_dir/.git" ]; then
    if [ "$PULL" = true ]; then
      git -C "$cache_dir" pull --ff-only
    else
      echo "superpowers cache ok: $cache_dir"
    fi
    return
  fi

  if [ -e "$cache_dir" ]; then
    fail "drift: $cache_dir exists and is not a git repo"
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "Would clone $repo_url -> $cache_dir"
    return
  fi

  mkdir -p "$(dirname "$cache_dir")"
  git clone "$repo_url" "$cache_dir"
}

verify_superpowers_source() {
  local cache_dir
  cache_dir="$(superpowers_cache_dir)"
  [ -f "$cache_dir/skills/using-superpowers/SKILL.md" ] || fail "missing Superpowers skill tree: $cache_dir/skills"
}

verify_superpowers_drift() {
  local target="$1"
  local source_id="$2"
  local expected_hash
  local actual_hash

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  if [ -L "$target" ]; then
    fail "drift: $target expected copied Superpowers tree from $source_id, got symlink"
  fi

  if [ ! -d "$target" ]; then
    fail "drift: $target expected copied Superpowers tree from $source_id"
  fi

  [ -f "$target/using-superpowers/SKILL.md" ] || fail "drift: $target missing using-superpowers/SKILL.md"

  expected_hash="$(read_state_hash "$target")"
  [ -n "$expected_hash" ] || fail "drift: $target has no managed state"

  actual_hash="$(hash_path "$target")"
  [ "$actual_hash" = "$expected_hash" ] || fail "drift: $target hash changed"
}

verify_superpowers_target_drift() {
  local repo_url
  local target

  while IFS=$'\t' read -r repo_url target; do
    verify_superpowers_drift "$target" "$repo_url"
  done < <(manifest_superpowers)
}

reconcile_superpowers() {
  local repo_url
  local target
  local cache_dir
  local source_dir
  local source_hash

  while IFS=$'\t' read -r repo_url target; do
    verify_superpowers_drift "$target" "$repo_url"
    ensure_superpowers_cache "$repo_url"

    if [ "$DRY_RUN" = true ]; then
      if [ -d "$(superpowers_cache_dir)/skills" ]; then
        verify_superpowers_source
      fi
      echo "Would copy Superpowers -> $target"
      continue
    fi

    verify_superpowers_source
    cache_dir="$(superpowers_cache_dir)"
    source_dir="$cache_dir/skills"
    source_hash="$(hash_path "$source_dir")"
    copy_dir_atomic "$source_dir" "$target"
    record_state "$target" "$repo_url" "superpowers-copy" "$source_hash"
    echo "synced Superpowers -> $target"
  done < <(manifest_superpowers)
}
