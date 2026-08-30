# Workflow /agy-ep-audit

Esegue l'audit completo dell'ambiente, rileva tool e alternative e aggiorna i registri senza installare pacchetti.

## Procedura
1. Esegui il rilevamento dell'ambiente:
   `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\detect-environment.ps1`
2. Esegui la scoperta dei tool:
   `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\discover-tools.ps1`
3. Esegui la scoperta delle alternative:
   `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\discover-alternatives.ps1`
4. Mostra un riepilogo delle capacità disponibili all'utente.

