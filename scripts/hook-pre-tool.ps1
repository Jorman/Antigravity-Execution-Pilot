$ErrorActionPreference = "SilentlyContinue"

try {
    # Read JSON payload from stdin
    $inputJson = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($inputJson)) {
        # Safe fallback if stdin is empty
        $res = [PSCustomObject]@{ decision = "allow" }
        Write-Output ($res | ConvertTo-Json -Compress)
        exit 0
    }

    $payload = $inputJson | ConvertFrom-Json
    $toolName = $payload.toolCall.name
    $cmd = $payload.toolCall.args.CommandLine

    # If not run_command, allow directly
    if ($toolName -ne "run_command" -or [string]::IsNullOrWhiteSpace($cmd)) {
        $res = [PSCustomObject]@{ decision = "allow" }
        Write-Output ($res | ConvertTo-Json -Compress)
        exit 0
    }

    # Execute pre-flight check
    $preflightScript = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\preflight-command.ps1"
    $wd = if ($payload.workspacePaths -and $payload.workspacePaths.Count -gt 0) { $payload.workspacePaths[0] } else { (Get-Location).Path }
    
    $pfRaw = & powershell -ExecutionPolicy Bypass -File $preflightScript -CommandLine $cmd -WorkingDir $wd
    $pf = $pfRaw | ConvertFrom-Json

    if ($pf.action -eq "BLOCK") {
        $res = [PSCustomObject]@{
            decision = "deny"
            reason = "[Command Governance] Blocked: $($pf.motivation) - $($pf.problems -join '; ')"
        }
    }
    elseif ($pf.action -eq "ASK_USER") {
        $res = [PSCustomObject]@{
            decision = "ask"
            reason = "[Command Governance] Confirmation required: $($pf.motivation)"
        }
    }
    elseif ($pf.action -in @("REWRITE", "USE_ALTERNATIVE")) {
        # If the command is rewritten on a single line or compatible
        $singleLineRewrite = ($pf.rewrittenCommand -split "`r`n")[0]
        $res = [PSCustomObject]@{
            decision = "allow"
            reason = "[Command Governance] Command safely rewritten: $($pf.motivation)"
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
    # Fallback to allow on unexpected hook exception
    $res = [PSCustomObject]@{
        decision = "allow"
        reason = "[Command Governance Warning] Internal hook error, falling back to allow"
    }
    Write-Output ($res | ConvertTo-Json -Compress)
}
exit 0


