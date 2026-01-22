# Ralph Script

Based on: https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum

Automated Claude Code loop for iterative task completion.

## Usage

```bash
./ralph.sh <iterations> <prompt-file>
```

## Arguments

| Argument      | Description                                            |
|---------------|--------------------------------------------------------|
| `iterations`  | Maximum number of Claude Code invocations              |
| `prompt-file` | Path to a file containing the prompt to send to Claude |

## Example Prompt File

Create a prompt file (e.g., `my-prompt.txt`) with the following format:

```
@plan.md @progress.txt
1. Decide which task to work on next.
   This should be the one YOU decide has the highest priority,
   - not necessarily the first in the list.
2. Check any feedback loops, such as types and tests.
3. Append your progress to the progress.txt file.
4. Make a git commit of that feature.
ONLY WORK ON A SINGLE FEATURE.
If, while implementing the feature, you notice that all work
is complete, output <promise>COMPLETE</promise>.
```

The `@file` references will be expanded by Claude to include file contents.

## Example work item

```json5
{
  "category": "functional",
  "description": "New chat button creates a fresh conversation",
  "steps": [
    "Click the 'New Chat' button",
    "Verify a new conversation is created",
    "Check that chat area shows welcome state"
  ],
  "passes": false
}
```

## Exit Behavior

The script exits early when Claude's output contains `<promise>COMPLETE</promise>`. This allows Claude to signal that all tasks are finished before reaching the maximum iteration count.

## Permission Mode

The script runs Claude with `--permission-mode acceptEdits`, which automatically accepts file edits without prompting. This enables unattended operation for automated workflows.
