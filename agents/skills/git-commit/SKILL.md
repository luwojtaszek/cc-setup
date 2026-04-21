---
name: git-commit
description: Create a git commit by analyzing current changes. Use when the user wants to commit staged or unstaged changes with an auto-generated commit message.
license: Apache-2.0
compatibility: Requires git. Designed for coding agents with shell access.
allowed-tools: Bash(git add:*) Bash(git status:*) Bash(git commit:*) Bash(git diff:*) Bash(git log:*) Bash(git branch:*)
metadata:
  author: Anthropic
  version: "1.0"
---

# Git Commit

Create a single git commit from current changes.

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

```bash
git log --oneline -10
```

## Step 2: Stage and Commit

Based on the gathered context, stage and create the commit.

You have the capability to call multiple tools in a single response. Stage and create the commit using a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
