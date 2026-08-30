# Workflow /agy-ep-rollback

Ripristina configurazioni o regole a uno stato precedente verificato tramite `backups/manifest.json`.

## Procedura
1. Ispeziona `~/.gemini/config/antigravity-execution-pilot/backups/manifest.json`.
2. Verifica i checksum SHA256 dei backup.
3. Ripristina il file originale selezionato.
4. Esegui il test di integrità e registra il rollback in `changes.jsonl`.

