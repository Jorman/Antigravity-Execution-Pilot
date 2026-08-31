---
name: agy-ep-scan
description: Scans the current conversation for recurring error patterns (Fast, local learning)
---

# Local Scanner (/agy-ep-scan)

Analyzes event logs from the current conversation to identify recurring errors and extract rule proposals.

## Procedure
1. Run the transcript scanner ONLY for the current conversation using the Conversation ID found in your `<user_information>` block:
   `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\scan-transcripts.ps1" -ConversationId "<YOUR_CONVERSATION_ID>"`
2. List classified errors in `events/error-events.jsonl`.
3. Display generated proposals in `proposals/pending/`.
