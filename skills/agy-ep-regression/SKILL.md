---
name: agy-ep-regression
description: Runs the full 35-case regression test suite
---

# Command Regression Skill

Use this skill to execute the full governance regression test suite.

## When to Use
- Before approving rule promotions or finalizing development phases.
- To ensure no regressions exist for `&&`, `grep`, `node -e`, `python -c`, SMB `J:\`, or secret redaction.

## Execution
Run: `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\run-regression-tests.ps1`


