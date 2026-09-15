param(
    [string]$TranscriptDir = "$env:USERPROFILE\.gemini\antigravity\brain",
    [string]$ConversationId = "",
    [string]$OutputDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\proposals\pending",
    [int]$MinOccurrences = 1
)

. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"
. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\record-event.ps1"
. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\classify-error.ps1"

$ErrorActionPreference = "SilentlyContinue"

if ([string]::IsNullOrWhiteSpace($ConversationId)) {
    Write-Host "Scansione globale transcript in: $TranscriptDir ..."
    $transcriptFiles = Get-ChildItem -Path $TranscriptDir -Recurse -Filter "transcript.jsonl" -ErrorAction SilentlyContinue
} else {
    Write-Host "Scansione singola chat transcript per ID: $ConversationId ..."
    $targetTranscript = Join-Path $TranscriptDir "$ConversationId\.system_generated\logs\transcript.jsonl"
    if (Test-Path $targetTranscript) {
        $transcriptFiles = @(Get-Item $targetTranscript)
    } else {
        $transcriptFiles = @()
        Write-Host "Nessun transcript trovato per la conversazione corrente."
    }
}

$fingerprintMap = @{}

foreach ($tf in $transcriptFiles) {
    if (-not (Test-Path $tf.FullName)) { continue }
    
    $lines = Get-Content $tf.FullName -ErrorAction SilentlyContinue
    if (-not $lines) { continue }

    $lastRunCommand = ""

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $step = $line | ConvertFrom-Json
            
            # If step contains run_command tool call, track command
            if ($step.tool_calls) {
                foreach ($tc in $step.tool_calls) {
                    if ($tc.name -eq "run_command" -and $tc.args -and $tc.args.CommandLine) {
                        $cmdVal = $tc.args.CommandLine
                        if ($cmdVal -is [string]) {
                            $lastRunCommand = $cmdVal.Trim('"')
                        }
                    }
                }
            }

            # Check if step contains an execution error
            $isErrorCode = ($step.content -match "The command exited with code [1-9]")
            $isSyntaxErr = ($step.content -match "ParseError|SyntaxError|Termine '.*' non riconosciuto|is not recognized|Cannot find path|Authentication failed|Accesso negato")
            $hasError = ($step.status -eq "ERROR" -or $isErrorCode -or $isSyntaxErr)

            if ($hasError) {
                $cmd = $lastRunCommand
                if (-not $cmd -and $step.content) {
                    if ($step.content -match 'CommandLine:\s*([^\r\n]+)') {
                        $cmd = $matches[1]
                    }
                }

                if ($cmd) {
                    $normCmd = $cmd.Trim().ToLower()
                    $sha256 = [System.Security.Cryptography.SHA256]::Create()
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normCmd)
                    $hashBytes = $sha256.ComputeHash($bytes)
                    $fingerprint = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })

                    if (-not $fingerprintMap.ContainsKey($fingerprint)) {
                        $stderr = $step.content
                        
                        # Direct classification via function call
                        $classObj = Classify-CommandError -Command $cmd -Stderr $stderr
                        
                        $fingerprintMap[$fingerprint] = @{
                            command = $cmd
                            category = if ($classObj) { $classObj.category } else { "unknown_error" }
                            cause = if ($classObj) { $classObj.cause } else { "Unclassified error" }
                            alternative = if ($classObj) { $classObj.alternative } else { "" }
                            remedy = if ($classObj) { $classObj.remedy } else { "" }
                            count = 1
                            firstObserved = $step.created_at
                            lastObserved = $step.created_at
                            sampleFile = $tf.FullName
                        }

                        # Record event
                        Record-GovernanceEvent -EventType "error" -Command $cmd -ExitCode 1 -Stderr $stderr -Category $fingerprintMap[$fingerprint].category -Cause $fingerprintMap[$fingerprint].cause -Alternative $fingerprintMap[$fingerprint].alternative -Remedy $fingerprintMap[$fingerprint].remedy -Status "observed" -Timestamp $step.created_at
                    } else {
                        $fingerprintMap[$fingerprint].count += 1
                        $fingerprintMap[$fingerprint].lastObserved = $step.created_at
                    }
                }
            }
        } catch {
            Write-Verbose "Skipping invalid JSON line in $($tf.FullName): $_"
        }
    }
}

# --- DYNAMIC PROPOSAL GENERATION ---
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$acceptedDir   = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\proposals\accepted"
$ruleRegPath   = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\registry\rule-registry.json"
$activeRuleIds = @()
if (Test-Path $ruleRegPath) {
    try {
        $reg = Get-Content $ruleRegPath -Raw | ConvertFrom-Json
        $activeRuleIds = @($reg.rules | Where-Object { $_.status -eq 'active' } | ForEach-Object { $_.ruleId })
    } catch {}
}

$generatedProposals = @()

foreach ($fp in $fingerprintMap.Keys) {
    $errInfo = $fingerprintMap[$fp]
    if ($errInfo.count -ge $MinOccurrences -and $errInfo.category -ne "unknown_error") {
        $propId = "prop-" + $fp.Substring(0, 8)
        $propFile = Join-Path $OutputDir "$propId-$($errInfo.category).json"
        
        $proposal = [PSCustomObject]@{
            proposalId = $propId
            createdAt = (Get-Date -Format "o")
            category = $errInfo.category
            pattern = $errInfo.command
            fingerprint = $fp
            occurrences = $errInfo.count
            cause = $errInfo.cause
            remedy = $errInfo.remedy
            action = if ($errInfo.alternative) { "USE_ALTERNATIVE" } elseif ($errInfo.category -in @("syntax_error", "quoting_error")) { "REWRITE" } else { "BLOCK" }
            alternative = $errInfo.alternative
            confidence = [Math]::Min(1.0, 0.6 + ($errInfo.count * 0.1))
            status = "pending"
        }

        $proposal | ConvertTo-Json -Depth 5 | Set-Content -Path $propFile -Encoding UTF8
        $generatedProposals += $proposal
    }
}

# Output statistical JSON summary
[PSCustomObject]@{
    transcriptsScanned = if ($transcriptFiles) { $transcriptFiles.Count } else { 0 }
    uniqueErrorFingerprints = $fingerprintMap.Keys.Count
    proposalsGenerated = $generatedProposals.Count
    proposals = ($generatedProposals | Select-Object proposalId, pattern, category, action)
} | ConvertTo-Json -Depth 5
