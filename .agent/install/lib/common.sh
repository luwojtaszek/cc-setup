#!/usr/bin/env bash

DRY_RUN=false
PULL=false

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd
}

parse_args() {
  DRY_RUN=false
  PULL=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        DRY_RUN=true
        ;;
      -p|--pull)
        PULL=true
        ;;
      *)
        fail "unknown arg: $1"
        ;;
    esac
    shift
  done
}

preflight_tools() {
  local tool
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 || fail "missing tool: $tool"
  done
}

pull_repo() {
  local root
  root="$(repo_root)"

  if [ "$PULL" != true ]; then
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "Would pull latest changes in $root"
    return
  fi

  git -C "$root" pull --ff-only
}

preflight_managed_targets() {
  preflight_configs
  verify_local_skill_drift
  verify_external_skill_drift
  verify_superpowers_target_drift
}

log_dir() {
  printf '%s\n' "$HOME/.config/cc-setup/logs"
}

run_with_timeout() {
  local seconds="$1"
  shift

  python3 - "$seconds" "$@" <<'PY'
import subprocess
import sys

timeout = int(sys.argv[1])
cmd = sys.argv[2:]

try:
    completed = subprocess.run(cmd, timeout=timeout)
except subprocess.TimeoutExpired:
    print(f'timeout after {timeout}s: {" ".join(cmd)}', file=sys.stderr)
    raise SystemExit(124)

raise SystemExit(completed.returncode)
PY
}
