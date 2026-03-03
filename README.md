# cc-setup

Setup tool for Claude Code — symlinks config files and installs skills.

## What it does

- Symlinks `settings.json` and `status-line.sh` to `~/.claude/`
- Runs skill installer: symlinks local skills + installs external skills via `npx`

## Usage

```bash
./install.sh          # install everything
./install.sh --dry-run  # preview what would happen
./install.sh -n         # same as --dry-run
```

Tip: add a shell alias for quick access:

```bash
alias cc-setup='bash ~/path/to/cc-setup/install.sh'
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
