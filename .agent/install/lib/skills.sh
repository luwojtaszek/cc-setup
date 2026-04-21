#!/usr/bin/env bash

manifest_local_skills_dir() {
  python3 - "$(repo_root)/.agent/install/manifest.json" <<'PY'
from pathlib import Path
import json
import sys

data = json.loads(Path(sys.argv[1]).read_text())
print(data["localSkillsDir"])
PY
}

verify_skill_dir() {
  local skill_dir="$1"
  [ -d "$skill_dir" ] || fail "missing skill dir: $skill_dir"
  [ -f "$skill_dir/SKILL.md" ] || fail "missing SKILL.md: $skill_dir"
}

verify_no_drift() {
  local target="$1"
  local source="$2"
  local expected_hash
  local actual_hash

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  if [ -L "$target" ]; then
    fail "drift: $target expected copied dir from $source, got symlink"
  fi

  if [ ! -d "$target" ]; then
    fail "drift: $target expected copied dir from $source"
  fi

  [ -f "$target/SKILL.md" ] || fail "drift: $target missing SKILL.md"

  expected_hash="$(read_state_hash "$target")"
  [ -n "$expected_hash" ] || fail "drift: $target has no managed state"

  actual_hash="$(hash_path "$target")"
  [ "$actual_hash" = "$expected_hash" ] || fail "drift: $target hash changed"
}

local_skill_targets() {
  local skill="$1"
  printf '%s\n' "$HOME/.claude/skills/$skill"
  printf '%s\n' "$HOME/.agents/skills/$skill"
}

materialize_skill_dir() {
  local source="$1"
  local target="$2"
  local source_id="$3"
  local method="$4"
  local label="$5"
  local source_hash

  source_hash="$(hash_path "$source")"
  copy_dir_atomic "$source" "$target"
  if [ "$DRY_RUN" = true ]; then
    return
  fi
  if [ "$DRY_RUN" != true ]; then
    record_state "$target" "$source_id" "$method" "$source_hash"
  fi
  echo "synced $label -> $target"
}

verify_local_skill_drift() {
  local root
  local skills_dir
  local source
  local skill
  local target

  root="$(repo_root)"
  skills_dir="$root/$(manifest_local_skills_dir)"
  [ -d "$skills_dir" ] || fail "missing local skills dir: $skills_dir"

  while IFS= read -r source; do
    verify_skill_dir "$source"
    skill="$(basename "$source")"
    while IFS= read -r target; do
      verify_no_drift "$target" "$source"
    done < <(local_skill_targets "$skill")
  done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d | sort)
}

reconcile_local_skills() {
  local root
  local skills_dir
  local source
  local skill
  local target
  local skills=()

  root="$(repo_root)"
  skills_dir="$root/$(manifest_local_skills_dir)"
  [ -d "$skills_dir" ] || fail "missing local skills dir: $skills_dir"

  while IFS= read -r source; do
    skills+=("$source")
  done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d | sort)

  verify_local_skill_drift

  for source in "${skills[@]}"; do
    skill="$(basename "$source")"
    while IFS= read -r target; do
      materialize_skill_dir "$source" "$target" "$source" "copy" "local skill: $skill"
    done < <(local_skill_targets "$skill")
  done
}

manifest_external_skills() {
  python3 - "$(repo_root)/.agent/install/manifest.json" <<'PY'
from pathlib import Path
import json
import sys

data = json.loads(Path(sys.argv[1]).read_text())
for skill in data["externalSkills"]:
    print(f'{skill["repo"]}\t{skill["skill"]}')
PY
}

verify_external_skill_drift() {
  local repo
  local skill
  local target

  while IFS=$'\t' read -r repo skill; do
    while IFS= read -r target; do
      verify_no_drift "$target" "$repo --skill $skill"
    done < <(local_skill_targets "$skill")
  done < <(manifest_external_skills)
}

fetch_external_skill() {
  local repo="$1"
  local skill="$2"
  local timeout_seconds="${CC_SETUP_TIMEOUT_SECONDS:-60}"
  local fetch_home
  local log
  local status

  fetch_home="$(mktemp -d)"
  log="$(log_dir)/npx-$skill.log"
  mkdir -p "$(log_dir)"

  set +e
  (
    export HOME="$fetch_home"
    run_with_timeout "$timeout_seconds" npx skills add "$repo" --skill "$skill" --copy -a claude-code -a codex -g -y
  ) >"$log" 2>&1
  status=$?
  set -e

  if [ "$status" -ne 0 ]; then
    if [ "$status" -eq 124 ]; then
      fail "timeout: npx skills add $repo --skill $skill (log: $log)"
    fi
    fail "external skill failed: npx skills add $repo --skill $skill (log: $log)"
  fi

  verify_skill_dir "$fetch_home/.claude/skills/$skill"
  verify_skill_dir "$fetch_home/.agents/skills/$skill"
  printf '%s\n' "$fetch_home"
}

reconcile_external_skills() {
  local repo
  local skill
  local fetch_home

  verify_external_skill_drift

  while IFS=$'\t' read -r repo skill; do
    if [ "$DRY_RUN" = true ]; then
      echo "Would fetch external skill: $repo --skill $skill"
      continue
    fi

    fetch_home="$(fetch_external_skill "$repo" "$skill")"
    materialize_skill_dir "$fetch_home/.claude/skills/$skill" "$HOME/.claude/skills/$skill" "$repo --skill $skill" "external-copy" "external skill: $skill"
    materialize_skill_dir "$fetch_home/.agents/skills/$skill" "$HOME/.agents/skills/$skill" "$repo --skill $skill" "external-copy" "external skill: $skill"
    rm -rf "$fetch_home"
  done < <(manifest_external_skills)
}
