---
name: pr-summary
description: Summarize current branch changes for a PR description. Use when the user wants a concise, copy-pasteable GitHub PR summary that covers commits tied to the current JIRA key plus local staged, unstaged, or untracked work.
disable-model-invocation: true
allowed-tools: Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git branch:*) Bash(git status:*) Bash(git ls-files:*) Bash(cat:*) Bash(sed:*)
context: fork
---

# PR Summary

Generate a concise markdown summary of the current branch state, ready to copy-paste into a GitHub PR description.

## Step 1: Resolve the JIRA Key

Read the current branch name:

```bash
git branch --show-current
```

Extract the first token matching a standard uppercase JIRA key pattern such as `ABC-123`.

If the branch name does not contain a JIRA key, inspect the latest commit message:

```bash
git log -1 --pretty=%B
```

Extract the first token matching the same JIRA key pattern from that commit message.

If a JIRA key is still not available, stop and ask the user which base branch to compare against. After the user answers, summarize all committed changes relative to that base branch plus local changes. Do not infer `main`, `master`, `develop`, or `release/*` automatically in this fallback path.

## Step 2: Gather Context

If a JIRA key was resolved, collect only commits whose message contains that key:

```bash
git log --oneline --grep='<JIRA_KEY>' --regexp-ignore-case=never
```

```bash
git log --format=%H --grep='<JIRA_KEY>' --regexp-ignore-case=never
```

Inspect the diffs for those matching commits only. Use `git show <sha> --stat` or `git show <sha>` as needed to understand the relevant committed changes. Exclude commits that do not mention the resolved JIRA key.

If the skill is operating in fallback mode after the user provided a base branch, gather committed changes with:

```bash
git log <base>..HEAD --oneline
```

```bash
git diff <base>...HEAD
```

Collect local working tree changes in all cases:

```bash
git diff --cached
```

```bash
git diff
```

```bash
git status --short
```

List untracked files explicitly:

```bash
git ls-files --others --exclude-standard
```

For any untracked text file that appears relevant to the summary, inspect its contents with `sed -n` or `cat`. Do not inspect binary files. Skip generated or irrelevant files unless they materially affect the summary.

## Step 3: Generate Summary

Analyze the selected committed changes and any local changes together. Produce a concise PR-ready summary using this exact markdown structure:

```md
## Summary
<1-3 sentence high-level description of what this branch does right now>

## Changes
- <grouped bullet by feature or area>
- <grouped bullet by feature or area>
```

Requirements:

- Keep the wording concise and suitable for a GitHub PR description.
- Group related changes instead of listing files one by one.
- Include notable local staged, unstaged, or untracked work when present.
- When a JIRA key was resolved, summarize only commits whose message contains that key.
- When fallback mode is used, summarize all committed changes relative to the user-provided base branch.
- Do not include a file stats section.
- Do not add extra headings such as Testing, Risks, or Files Changed unless the user explicitly asks for them.

## Step 4: Output

Output exactly one markdown code block using triple backticks. Inside that code block, return plain markdown text only. Do not output any explanation or rendered markdown before or after the code block.

Example output shape:

````markdown
```md
## Summary
Updated the PR summary skill to select committed work by JIRA key and include local in-progress changes.

## Changes
- Resolved the JIRA key from the branch name or latest commit before gathering history.
- Limited committed-change analysis to matching JIRA-tagged commits while still including staged, unstaged, and relevant untracked files.
```
````
