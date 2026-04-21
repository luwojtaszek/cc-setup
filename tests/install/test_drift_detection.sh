#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../support/test_env.sh"
setup_test_env
run_install
echo "local edit" >> "$HOME/.agents/skills/code-review/SKILL.md"

if run_install; then
  echo "expected drift failure" >&2
  exit 1
fi
