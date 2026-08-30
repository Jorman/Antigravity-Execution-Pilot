# Workflow /agy-ep-regression

Esegue la suite completa di test di regressione su tutti i vincoli Windows PowerShell e Command Governance.

## Procedura
1. Esegui lo script di regressione:
   `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\run-regression-tests.ps1`
2. Verifica che 100% dei casi di test (sintassi, quoting, alternative, segreti, SMB) risultino `PASS`.
3. Registra i risultati in `test-results.jsonl`.

