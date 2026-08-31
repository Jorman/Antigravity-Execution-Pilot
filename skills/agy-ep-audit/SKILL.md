---
name: agy-ep-audit
description: Audits your local environment: PATH, tools, permissions, SMB drives
---

# Command Environment Skill

Use this skill to inspect and verify the execution environment.

## When to Use
- At the start of new sessions or when diagnosing environment-specific errors.
- When verifying whether a path is on a local drive (C:\) or SMB network share (J:\).
- When checking PowerShell version or user permission elevation.

## Procedure
1. Run `detect-environment.ps1`:
   `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\detect-environment.ps1"`
2. Inspect the output registry in `$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\registry\environment-registry.json`.
3. Check filesystem capabilities and permission grants before planning heavy disk I/O.


