# cc-setup

Setup tool for Claude Code, Codex CLI, and OpenCode.

## What it does

- Symlinks `settings.json` and `status-line.sh` to `~/.claude/`
- Installs standalone skills: symlinks local skills + installs external skills via `npx`
- Installs Superpowers using the upstream-recommended method for each agent:
  - Claude Code: plugin install via `claude plugin install`
  - Codex CLI: clone to `~/.codex/superpowers` + symlink `~/.agents/skills/superpowers`
  - OpenCode: global `plugin` entry in `~/.config/opencode/opencode.json`
- Installs Superpowers only for agent CLIs detected on `PATH`

## Usage

```bash
./install.sh          # install everything
./install.sh --dry-run  # preview what would happen
./install.sh -n         # same as --dry-run
./install.sh --pull     # update this repo and Superpowers
```

Tip: add a shell alias for quick access:

```bash
alias cc-setup='bash ~/path/to/cc-setup/install.sh'
```

## Superpowers

This repo does not use `skills.sh/obra/superpowers/using-superpowers`. It installs Superpowers using the upstream-recommended setup for each supported tool:

- Claude Code: installs `superpowers@claude-plugins-official`
- Codex CLI: clones `https://github.com/obra/superpowers.git` to `~/.codex/superpowers` and links `~/.agents/skills/superpowers`
- OpenCode: adds `superpowers@git+https://github.com/obra/superpowers.git` to `~/.config/opencode/opencode.json`

Superpowers is installed only for detected agent CLIs on `PATH`:

- Claude Code is detected from the `claude` CLI with plugin support
- Codex is detected from the `codex` CLI
- OpenCode is detected from the `opencode` CLI

Existing config directories alone do not trigger installation.

For Codex, the installer also enables:

```toml
[features]
multi_agent = true
```

## Adding skills

### Local skills

Add a directory under `claude/skills/` with a `SKILL.md` file. The installer symlinks each skill dir into `~/.claude/skills/`.

### External skills

Edit the `externals` array in `claude/skills/install.sh`:

```bash
externals=(
  "vercel-labs/skills --skill find-skills"
  "anthropics/claude-plugins-official --skill frontend-design"
)
```
