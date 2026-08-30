$ErrorActionPreference = "SilentlyContinue"

try {
    # Leggi payload JSON da stdin
    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        # Fallback sicuro se stdin e' vuoto
        $res = [PSCustomObject]@{ decision = "allow" }
        Write-Output ($res | ConvertTo-Json -Compress)
        exit 0
    }

    $payload = $inputJson | ConvertFrom-Json
    $toolName = $payload.toolCall.name
    $cmd = $payload.toolCall.args.CommandLine

    # Se non e' run_command, consenti direttamente
    if ($toolName -ne "run_command" -or [string]::IsNullOrWhiteSpace($cmd)) {
        $res = [PSCustomObject]@{ decision = "allow" }
        Write-Output ($res | ConvertTo-Json -Compress)
        exit 0
    }

    # Esegui pre-flight
    $preflightScript = "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\scripts\preflight-command.ps1"
    $wd = if ($payload.workspacePaths -and $payload.workspacePaths.Count -gt 0) { $payload.workspacePaths[0] } else { "j:\Progetti\AG" }
    
    $pfRaw = & powershell -ExecutionPolicy Bypass -File $preflightScript -CommandLine $cmd -WorkingDir $wd
    $pf = $pfRaw | ConvertFrom-Json

    if ($pf.action -eq "BLOCK") {
        $res = [PSCustomObject]@{
            decision = "deny"
            reason = "[Command Governance] Bloccato: $($pf.motivation) - $($pf.problems -join '; ')"
        }
    }
    elseif ($pf.action -eq "ASK_USER") {
        $res = [PSCustomObject]@{
            decision = "ask"
            reason = "[Command Governance] Richiesta conferma: $($pf.motivation)"
        }
    }
    elseif ($pf.action -in @("REWRITE", "USE_ALTERNATIVE")) {
        # Se il comando e' riscritto su singola linea o compatibile
        $singleLineRewrite = ($pf.rewrittenCommand -split "`r`n")[0]
        $res = [PSCustomObject]@{
            decision = "allow"
            reason = "[Command Governance] Comando riscritto in modo sicuro: $($pf.motivation)"
            overwrite = [PSCustomObject]@{
                CommandLine = $singleLineRewrite
            }
        }
    }
    else {
        # ALLOW
        $res = [PSCustomObject]@{ decision = "allow" }
    }

    Write-Output ($res | ConvertTo-Json -Compress)
}
catch {
    # In caso di errore imprevisto, non bloccare l'agente
    $res = [PSCustomObject]@{
        decision = "allow"
        reason = "[Command Governance Warning] Errore interno hook, fallback su allow"
    }
    Write-Output ($res | ConvertTo-Json -Compress)
}
exit 0


