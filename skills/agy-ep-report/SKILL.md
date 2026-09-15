---
name: agy-ep-report
description: Generates a report of all intercepted commands and error events in this session
---

# Session Governance Reporting Skill

Use this skill to generate a structured statistical summary of intercepted commands, blocked operations, rewrites, and recorded error events.

## Execution

Execute the reporting script via PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\generate-report.ps1"
```

## Output Summary
The script aggregates:
- Total recorded events from `error-events.jsonl`
- Count of active governance rules
- Error distribution by category (`syntax_error`, `missing_tool`, `smb_error`, `wrong_shell`, `quoting_error`, etc.)
- Status breakdown (`observed`, `blocked`, `rewritten`)
