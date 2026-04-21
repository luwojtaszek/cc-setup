#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../support/test_env.sh"
setup_test_env
export CC_SETUP_NPX_MODE=hang

if run_install; then
  echo "expected timeout failure" >&2
  exit 1
fi

assert_file "$TEST_HOME/.config/cc-setup/logs/npx-find-skills.log"
assert_contains "$TEST_HOME/.config/cc-setup/logs/npx-find-skills.log" "timeout after 1s"
