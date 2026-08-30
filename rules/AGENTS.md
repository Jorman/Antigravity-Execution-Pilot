# Command Governance Plugin Rules

Queste regole si applicano globalmente per garantire l'esecuzione sicura e deterministica dei comandi:

1. **Pre-flight Obbligatorio**: Ogni comando terminale deve superare l'analisi pre-flight prima dell'esecuzione.
2. **Divieto Ripetizione Errori**: E' vietato ripetere identicamente comandi falliti nella stessa sessione.
3. **Priorita Alternative**: Usare sempre `rg` (Ripgrep) o `Select-String` al posto di `grep`, e server MCP `github` al posto di `gh`.
4. **Isolamento Script**: Usare sempre file temporanei `.cjs` o `.py` per codice Node/Python complesso invece di inline `-e` o `-c`.
5. **Separazione Step Git**: Eseguire i comandi git in step separati verificando l'esito; non usare `&&`.
6. **Protezione Segreti**: E' vietato registrare token, password, chiavi o credenziali nei file di log o report.
7. **Attenzione Condivisioni SMB**: Non eseguire installazioni pesanti o build sul drive di rete `J:\`.
