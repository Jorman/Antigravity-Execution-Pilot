# Workflow /agy-ep-update

Valuta le proposte pendenti, esegue i test di regressione e promuove le regole validate in `rule-registry.json`.

## Procedura
1. Leggi le proposte in `proposals/pending/`.
2. Esegui la suite di regressione:
   `powershell -ExecutionPolicy Bypass -File C:\Users\jorma\.gemini\config\antigravity-execution-pilot\scripts\run-regression-tests.ps1`
3. Se i test passano, promuovi la regola con `promote-rule.ps1`.
4. Registra l'evento di cambio stato e aggiorna il changelog.

