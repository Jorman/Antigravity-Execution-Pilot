param(
    [string]$Command = "",
    [int]$ExitCode = 1,
    [string]$Stderr = "",
    [string]$Stdout = "",
    [string]$WorkingDir = ""
)

if ([string]::IsNullOrWhiteSpace($WorkingDir)) {
    $WorkingDir = (Get-Location).Path
}

. "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"

$combinedErr = "$Stderr `n $Stdout"
$category = "unknown_error"
$cause = "Unspecified error or non-zero exit code"
$remedy = ""
$alternative = ""

if ($combinedErr -match "(& era imprevisto|The token '&&' is not a valid statement separator)") {
    $category = "syntax_error"
    $cause = "Operator '&&' is not supported as a statement separator in Windows PowerShell 5.1"
    $remedy = "Execute commands separately in distinct sequential steps"
}
elseif ($combinedErr -match "Termine 'grep' non riconosciuto|'grep' is not recognized") {
    $category = "missing_tool"
    $cause = "'grep' is a Unix utility and is not installed in the Windows PATH"
    $alternative = "rg"
    $remedy = "Use 'rg' (Ripgrep installed), 'Select-String', or Antigravity's grep_search tool"
}
elseif ($combinedErr -match "Termine 'gh' non riconosciuto|'gh' is not recognized") {
    $category = "missing_tool"
    $cause = "GitHub CLI ('gh') is not installed in the machine PATH"
    $alternative = "mcp_github"
    $remedy = "Use the GitHub MCP server or direct git commands"
}
elseif ($combinedErr -match "Termine '(bash|zsh|sh)' non riconosciuto|execvpe\(/bin/bash\) failed") {
    $category = "wrong_shell"
    $cause = "Unix shell requested but not available or configured on Windows"
    $remedy = "Convert the command to PowerShell syntax or a Node/Python script"
}
elseif ($combinedErr -match "Termine '([^']+)' non riconosciuto|The term '([^']+)' is not recognized|'([^']+)' is not recognized") {
    $category = "missing_tool"
    $missingToolName = if ($matches[1]) { $matches[1] } elseif ($matches[2]) { $matches[2] } else { $matches[3] }
    $cause = "Tool '$missingToolName' is not installed or not found in the Windows PATH"
    $remedy = "Verify tool installation, check PATH environment, or use an equivalent alternative"
}
elseif ($combinedErr -match "SyntaxError: (Invalid or unexpected token|Unexpected identifier)|ParserError:") {
    $category = "quoting_error"
    $cause = "Quotation escaping or multiline string is incompatible with PowerShell"
    $remedy = "Create a temporary script file (.cjs, .py, or .ps1) and execute it without inline quotes"
}
elseif ($combinedErr -match "Accesso negato|UnauthorizedAccessException") {
    $isNet = $false
    if ($WorkingDir -match '^\\\\') {
        $isNet = $true
    } elseif ($WorkingDir -match '^([A-Za-z]):') {
        $dl = $matches[1]
        $drv = Get-PSDrive -Name $dl -PSProvider FileSystem -ErrorAction SilentlyContinue
        if ($drv -and $drv.DisplayRoot) { $isNet = $true }
    }

    if ($isNet) {
        $category = "smb_error"
        $cause = "Permission restriction or filesystem limitation on SMB network share ($WorkingDir)"
        $remedy = "Use a local temporary folder (%TEMP%) for build/test operations"
    } else {
        $category = "permission_denied"
        $cause = "Write or execution permission denied at specified path"
        $remedy = "Check user permissions or request elevation if authorized"
    }
}
elseif ($combinedErr -match "Termine '.*' non riconosciuto|is not recognized as an internal or external command") {
    $category = "missing_tool"
    $cause = "The invoked command or executable is not present in PATH"
    $remedy = "Verify if the tool is installed outside PATH or use an alternative from the registry"
}
elseif ($combinedErr -match "ETIMEDOUT|Connection timed out|TimeoutException") {
    $category = "timeout"
    $cause = "Timeout occurred during network or I/O operation"
    $remedy = "Verify network connectivity or increase command timeout"
}

$result = [PSCustomObject]@{
    category = $category
    cause = $cause
    alternative = $alternative
    remedy = $remedy
    exitCode = $ExitCode
    redactedStderr = (Redact-Secrets -Text $Stderr)
    redactedStdout = (Redact-Secrets -Text $Stdout)
    timestamp = (Get-Date -Format "o")
}

Write-Output ($result | ConvertTo-Json -Depth 5)


