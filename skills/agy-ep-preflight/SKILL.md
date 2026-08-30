---
name: agy-ep-preflight
description: Use this skill to validate, analyze, rewrite, or block terminal commands before execution, ensuring syntax compatibility with Windows PowerShell and preventing dangerous operations.
---

# Command Pre-Flight Skill

Use this skill to perform pre-execution safety and syntax checks.

## When to Use
- Before proposing or executing any shell command.
- To check for command chaining (`&&`), dangerous arguments, inline quoting issues, or secrets exposure.

## Pre-Flight Statuses
- `ALLOW`: Command is safe and syntax-compatible.
- `REWRITE`: Command needs automatic transformation (e.g. splitting `&&` into separate steps).
- `USE_ALTERNATIVE`: Redirect to an existing tool (e.g. `grep` -> `rg`).
- `BLOCK`: Unsafe, unsupported shell, or destructive command.
- `ASK_USER`: High-impact or ambiguous command requiring confirmation.

## Execution
Run: `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\preflight-command.ps1 -CommandLine "<command>"`

