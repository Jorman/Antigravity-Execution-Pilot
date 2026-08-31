param(
    [string]$TranscriptDir = "$env:USERPROFILE\.gemini\antigravity\brain",
    [string]$ConversationId = "",
    [string]$OutputDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\proposals\pending",
    [int]$MinOccurrences = 1
)

. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"
. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\record-event.ps1"

$ErrorActionPreference = "SilentlyContinue"

if ([string]::IsNullOrWhiteSpace($ConversationId)) {
    Write-Host "Global transcript scan in: $TranscriptDir ..."
    $transcriptFiles = Get-ChildItem -Path $TranscriptDir -Recurse -Filter "transcript.jsonl" -ErrorAction SilentlyContinue
} else {
    Write-Host "Single conversation transcript scan for ID: $ConversationId ..."
    $targetTranscript = Join-Path $TranscriptDir "$ConversationId\.system_generated\logs\transcript.jsonl"
    if (Test-Path $targetTranscript) {
        $transcriptFiles = @(Get-Item $targetTranscript)
    } else {
        $transcriptFiles = @()
        Write-Host "No transcript found for current conversation."
    }
}

$foundErrors = @()
$fingerprintMap = @{}

foreach ($tf in $transcriptFiles) {
    $lines = Get-Content -Path $tf.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    $lastRunCommand = ""
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $step = $line | ConvertFrom-Json
            
            # If step contains run_command tool calls, save command
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
            $isSyntaxErr = ($step.content -match "ParseError|SyntaxError|Termine '.*' non riconosciuto|is not recognized|Cannot find path")
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
                        # Classify error
                        $classification = & powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\classify-error.ps1" -Command $cmd -Stderr $stderr
                        $classObj = $classification | ConvertFrom-Json

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
                        Record-GovernanceEvent -EventType "error" -Command $cmd -ExitCode 1 -Stderr $stderr -Category $fingerprintMap[$fingerprint].category -Cause $fingerprintMap[$fingerprint].cause -Alternative $fingerprintMap[$fingerprint].alternative -Remedy $fingerprintMap[$fingerprint].remedy -Status "observed"
                    } else {
                        $fingerprintMap[$fingerprint].count += 1
                        $fingerprintMap[$fingerprint].lastObserved = $step.created_at
                    }
                }
            }
        } catch {}
    }
}

# --- DYNAMIC PROPOSAL GENERATION ---
# Proposals are generated dynamically from real errors observed in transcripts.

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$acceptedDir   = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\proposals\accepted"
$ruleRegPath   = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\registry\rule-registry.json"
$activeRuleIds = @()
if (Test-Path $ruleRegPath) {
    $reg = Get-Content -Path $ruleRegPath -Raw | ConvertFrom-Json
    if ($reg.rules) { $activeRuleIds = @($reg.rules | ForEach-Object { $_.ruleId }) }
}

$generatedProposals = @()
$counter = 1

foreach ($fp in $fingerprintMap.GetEnumerator()) {
    $entry = $fp.Value
    if ($entry.count -lt $MinOccurrences) { continue }

    # Create deterministic proposal ID from fingerprint
    $shortFp  = $fp.Key.Substring(0, 8)
    $propId   = "prop-dyn-$shortFp"
    $ruleId   = "rule-dyn-$shortFp"

    # Skip if already accepted or in registry
    $accFile  = "$acceptedDir\$propId.json"
    if ((Test-Path $accFile) -or ($activeRuleIds -contains $ruleId)) { continue }

    $propObj = [PSCustomObject]@{
        proposalId       = $propId
        version          = 1
        scope            = "global"
        status           = "pending"
        pattern          = ($entry.command -replace '"', "'")
        category         = $entry.category
        shells           = @("powershell.exe")
        platforms        = @("windows")
        cause            = $entry.cause
        action           = if ($entry.alternative) { "REWRITE" } else { "BLOCK" }
        alternative      = $entry.alternative
        remedy           = $entry.remedy
        evidenceCount    = $entry.count
        firstObserved    = $entry.firstObserved
        lastObserved     = $entry.lastObserved
        sampleFile       = $entry.sampleFile
        confidence       = [math]::Min(1.0, [math]::Round($entry.count / 3.0, 2))
        risk             = "low"
        regressionTests  = @("test-preflight-$($entry.category)")
        expiresAt        = (Get-Date).AddMonths(6).ToString("o")
        lastValidated    = (Get-Date -Format "o")
        rollbackAvailable = $true
    }

    $propFile = "$OutputDir\$propId.json"
    $propObj | ConvertTo-Json -Depth 6 | Set-Content -Path $propFile -Encoding UTF8
    $generatedProposals += $propObj
    $counter++
}

# Statistical output
[PSCustomObject]@{
    transcriptsScanned      = if ($transcriptFiles) { $transcriptFiles.Count } else { 0 }
    uniqueErrorFingerprints = $fingerprintMap.Keys.Count
    newProposalsGenerated   = $generatedProposals.Count
    proposals               = ($generatedProposals | Select-Object proposalId, pattern, category, action)
} | ConvertTo-Json -Depth 5



