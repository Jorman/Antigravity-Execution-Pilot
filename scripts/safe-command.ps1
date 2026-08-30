param(
    [Parameter(Mandatory=$true)]
    [string]$CommandLine,
    [string]$WorkingDir = "j:\Progetti\AG",
    [switch]$ForceExecution
)

$baseDir = "C:\Users\jorma\.gemini\config\antigravity-execution-pilot"
. "$baseDir\scripts\redact-secrets.ps1"
. "$baseDir\scripts\record-event.ps1"

# 1. Pre-flight
$pfRaw = powershell -ExecutionPolicy Bypass -File "$baseDir\scripts\preflight-command.ps1" -CommandLine $CommandLine -WorkingDir $WorkingDir
$pf = $pfRaw | ConvertFrom-Json

if ($pf.action -eq "BLOCK" -and -not $ForceExecution) {
    Write-Warning "[Command Governance BLOCKED] $($pf.motivation)"
    $errEvt = Record-GovernanceEvent -EventType "error" -Command $CommandLine -ExitCode 126 -Stderr "$($pf.motivation)" -Category "$($pf.category)" -Cause "$($pf.motivation)" -WorkingDir $WorkingDir
    $res = [PSCustomObject]@{
        success = $false
        action = "BLOCKED"
        exitCode = 126
        stdout = ""
        stderr = $pf.motivation
        problems = $pf.problems
    }
    Write-Output ($res | ConvertTo-Json -Depth 5)
    return
}

$effectiveCmd = if ($pf.action -in @("REWRITE", "USE_ALTERNATIVE")) { $pf.rewrittenCommand } else { $CommandLine }

# 2. Esecuzione
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = "powershell.exe"
$startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$effectiveCmd`""
$startInfo.WorkingDirectory = $WorkingDir
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
$process.Start() | Out-Null

$stdout = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()
$exitCode = $process.ExitCode

$safeStdout = if ($stdout) { $stdout.Trim() } else { "" }
$safeStderr = if ($stderr) { $stderr.Trim() } else { "" }

# 3. Registrazione evento pulita via dot-sourcing
$evtType = if ($exitCode -eq 0) { "command" } else { "error" }
$recorded = Record-GovernanceEvent -EventType $evtType -Command $CommandLine -ExitCode $exitCode -Stdout $safeStdout -Stderr $safeStderr -WorkingDir $WorkingDir

$outObj = [PSCustomObject]@{
    success = ($exitCode -eq 0)
    originalCommand = $CommandLine
    executedCommand = $effectiveCmd
    exitCode = $exitCode
    stdout = $safeStdout
    stderr = $safeStderr
}
Write-Output ($outObj | ConvertTo-Json -Depth 5)

