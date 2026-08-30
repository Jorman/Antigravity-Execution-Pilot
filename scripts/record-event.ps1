function Record-GovernanceEvent {
    param(
        [string]$EventType = "command",
        [string]$Command = "",
        [int]$ExitCode = 0,
        [string]$Stdout = "",
        [string]$Stderr = "",
        [string]$Category = "none",
        [string]$Cause = "",
        [string]$Alternative = "",
        [string]$Remedy = "",
        [string]$Status = "observed",
        [string]$WorkingDir = "j:\Progetti\AG",
        [string]$OutputDir = "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\events"
    )

    . "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"

    $safeCmd = if ($null -ne $Command) { $Command } else { "" }
    $safeStdout = if ($null -ne $Stdout) { $Stdout } else { "" }
    $safeStderr = if ($null -ne $Stderr) { $Stderr } else { "" }

    $redactedCmd = Redact-Secrets -Text $safeCmd
    $redactedStdout = Redact-Secrets -Text $safeStdout
    $redactedStderr = Redact-Secrets -Text $safeStderr

    $normCmd = $safeCmd.Trim().ToLower()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normCmd)
    $hashBytes = $sha256.ComputeHash($bytes)
    $fingerprint = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })

    $eventId = "evt-" + [Guid]::NewGuid().ToString("N").Substring(0, 12)

    $eventObj = [PSCustomObject]@{
        eventId = $eventId
        timestamp = (Get-Date -Format "o")
        eventType = $EventType
        project = "antigravity-execution-pilot"
        workspace = "j:\Progetti\AG"
        workingDirectory = $WorkingDir
        shell = "powershell.exe"
        shellVersion = $PSVersionTable.PSVersion.ToString()
        commandFingerprint = $fingerprint
        redactedCommand = $redactedCmd
        exitCode = $ExitCode
        stdoutRedacted = $redactedStdout
        stderrRedacted = $redactedStderr
        category = $Category
        cause = $Cause
        alternativeFound = $Alternative
        recommendedRemedy = $Remedy
        remedyApplied = ""
        remedyVerified = $false
        repeatedCount = 1
        status = $Status
    }

    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $targetFile = "$OutputDir\$EventType-events.jsonl"
    $jsonLine = $eventObj | ConvertTo-Json -Compress
    Add-Content -Path $targetFile -Value $jsonLine -Encoding UTF8

    return $jsonLine
}

# Invocazione da CLI se chiamato con parametri
if ($MyInvocation.InvocationName -ne '.') {
    Record-GovernanceEvent @PSBoundParameters
}


