#!/usr/bin/env bash
set -euo pipefail

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
      echo "WARN: superpowers installer ignoring unknown arg: $1" >&2
      ;;
  esac
  shift
done

REPO_URL="https://github.com/obra/superpowers.git"
CLAUDE_PLUGIN_REF="superpowers@claude-plugins-official"
CLAUDE_FALLBACK_MARKETPLACE="obra/superpowers-marketplace"
CLAUDE_FALLBACK_PLUGIN_REF="superpowers@superpowers-marketplace"
CODEX_REPO_DIR="$HOME/.codex/superpowers"
CODEX_CONFIG="$HOME/.codex/config.toml"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
AGENTS_SUPERPOWERS_LINK="$AGENTS_SKILLS_DIR/superpowers"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
OPENCODE_PLUGIN_REF="superpowers@git+https://github.com/obra/superpowers.git"

say() {
  echo "$*"
}

warn() {
  echo "WARN: $*" >&2
}

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    say "Would run: $*"
  else
    "$@"
  fi
}

ensure_parent_dir() {
  local path="$1"
  local parent
  parent="$(dirname "$path")"
  if [ "$DRY_RUN" = true ]; then
    say "Would ensure directory exists: $parent"
  else
    mkdir -p "$parent"
  fi
}

has_claude_code() {
  command -v claude >/dev/null 2>&1 || return 1
  claude plugin --help >/dev/null 2>&1
}

has_codex_cli() {
  command -v codex >/dev/null 2>&1
}

has_opencode() {
  command -v opencode >/dev/null 2>&1
}

claude_has_superpowers_plugin() {
  claude plugin list 2>/dev/null | grep -Eq 'superpowers@'
}

print_claude_fallback() {
  say "Claude Code fallback commands:"
  say "  claude plugin marketplace add $CLAUDE_FALLBACK_MARKETPLACE"
  say "  claude plugin install -s user $CLAUDE_FALLBACK_PLUGIN_REF"
}

install_claude_superpowers() {
  say "superpowers: configuring Claude Code"

  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not found, skipping Claude plugin install"
    return
  fi

  if claude_has_superpowers_plugin; then
    if [ "$PULL" = true ]; then
      run_cmd claude plugin update superpowers
    else
      say "claude: plugin already installed"
    fi
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    say "Would run: claude plugin install -s user $CLAUDE_PLUGIN_REF"
    return
  fi

  if claude plugin install -s user "$CLAUDE_PLUGIN_REF"; then
    say "claude: installed $CLAUDE_PLUGIN_REF"
  else
    warn "official Claude marketplace install failed"
    print_claude_fallback
  fi
}

ensure_codex_repo() {
  say "superpowers: configuring Codex"

  if [ -d "$CODEX_REPO_DIR/.git" ]; then
    if [ "$PULL" = true ]; then
      run_cmd git -C "$CODEX_REPO_DIR" pull --ff-only
    else
      say "codex: repo already present at $CODEX_REPO_DIR"
    fi
    return
  fi

  if [ -e "$CODEX_REPO_DIR" ]; then
    warn "path exists and is not a git repo, skipping clone: $CODEX_REPO_DIR"
    return
  fi

  ensure_parent_dir "$CODEX_REPO_DIR"
  run_cmd git clone "$REPO_URL" "$CODEX_REPO_DIR"
}

ensure_codex_symlink() {
  local expected_target actual_target
  expected_target="$CODEX_REPO_DIR/skills"

  if [ "$DRY_RUN" = true ]; then
    say "Would ensure directory exists: $AGENTS_SKILLS_DIR"
  else
    mkdir -p "$AGENTS_SKILLS_DIR"
  fi

  if [ -L "$AGENTS_SUPERPOWERS_LINK" ]; then
    actual_target="$(readlink "$AGENTS_SUPERPOWERS_LINK" || true)"
    actual_target="${actual_target%/}"
    if [ "$actual_target" = "$expected_target" ]; then
      say "codex: symlink already points to $expected_target"
      return
    fi

    if [ "$DRY_RUN" = true ]; then
      say "Would replace symlink: $AGENTS_SUPERPOWERS_LINK -> $actual_target"
      say "Would create symlink: $AGENTS_SUPERPOWERS_LINK -> $expected_target"
    else
      rm "$AGENTS_SUPERPOWERS_LINK"
      ln -s "$expected_target" "$AGENTS_SUPERPOWERS_LINK"
      say "codex: replaced symlink $AGENTS_SUPERPOWERS_LINK -> $expected_target"
    fi
    return
  fi

  if [ -e "$AGENTS_SUPERPOWERS_LINK" ]; then
    warn "non-symlink path exists, leaving it untouched: $AGENTS_SUPERPOWERS_LINK"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    say "Would create symlink: $AGENTS_SUPERPOWERS_LINK -> $expected_target"
  else
    ln -s "$expected_target" "$AGENTS_SUPERPOWERS_LINK"
    say "codex: created symlink $AGENTS_SUPERPOWERS_LINK -> $expected_target"
  fi
}

