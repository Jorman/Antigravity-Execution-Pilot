param(
    [string]$EventsFile = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\events\error-events.jsonl",
    [string]$RuleRegistryFile = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\registry\rule-registry.json"
)

$events = @()
if (Test-Path $EventsFile) {
    Get-Content $EventsFile -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_)) {
            try { $events += ($_ | ConvertFrom-Json) } catch {}
        }
    }
}

$ruleCount = 0
if (Test-Path $RuleRegistryFile) {
    try {
        $reg = Get-Content $RuleRegistryFile -Raw | ConvertFrom-Json
        $ruleCount = if ($reg.rules) { $reg.rules.Count } else { 0 }
    } catch {}
}

$byCategory = @{}
$byStatus = @{}

foreach ($ev in $events) {
    $cat = if ($ev.category) { $ev.category } else { "unknown" }
    $st = if ($ev.status) { $ev.status } else { "observed" }
    
    if (-not $byCategory.ContainsKey($cat)) { $byCategory[$cat] = 0 }
    $byCategory[$cat]++

    if (-not $byStatus.ContainsKey($st)) { $byStatus[$st] = 0 }
    $byStatus[$st]++
}

$report = [PSCustomObject]@{
    timestamp = (Get-Date -Format "o")
    totalEventsRecorded = $events.Count
    activeRulesCount = $ruleCount
    eventsByCategory = $byCategory
    eventsByStatus = $byStatus
}

Write-Output ($report | ConvertTo-Json -Depth 5)
