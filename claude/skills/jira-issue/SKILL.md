---
name: jira-issue
description: Generate a JIRA issue description from notes or a file. Use when the user wants copy-pasteable raw markdown for Jira.
argument-hint: <notes or @file>
allowed-tools: Bash(test:*) Bash(cat:*) Bash(sed:*)
---

# JIRA Issue

Generate a JIRA issue description from either inline notes or a file reference.

## Step 1: Resolve the Input

Read the user-provided argument.

- If the argument starts with `@`, treat the remainder as a file path.
- Resolve relative paths from the current working directory.
- Verify the file is readable before reading it.
- If the file is missing or unreadable, stop and ask the user for a valid readable text file.
- If the argument does not start with `@`, treat the full argument as the notes.

Use the resolved text as the only source of truth for the JIRA issue description.

## Step 2: Extract the Content

Analyze the notes and identify:

- Background or context
- Proposed solution or intended change
- Acceptance criteria or expected outcomes
- QA details such as test notes, steps to reproduce, configurations, or edge cases
- Potential regression impact

Write concise, professional bullets. Preserve concrete details from the notes. Do not invent specifics that are not implied by the source text.

## Step 3: Fill Missing Information

If a section is missing in the notes, use these defaults:

- `## Background`: `- Background/context not explicitly provided in the notes.`
- `## Proposed solution`: `- Proposed implementation details were not explicitly provided in the notes.`
- `## Acceptance criteria`: `- Requested behavior from the notes is implemented and verified.`
- `### Testable by QA`: `- Yes` unless the notes clearly indicate an internal-only or non-observable change, then use `- No`
- `### Extra info? (i.e. Steps to reproduce & edge cases)`:
  - `- No additional QA notes provided.`
  - `- No reproduction steps provided.`
  - `- No special configurations or edge cases provided.`
- `### Regression?`: `- N/A`

If the notes include QA steps, repro steps, edge cases, environments, data requirements, or regression risks, replace the defaults with those extracted details.

## Step 4: Output

Output exactly one markdown code block using triple backticks with an `md` info string. Inside the code block, return plain markdown only using this exact structure:

````markdown
```md
## Background
- <background bullet>

## Proposed solution
- <solution bullet>

## Acceptance criteria
- <acceptance criterion bullet>

## FILLED BY THE DEVELOPER WHEN CREATING PR:

### Testable by QA
- Yes/No

### Extra info? (i.e. Steps to reproduce & edge cases)
- <Add any extra info useful for QA or leave empty if not applicable>
- <Provide detailed steps to reproduce or leave empty if not applicable>
- <Include any specific configurations, edge cases, data needed for testing or leave empty if not applicable>

### Regression?
- If change may affect other parts of a system or another feature, include information on what may be affected so that the QA can perform a regression test
- N/A if not applicable
```
````

Requirements:

- Return only the code block and nothing else.
- Do not render the markdown directly outside the code block.
- Keep the section headings exactly as shown above.
- Use multiple bullets within a section if the notes contain multiple relevant points.