ensure_codex_multi_agent() {
  python3 - "$CODEX_CONFIG" "$DRY_RUN" <<'PY'
from pathlib import Path
import re
import sys

config_path = Path(sys.argv[1]).expanduser()
dry_run = sys.argv[2].lower() == "true"

original = config_path.read_text() if config_path.exists() else ""
text = original

section_re = re.compile(r'(?ms)^\[features\]\s*\n(?P<body>.*?)(?=^\[|\Z)')
match = section_re.search(text)

action = None
updated = text

if match:
    body = match.group("body")
    multi_re = re.compile(r'(?m)^multi_agent\s*=\s*(true|false)\s*$')
    if multi_re.search(body):
        new_body = multi_re.sub("multi_agent = true", body, count=1)
        updated = text[:match.start("body")] + new_body + text[match.end("body"):]
        if new_body != body:
            action = "update"
    else:
        insertion = "multi_agent = true\n"
        updated = text[:match.end("body")] + insertion + text[match.end("body"):]
        action = "insert"
else:
    updated = text
    if updated and not updated.endswith("\n"):
        updated += "\n"
    if updated and not updated.endswith("\n\n"):
        updated += "\n"
    updated += "[features]\nmulti_agent = true\n"
    action = "append"

if action is None:
    print("codex: multi_agent already enabled")
    raise SystemExit(0)

if dry_run:
    print(f"Would enable Codex multi_agent in {config_path}")
    raise SystemExit(0)

config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(updated)
print(f"codex: enabled multi_agent in {config_path}")
PY
}

configure_opencode() {
  python3 - "$OPENCODE_CONFIG" "$OPENCODE_PLUGIN_REF" "$DRY_RUN" <<'PY'
from pathlib import Path
import json
import sys

config_path = Path(sys.argv[1]).expanduser()
plugin_ref = sys.argv[2]
dry_run = sys.argv[3].lower() == "true"

if config_path.exists():
    data = json.loads(config_path.read_text())
else:
    data = {"$schema": "https://opencode.ai/config.json"}

plugins = data.get("plugin")
if plugins is None:
    plugins = []
    data["plugin"] = plugins
elif not isinstance(plugins, list):
    raise SystemExit(f"ERROR: {config_path} has a non-array 'plugin' value")

if plugin_ref in plugins:
    print("opencode: config already contains the Superpowers plugin")
    raise SystemExit(0)

plugins.append(plugin_ref)

if dry_run:
    print(f"Would update OpenCode config: {config_path}")
    print("  - add OpenCode plugin entry")
    raise SystemExit(0)

config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(json.dumps(data, indent=2) + "\n")
print(f"opencode: updated {config_path}")
print("  - add OpenCode plugin entry")
PY
}

main() {
  local has_claude=false
  local has_codex=false
  local has_opencode_cli=false

  say "Installing superpowers..."

  if has_claude_code; then
    has_claude=true
  fi

  if has_codex_cli; then
    has_codex=true
  fi

  if has_opencode; then
    has_opencode_cli=true
  fi

  say "superpowers: detected tools"
  say "  - Claude Code: $([ "$has_claude" = true ] && printf 'yes' || printf 'no')"
  say "  - Codex CLI: $([ "$has_codex" = true ] && printf 'yes' || printf 'no')"
  say "  - OpenCode: $([ "$has_opencode_cli" = true ] && printf 'yes' || printf 'no')"

  if [ "$has_claude" = false ] && [ "$has_codex" = false ] && [ "$has_opencode_cli" = false ]; then
    say "superpowers: no supported agent CLIs detected, skipping install"
    return
  fi

  if [ "$has_claude" = true ]; then
    install_claude_superpowers
  else
    say "superpowers: skipping Claude Code (not detected)"
  fi

  if [ "$has_codex" = true ]; then
    ensure_codex_repo
    ensure_codex_symlink
    ensure_codex_multi_agent
  else
    say "superpowers: skipping Codex (not detected)"
  fi

  if [ "$has_opencode_cli" = true ]; then
    say "superpowers: configuring OpenCode"
    configure_opencode
  else
    say "superpowers: skipping OpenCode (not detected)"
  fi
}

main
