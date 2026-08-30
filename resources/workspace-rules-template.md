# Regole Workspace per Command Governance

Queste regole si applicano al repository/progetto locale:

## 1. Ambiente di Esecuzione
- Stack tecnologico: Node.js / Python / Git.
- Shell supportata: Windows PowerShell.
- Percorso workspace: verificare se locale (C:\) o su share di rete SMB (J:\).

## 2. Direttive Operative
- Usare `rg` o `Select-String` per ricerche testuali nel progetto.
- Eseguire i comandi di build e test esclusivamente su drive locali o cartella temporanea locale (%TEMP%) se il progetto risiede su share SMB.
- Proteggere tutte le credenziali e API keys (redazione automatica).
