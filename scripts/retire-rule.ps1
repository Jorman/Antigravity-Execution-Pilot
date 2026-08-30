param(
    [Parameter(Mandatory=$true)]
    [string]$RuleId,
    [string]$Reason = "Scadenza naturale o contesto mutato",
    [string]$NewStatus = "retired" # retired, suspended, deprecated
)

$baseDir = "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot"
$ruleRegPath = "$baseDir\registry\rule-registry.json"

if (-not (Test-Path $ruleRegPath)) {
    Write-Error "rule-registry.json non presente"
    return $null
}

$ruleReg = Get-Content -Path $ruleRegPath -Raw | ConvertFrom-Json
$targetRule = $ruleReg.rules | Where-Object { $_.ruleId -eq $RuleId }

if (-not $targetRule) {
    Write-Error "Regola $RuleId non trovata nel registro"
    return $null
}

$targetRule.status = $NewStatus
$targetRule.lastValidated = (Get-Date -Format "o")
$ruleReg.lastScan = (Get-Date -Format "o")

$ruleReg | ConvertTo-Json -Depth 6 | Set-Content -Path $ruleRegPath -Encoding UTF8

# Sposta in proposals/retired/ se presente
$acceptedFile = Get-ChildItem -Path "$baseDir\proposals\accepted" -Filter "*$($RuleId -replace '^rule-', '')*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($acceptedFile) {
    $retiredFile = "$baseDir\proposals\retired\$($acceptedFile.Name)"
    Move-Item -Path $acceptedFile.FullName -Destination $retiredFile -Force
}

$chg = [PSCustomObject]@{
    id = "chg-" + [Guid]::NewGuid().ToString("N").Substring(0, 8)
    timestamp = (Get-Date -Format "o")
    phase = 10
    action = "rule_status_changed"
    ruleId = $RuleId
    newStatus = $NewStatus
    reason = $Reason
    status = "completed"
} | ConvertTo-Json -Compress
Add-Content -Path "$baseDir\changes.jsonl" -Value $chg -Encoding UTF8

Write-Output ($targetRule | ConvertTo-Json -Depth 5)


