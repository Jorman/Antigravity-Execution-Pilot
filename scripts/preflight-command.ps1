param(
    [string]$CommandLine = "",
    [string]$WorkingDir = "",
    [string]$Shell = "powershell.exe",
    [switch]$CheckAntiRepetition = $true
)

if ([string]::IsNullOrWhiteSpace($WorkingDir)) {
    $WorkingDir = (Get-Location).Path
}

. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"

if ([string]::IsNullOrWhiteSpace($CommandLine)) {
    $out = [PSCustomObject]@{
        originalCommand = ""
        action = "BLOCK"
        rewrittenCommand = ""
        category = "invalid_arguments"
        problems = @("Empty or null command")
        needsApproval = $false
        confidence = 1.0
        motivation = "Cannot execute empty commands."
    }
    Write-Output ($out | ConvertTo-Json -Depth 5)
    return
}

$trimmed = $CommandLine.Trim()
$action = "ALLOW"
$rewritten = $trimmed
$category = "none"
$problems = @()
$needsApproval = $false
$confidence = 1.0
$motivation = "Command verified and safe."

# Anti-repetition check
if ($CheckAntiRepetition) {
    $normCmd = $trimmed.ToLower()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normCmd)
    $hashBytes = $sha256.ComputeHash($bytes)
    $fingerprint = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })

    $errLog = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\events\error-events.jsonl"
    if (Test-Path $errLog) {
        $recentErrors = Get-Content -Path $errLog -ErrorAction SilentlyContinue | ForEach-Object { $_ | ConvertFrom-Json }
        $match = $recentErrors | Where-Object { $_.commandFingerprint -eq $fingerprint -and $_.status -eq "observed" }
        if ($match) {
            $out = [PSCustomObject]@{
                originalCommand = (Redact-Secrets -Text $CommandLine)
                action = "BLOCK"
                rewrittenCommand = ""
                category = "repeated_failed_command"
                problems = @("Command already failed previously with fingerprint: $fingerprint")
                needsApproval = $true
                confidence = 1.0
                motivation = "STRICT GOVERNANCE: Repeating an identical failed command in the same session without applying a fix is prohibited."
            }
            Write-Output ($out | ConvertTo-Json -Depth 5)
            return
        }
    }
}

# Check for destructive commands
if ($trimmed -match "(?i)\b(rmdir\s+/s\s+/q\s+[c-z]:\\|format\s+[c-z]:|drop\s+database|del\s+/s\s+/q\s+[c-z]:\\windows)") {
    $action = "BLOCK"
    $category = "destructive_operation"
    $problems += "Potentially destructive system command"
    $needsApproval = $true
    $motivation = "Command blocked to prevent catastrophic data loss."
}
# Check for && operator
elseif ($trimmed -match "\s+&&\s+") {
    $action = "REWRITE"
    $category = "syntax_error"
    $problems += "Operator '&&' is not supported in Windows PowerShell 5.1"
    $steps = $trimmed -split "\s+&&\s+"
    $rewritten = ($steps | ForEach-Object { $_.Trim() }) -join "`r`n# then execute:`r`n"
    $motivation = "Separate commands chained with '&&' into individual sequential steps."
}
# Check for grep
elseif ($trimmed -match "(?i)^\s*grep(\.exe)?\b") {
    $action = "USE_ALTERNATIVE"
    $category = "missing_tool"
    $problems += "grep is not installed in the Windows PATH"
    $rewritten = $trimmed -replace "(?i)^\s*grep(\.exe)?\b", "rg"
    $motivation = "Replace 'grep' with 'rg' (Ripgrep) or use 'Select-String'."
}
# Check for complex node -e
elseif ($trimmed -match "(?i)^\s*node(\.exe)?\s+-e\s+\S") {
    $action = "REWRITE"
    $category = "quoting_error"
    $problems += "node -e with complex inline strings causes SyntaxError on PowerShell"
    $rewritten = "Create a temporary .cjs file, run 'node file.cjs', and delete the file"
    $motivation = "Adopt the mandatory temporary .cjs script file pattern."
}
# Check for complex python -c
elseif ($trimmed -match "(?i)^\s*python(\.exe)?\s+-c\s+\S") {
    $action = "REWRITE"
    $category = "quoting_error"
    $problems += "python -c with complex inline strings causes SyntaxError on PowerShell"
    $rewritten = "Create a temporary .py file, run 'python file.py', and delete the file"
    $motivation = "Adopt the mandatory temporary .py script file pattern."
}
# Check for bash/zsh/sh
elseif ($trimmed -match "(?i)^\s*(bash|zsh|sh)(\.exe)?\s+(-c\s+)?") {
    $action = "BLOCK"
    $category = "wrong_shell"
    $problems += "Unix shell is not available natively on Windows"
    $motivation = "Rewrite the command using PowerShell cmdlets or a Node/Python script."
}
# Check for heavy operations on SMB
elseif ($trimmed -match "(?i)\b(npm\s+(run\s+(build|lint|test)|install|ci))\b") {
    $isNet = $false
    if ($WorkingDir -match '^\\\\') {
        $isNet = $true
    } elseif ($WorkingDir -match '^([A-Za-z]):') {
        $dl = $matches[1]
        $drv = Get-PSDrive -Name $dl -PSProvider FileSystem -ErrorAction SilentlyContinue
        if ($drv -and $drv.DisplayRoot) { $isNet = $true }
    }
    if ($isNet) {
        $action = "BLOCK"
        $category = "smb_error"
        $problems += "Heavy build/lint/test/install operations are not supported on SMB network shares ($WorkingDir)"
        $motivation = "Perform the operation in a local temporary directory (%TEMP%) and synchronize files."
    }
}

$out = [PSCustomObject]@{
    originalCommand = (Redact-Secrets -Text $CommandLine)
    action = $action
    rewrittenCommand = $rewritten
    category = $category
    problems = $problems
    needsApproval = $needsApproval
    confidence = $confidence
    motivation = $motivation
}

Write-Output ($out | ConvertTo-Json -Depth 5)



