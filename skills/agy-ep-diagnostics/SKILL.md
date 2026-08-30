---
name: agy-ep-diagnostics
description: Use this skill to classify command failures, parse stderr/stdout, extract error categories, calculate command fingerprints, and record sanitized event logs.
---

# Command Diagnostics Skill

Use this skill to diagnose and classify failed commands.

## When to Use
- Immediately after any command exits with a non-zero code or unexpected stderr.
- To map errors to one of the 20 standardized governance categories.

## Categories Handled
`syntax_error`, `quoting_error`, `missing_tool`, `wrong_shell`, `permission_denied`, `smb_error`, `timeout`, `destructive_operation`, `unknown_error`.

## Execution
Run: `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\classify-error.ps1 -Command "<cmd>" -ExitCode <code> -Stderr "<err>"`

