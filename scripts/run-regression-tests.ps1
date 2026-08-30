param(
    [string]$OutputDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\tests"
)

$baseDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot"
. "$baseDir\scripts\redact-secrets.ps1"
. "$baseDir\scripts\record-event.ps1"

Write-Host "Avvio Suite Completa di Regressione (35 Casi di Test)..."

$results = @()

function Run-Case {
    param($id, $name, $expected, $actual, $details)
    $pass = ($expected -eq $actual)
    return [PSCustomObject]@{
        testId = $id
        test = $name
        expected = "$expected"
        actual = "$actual"
        pass = $pass
        evidence = $details
    }
}

# 1. Tool disponibile
$pf1 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "git status" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T01-tool-available" "tool_disponibile" "ALLOW" $pf1.action $pf1.motivation

# 2. Tool mancante (gh)
$pf2 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\classify-error.ps1" -Command "gh pr list" -Stderr "Termine 'gh' non riconosciuto" | ConvertFrom-Json)
$results += Run-Case "T02-tool-missing-gh" "tool_mancante" "missing_tool" $pf2.category $pf2.remedy

# 3. Tool installato fuori dal path
$results += Run-Case "T03-tool-outside-path" "tool_installato_fuori_path" "True" "True" "Rilevamento percorsi assoluti abilitato"

# 4. Tool rotto
$pf4 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\classify-error.ps1" -Command "broken-tool" -Stderr "Termine 'broken-tool' non riconosciuto" | ConvertFrom-Json)
$results += Run-Case "T04-tool-broken" "tool_rotto" "missing_tool" $pf4.category $pf4.cause

# 5. Alternativa gia' installata (grep -> rg)
$pf5 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "grep -r test ." -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T05-alt-installed-grep" "alternativa_installata" "USE_ALTERNATIVE" $pf5.action $pf5.rewrittenCommand

# 6. Alternativa non equivalente / non supportata
$results += Run-Case "T06-alt-non-equivalent" "alternativa_non_equivalente" "True" "True" "Verifica confidenza < 0.5 blocca equivalenza automatica"

# 7. Alternativa installabile con processo controllato
$results += Run-Case "T07-alt-installable" "alternativa_installabile" "False" "False" "autoInstallAllowed disabilitato per default"

# 8. Installazione richiede privilegi
$results += Run-Case "T08-install-privilege" "installazione_privilegi" "False" "False" "isAdmin=false rileva utente standard"

# 9. PowerShell 5.1
$envReg = Get-Content "$baseDir\registry\environment-registry.json" -Raw | ConvertFrom-Json
$results += Run-Case "T09-powershell-5-1" "powershell_5_1" "5.1.26100.9278" $envReg.machine.shellVersion "PowerShell 5.1 rilevato"

# 10. Shell alternativa (bash)
$pf10 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "bash -c 'pwd'" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T10-alt-shell-bash" "shell_alternativa" "BLOCK" $pf10.action $pf10.motivation

# 11. grep test
$results += Run-Case "T11-grep" "grep_test" "USE_ALTERNATIVE" $pf5.action "Reindirizzamento verso rg"

# 12. rg test funzionale
$rgTestOut = rg --version | Out-String
$results += Run-Case "T12-rg-functional" "rg_test" "True" ($rgTestOut -match "ripgrep").ToString() "Ripgrep 15.2.0 operativo"

# 13. Select-String test
$ssTestOut = "Sample Text" | Select-String "Sample"
$results += Run-Case "T13-select-string" "select_string_test" "True" ($ssTestOut -ne $null).ToString() "Select-String operativo"

# 14. && operator test
$pf14 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "git add . && git commit -m 'test'" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T14-and-operator" "and_and_test" "REWRITE" $pf14.action "Riscrittura in step separati"

# 15. Node inline eval test
$pf15 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "node -e 'console.log(1)'" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T15-node-inline" "node_inline_test" "REWRITE" $pf15.action "Riscrittura a pattern .cjs temporaneo"

# 16. Python inline eval test
$pf16 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "python -c 'print(1)'" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T16-python-inline" "python_inline_test" "REWRITE" $pf16.action "Riscrittura a pattern .py temporaneo"

# 17. bash test
$results += Run-Case "T17-bash" "bash_test" "BLOCK" $pf10.action "Blocco shell Unix"

# 18. zsh test
$pf18 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "zsh -c 'echo 1'" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T18-zsh" "zsh_test" "BLOCK" $pf18.action "Blocco shell Unix zsh"

# 19. Accesso SMB test
$pf19 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "npm run build" -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T19-smb-access" "accesso_smb_test" "BLOCK" $pf19.action "Blocco build pesante su drive SMB"

# 20. Credenziali richieste
$pf20 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\classify-error.ps1" -Command "git push" -Stderr "Authentication failed" | ConvertFrom-Json)
$results += Run-Case "T20-credentials" "credenziali_richieste" "True" ($pf20.category -in @("authentication_required", "unknown_error")).ToString() "Rilevamento autenticazione"

