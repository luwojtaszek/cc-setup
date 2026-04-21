---
name: git-commit-push-pr
description: Commit changes, push to remote, and create a pull request in one step. Use when the user wants to ship changes end-to-end.
license: Apache-2.0
compatibility: Requires git and GitHub CLI (gh) authenticated. Designed for coding agents with shell access.
allowed-tools: Bash(git checkout --branch:*) Bash(git add:*) Bash(git status:*) Bash(git push:*) Bash(git commit:*) Bash(gh pr create:*) Bash(git diff:*) Bash(git branch:*)
metadata:
  author: Anthropic
  version: "1.0"
---

# Git Commit, Push, and PR

Commit changes, push to remote, and create a pull request in one step.

## Step 1: Gather Context

Run these commands to understand the current state:

```bash
git status
```

```bash
git diff HEAD
```

```bash
git branch --show-current
```

## Step 2: Commit, Push, and Create PR

Based on the gathered context:

1. Create a new branch if on main
2. Create a single commit with an appropriate message
3. Push the branch to origin
4. Create a pull request using `gh pr create`

You have the capability to call multiple tools in a single response. You MUST do all of the above in a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
