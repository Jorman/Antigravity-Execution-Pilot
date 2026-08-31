---
name: agy-ep-scan-all
description: Scans all historical conversations across all projects (Global learning, takes longer)
---

# Global Scanner (/agy-ep-scan-all)

Analyzes event logs GLOBALLY across ALL past conversations and projects to identify recurring errors and extract rule proposals.

## Procedure
1. Run the transcript scanner across all files without passing an ID:
   `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\scan-transcripts.ps1"`
2. List classified errors in `events/error-events.jsonl`.
3. Display generated proposals in `proposals/pending/`.
