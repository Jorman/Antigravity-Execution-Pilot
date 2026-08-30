# Workflow /agy-ep-scan

Analizza i log degli eventi e i transcript delle sessioni per identificare errori ricorrenti ed estrarre proposte di regola.

## Procedura
1. Esegui lo scanner dei transcript:
   `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\scan-transcripts.ps1`
2. Elenca gli errori classificati in `events/error-events.jsonl`.
3. Mostra le proposte generate in `proposals/pending/`.

