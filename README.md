# cc-setup

Strict setup for Claude Code and Codex.

## Usage

```bash
./install.sh
./install.sh --dry-run
./install.sh --pull
```

`./install.sh` is the only supported entrypoint. Old sub-installers under `claude/skills/` and `superpowers/` delegate back to it.

## Layout

- `agents/` shared assets for Claude Code and Codex
- `claude/` Claude-only config
- `codex/` Codex-only config
- `.agent/install/manifest.json` installer source of truth
- `.agent/superpowers/` Superpowers specs/plans

## Managed targets

Config files are symlinked from repo:

- `claude/settings.json` -> `~/.claude/settings.json`
- `claude/status-line.sh` -> `~/.claude/status-line.sh`
- `codex/config.toml` -> `~/.codex/config.toml`

Skills are copied, never symlinked:

- local skills from `agents/skills/`
- external skills from `npx skills`
- Claude Code target: `~/.claude/skills`
- Codex target: `~/.agents/skills`

Codex config is repo-managed and enables:

```toml
[features]
multi_agent = true
```

## External skills

Managed external skills:

- `vercel-labs/skills --skill find-skills`
- `vercel-labs/agent-browser --skill agent-browser`
- `anthropics/skills --skill frontend-design`
- `vercel-labs/ai --skill ai-sdk`

Each fetch runs with timeout. Logs go to:

```text
~/.config/cc-setup/logs/
```

## Superpowers

Superpowers is cloned or updated in cache, then copied into Codex's primary target:

```text
~/.cache/cc-setup/superpowers
~/.agents/skills/superpowers
```

Codex does not depend on marketplace/plugin flow.

## Drift

Managed target drift is fatal before mutation.

Examples:

- config target exists but is not the expected symlink
- copied skill hash differs from installer state
- copied skill target is replaced by a symlink
- managed skill target has no recorded state

State file:

```text
~/.config/cc-setup/state.json
```

Fix drift manually, then rerun `./install.sh`.

## Adding local skills

Add a directory under `agents/skills/` with `SKILL.md`.
