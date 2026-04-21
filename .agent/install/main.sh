#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/configs.sh"
source "$SCRIPT_DIR/lib/hash.sh"
source "$SCRIPT_DIR/lib/state.sh"
source "$SCRIPT_DIR/lib/materialize.sh"
source "$SCRIPT_DIR/lib/skills.sh"
source "$SCRIPT_DIR/lib/superpowers.sh"

main() {
  parse_args "$@"
  preflight_tools git npx python3
  preflight_managed_targets
  pull_repo
  reconcile_configs
  reconcile_local_skills
  reconcile_external_skills
  reconcile_superpowers
}

main "$@"
