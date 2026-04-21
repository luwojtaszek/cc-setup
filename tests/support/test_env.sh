#!/usr/bin/env bash
set -euo pipefail

TEST_SUPPORT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_SUPPORT_DIR/assert.sh"

REPO_ROOT="$(cd "$TEST_SUPPORT_DIR/../.." && pwd)"
TEST_HOME=""

setup_test_env() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export PATH="$REPO_ROOT/tests/fixtures/bin:$PATH"
  export CC_SETUP_TEST_MODE=1
  export CC_SETUP_TIMEOUT_SECONDS=1
}

run_install() {
  bash "$REPO_ROOT/install.sh"
}
