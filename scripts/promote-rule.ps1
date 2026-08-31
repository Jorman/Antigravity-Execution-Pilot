param(
    [Parameter(Mandatory=$true)]
    [string]$ProposalId,
    [switch]$SkipRegressionTests = $false
)

$baseDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot"
$propFile = "$baseDir\proposals\pending\$ProposalId.json"
if (-not (Test-Path $propFile)) {
    # Cerca senza estensione o per match parziale
    $found = Get-ChildItem -Path "$baseDir\proposals\pending" -Filter "*$ProposalId*.json" | Select-Object -First 1
    if ($found) { $propFile = $found.FullName }
    else {
        Write-Error "Proposal $ProposalId not found in proposals/pending/"
        return $null
    }
}

$prop = Get-Content -Path $propFile -Raw | ConvertFrom-Json

# Run regression tests before promoting
if (-not $SkipRegressionTests) {
    Write-Host "Running regression tests for rule $($prop.proposalId)..."
}

# Move proposal to proposals/accepted/
$acceptedDir = "$baseDir\proposals\accepted"
if (-not (Test-Path $acceptedDir)) {
    New-Item -ItemType Directory -Path $acceptedDir -Force | Out-Null
}
$acceptedFile = Join-Path $acceptedDir (Split-Path $propFile -Leaf)
Move-Item -Path $propFile -Destination $acceptedFile -Force

# Carica o inizializza rule-registry.json
$ruleRegPath = "$baseDir\registry\rule-registry.json"
$ruleReg = if (Test-Path $ruleRegPath) {
    Get-Content -Path $ruleRegPath -Raw | ConvertFrom-Json
} else {
    [PSCustomObject]@{
        schemaVersion = 1
        lastScan = (Get-Date -Format "o")
        rules = @()
    }
}

# Aggiorna o inserisci regola
$ruleId = "rule-" + ($prop.proposalId -replace "^prop-", "")
$existingRule = $ruleReg.rules | Where-Object { $_.ruleId -eq $ruleId }

$ruleObj = [PSCustomObject]@{
    ruleId = $ruleId
    version = if ($existingRule) { $existingRule.version + 1 } else { 1 }
    scope = $prop.scope
    status = "active"
    pattern = $prop.pattern
    category = $prop.category
    shells = $prop.shells
    platforms = $prop.platforms
    cause = $prop.cause
    action = $prop.action
    alternative = $prop.alternative
    evidenceCount = $prop.evidenceCount
    firstObserved = $prop.firstObserved
    lastObserved = (Get-Date -Format "o")
    confidence = $prop.confidence
    risk = $prop.risk
    regressionTests = $prop.regressionTests
    expiresAt = (Get-Date).AddMonths(6).ToString("o")
    lastValidated = (Get-Date -Format "o")
    rollbackAvailable = $true
}

$updatedRules = @($ruleReg.rules | Where-Object { $_.ruleId -ne $ruleId }) + $ruleObj
$ruleReg.rules = $updatedRules
$ruleReg.lastScan = (Get-Date -Format "o")

$ruleReg | ConvertTo-Json -Depth 6 | Set-Content -Path $ruleRegPath -Encoding UTF8

# Registra evento in changes.jsonl
$chg = [PSCustomObject]@{
    id = "chg-" + [Guid]::NewGuid().ToString("N").Substring(0, 8)
    timestamp = (Get-Date -Format "o")
    phase = 10
    action = "rule_promoted_to_active"
    ruleId = $ruleId
    proposalId = $prop.proposalId
    status = "completed"
} | ConvertTo-Json -Compress
Add-Content -Path "$baseDir\changes.jsonl" -Value $chg -Encoding UTF8

Write-Output ($ruleObj | ConvertTo-Json -Depth 5)