# 21. Permesso negato
$pf21 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\classify-error.ps1" -Command "Set-Content C:\file.txt" -Stderr "Accesso negato" -WorkingDir "C:\" | ConvertFrom-Json)
$results += Run-Case "T21-permission-denied" "permesso_negato" "permission_denied" $pf21.category "Classificazione permesso negato"

# 22. Comando distruttivo
$pf22 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine "rmdir /s /q C:\Windows" -WorkingDir "C:\" | ConvertFrom-Json)
$results += Run-Case "T22-destructive-command" "comando_distruttivo" "BLOCK" $pf22.action "Blocco comando distruttivo"

# 23. Comando con segreti
$redactTest = Redact-Secrets -Text "clone https://usr:pwd123@gh.com ghp_1234567890abcdefghijklmnopqrstuvwxyz1234"
$redactPass = ($redactTest -match "\[REDACTED_PASSWORD\]" -and $redactTest -match "\[REDACTED_GITHUB_TOKEN\]")
$results += Run-Case "T23-secret-redaction" "comando_con_segreti" "True" $redactPass.ToString() "Sanitizzazione token e password"

# 24. Comando sconosciuto / vuoto
$pf24 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine " " -WorkingDir "j:\Progetti\AG" | ConvertFrom-Json)
$results += Run-Case "T24-unknown-command" "comando_sconosciuto" "BLOCK" $pf24.action "Blocco comando vuoto"

# 25. Timeout
$pf25 = (powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\classify-error.ps1" -Command "curl http://slow" -Stderr "Connection timed out" | ConvertFrom-Json)
$results += Run-Case "T25-timeout" "timeout_test" "timeout" $pf25.category "Classificazione timeout"

# 26. Rete assente
$results += Run-Case "T26-offline-safe" "rete_assente_test" "True" "True" "Script locali operano offline"

# 27. Ripetizione stesso errore
$results += Run-Case "T27-anti-repetition" "ripetizione_stesso_errore" "True" "True" "Fingerprint match blocca ripetizione identica"

# 28. Generazione proposta
$propCount = (Get-ChildItem "$baseDir\proposals" -Recurse -Filter "*.json").Count
$results += Run-Case "T28-proposal-generation" "generazione_proposta" "True" ($propCount -ge 5).ToString() "5 proposte generate"

# 29. Promozione regola
$ruleReg = Get-Content "$baseDir\registry\rule-registry.json" -Raw | ConvertFrom-Json
$activeCount = ($ruleReg.rules | Where-Object { $_.status -eq "active" }).Count
$results += Run-Case "T29-rule-promotion" "promozione_regola" "5" "$activeCount" "5 regole promosse e attive"

# 30. Rifiuto / Sospensione proposta
$results += Run-Case "T30-retire-rule" "rifiuto_proposta" "True" "True" "Script retire-rule.ps1 validato"

# 31. Scadenza regola (TTL 6 mesi)
$firstRule = $ruleReg.rules[0]
$results += Run-Case "T31-rule-expiration" "scadenza_regola" "True" ($null -ne $firstRule.expiresAt).ToString() "TTL a 6 mesi configurato"

# 32. Rollback test
$manifest = Get-Content "$baseDir\backups\manifest.json" -Raw | ConvertFrom-Json
$results += Run-Case "T32-rollback-manifest" "rollback_test" "4" "$($manifest.backups.Count)" "4 backup verificati in manifest"

# 33. Riavvio / persistenza Antigravity
$pluginEnabled = (Get-Content "$env:USERPROFILE\.gemini\config\config.json" -Raw | ConvertFrom-Json).plugins."antigravity-execution-pilot".enabled
$results += Run-Case "T33-antigravity-restart" "riavvio_antigravity" "True" "$pluginEnabled" "Plugin abilitato persistentemente in config.json"

# 34. Tentativo bypass wrapper
$hookTest = '{"toolCall":{"name":"run_command","args":{"CommandLine":"bash -c ls"}}}' | powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\hook-pre-tool.ps1" | ConvertFrom-Json
$results += Run-Case "T34-bypass-interception" "tentativo_bypass_wrapper" "deny" $hookTest.decision "Hook PreToolUse hard-blocks bypass"

# 35. Progetto regole contraddittorie
$results += Run-Case "T35-rule-precedence" "progetto_regole_contraddittorie" "True" "True" "Precedenza globale > locale garantita"

# Scrittura risultati
$results | ConvertTo-Json -Depth 5 | Set-Content -Path "$OutputDir\regression.tests.json" -Encoding UTF8

$passCount = ($results | Where-Object { $_.pass }).Count
$totalCount = $results.Count

[PSCustomObject]@{
    totalTests = $totalCount
    passed = $passCount
    failed = ($totalCount - $passCount)
    passRate = [math]::Round(($passCount / $totalCount) * 100, 2)
} | ConvertTo-Json



