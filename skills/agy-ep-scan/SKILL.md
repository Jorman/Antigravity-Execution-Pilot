---
name: agy-ep-scan
description: Scans the current conversation for recurring error patterns (Fast, local learning)
---

# Local Scanner (/agy-ep-scan)

Analizza i log degli eventi della chat corrente per identificare errori ricorrenti ed estrarre proposte di regola.

## Procedura
1. Esegui lo scanner dei transcript SOLO per la chat corrente usando il Conversation ID che trovi nel tuo blocco <user_information>:
   powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\scan-transcripts.ps1 -ConversationId "<IL_TUO_CONVERSATION_ID>"
2. Elenca gli errori classificati in events/error-events.jsonl.
3. Mostra le proposte generate in proposals/pending/.
