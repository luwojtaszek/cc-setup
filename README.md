# cc-setup

Setup tool for Claude Code that installs skills and configures settings.

## What it does

- Installs Claude Code skills via customizable commands
- Copies settings.json to ~/.claude/
- Tracks executed commands for idempotent updates

## Usage

```bash
./install.sh          # Install/update skills (idempotent)
./install.sh --force  # Force reinstall all skills
./install.sh -f       # Same as --force
./install.sh --dry-run  # Show what would happen
./install.sh -n         # Same as --dry-run
```

## Configuration

### Skills

Edit the `SKILL_COMMANDS` array in `install.sh`. Paste any command format directly:

```bash
SKILL_COMMANDS=(
    "npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser"
    "npx skills add https://github.com/anthropics/skills --skill frontend-design"
)
```

### Settings

Edit `setup/settings.json` to customize Claude Code settings.

## How it works

1. Copies settings.json to ~/.claude/settings.json
2. Compares current SKILL_COMMANDS against previous state
3. Runs new commands that haven't been executed before
4. Saves state to ~/.claude/.cc-setup-state
