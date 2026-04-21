#!/usr/bin/env bash

reconcile_configs() {
  local root
  local manifest
  root="$(repo_root)"
  manifest="$root/.agent/install/manifest.json"

  while IFS=$'\t' read -r source target; do
    reconcile_config "$root/$source" "$target"
  done < <(
    python3 - "$manifest" <<'PY'
from pathlib import Path
import json
import sys

manifest = Path(sys.argv[1])
data = json.loads(manifest.read_text())
for config in data["configs"]:
    print(f'{config["source"]}\t{Path(config["target"]).expanduser()}')
PY
  )
}

preflight_configs() {
  local root
  local manifest
  root="$(repo_root)"
  manifest="$root/.agent/install/manifest.json"

  while IFS=$'\t' read -r source target; do
    verify_config_target "$root/$source" "$target"
  done < <(
    python3 - "$manifest" <<'PY'
from pathlib import Path
import json
import sys

manifest = Path(sys.argv[1])
data = json.loads(manifest.read_text())
for config in data["configs"]:
    print(f'{config["source"]}\t{Path(config["target"]).expanduser()}')
PY
  )
}

verify_config_target() {
  local source="$1"
  local target="$2"
  local actual

  [ -e "$source" ] || fail "missing config source: $source"

  if [ -L "$target" ]; then
    actual="$(readlink "$target")"
    [ "$actual" = "$source" ] || fail "drift: $target expected symlink to $source, got $actual"
    return
  fi

  if [ -e "$target" ]; then
    fail "drift: $target expected symlink to $source"
  fi
}

reconcile_config() {
  local source="$1"
  local target="$2"
  local target_dir
  local actual

  verify_config_target "$source" "$target"
  target_dir="$(dirname "$target")"

  if [ -L "$target" ]; then
    echo "config ok: $target"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "Would symlink $target -> $source"
    return
  fi

  mkdir -p "$target_dir"
  ln -s "$source" "$target"
  echo "linked config: $target -> $source"
}
