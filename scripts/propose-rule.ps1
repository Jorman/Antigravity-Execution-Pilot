param(
    [Parameter(Mandatory=$true)]
    [string]$Pattern,
    [Parameter(Mandatory=$true)]
    [string]$Category,
    [Parameter(Mandatory=$true)]
    [string]$Cause,
    [Parameter(Mandatory=$true)]
    [string]$Action,
    [string]$Alternative = "",
    [double]$Confidence = 1.0,
    [string]$Risk = "low",
    [string]$Scope = "global"
)

$baseDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot"
$propId = "prop-" + [Guid]::NewGuid().ToString("N").Substring(0, 8)

$propObj = [PSCustomObject]@{
    proposalId = $propId
    version = 1
    scope = $Scope
    status = "pending"
    pattern = $Pattern
    category = $Category
    shells = @("powershell.exe")
    platforms = @("windows")
    cause = $Cause
    action = $Action
    alternative = $Alternative
    evidenceCount = 1
    firstObserved = (Get-Date -Format "o")
    lastObserved = (Get-Date -Format "o")
    confidence = $Confidence
    risk = $Risk
    regressionTests = @("test-preflight-$Category")
    expiresAt = (Get-Date).AddMonths(6).ToString("o")
    lastValidated = (Get-Date -Format "o")
    rollbackAvailable = $true
}

$propFile = "$baseDir\proposals\pending\$propId.json"
$propObj | ConvertTo-Json -Depth 6 | Set-Content -Path $propFile -Encoding UTF8

Write-Output ($propObj | ConvertTo-Json -Depth 5)


