---
name: agy-ep-scan-all
description: Scans all historical conversations across all projects (Global learning, takes longer)
---

# Global Scanner (/agy-ep-scan-all)

Analizza GLOBALMENTE i log degli eventi di TUTTE le chat e progetti passati per identificare errori ricorrenti ed estrarre proposte di regola.

## Procedura
1. Esegui lo scanner dei transcript su tutti i file senza passare ID:
   powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\scan-transcripts.ps1
2. Elenca gli errori classificati in events/error-events.jsonl.
3. Mostra le proposte generate in proposals/pending/.
