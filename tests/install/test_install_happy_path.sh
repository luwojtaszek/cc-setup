#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../support/test_env.sh"
setup_test_env

run_install

assert_symlink "$TEST_HOME/.claude/settings.json"
assert_symlink "$TEST_HOME/.codex/config.toml"
assert_contains "$TEST_HOME/.codex/config.toml" "multi_agent = true"
assert_file "$TEST_HOME/.config/cc-setup/state.json"
assert_file "$TEST_HOME/.claude/skills/code-review/SKILL.md"
assert_file "$TEST_HOME/.agents/skills/code-review/SKILL.md"
assert_file "$TEST_HOME/.claude/skills/frontend-design/SKILL.md"
assert_file "$TEST_HOME/.agents/skills/frontend-design/SKILL.md"
assert_file "$TEST_HOME/.config/cc-setup/logs/npx-frontend-design.log"
assert_file "$TEST_HOME/.agents/skills/superpowers/using-superpowers/SKILL.md"
