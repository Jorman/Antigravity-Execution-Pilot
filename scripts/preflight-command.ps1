param(
    [string]$CommandLine = "",
    [string]$WorkingDir = "j:\Progetti\AG",
    [string]$Shell = "powershell.exe",
    [switch]$CheckAntiRepetition = $true
)

. "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"

if ([string]::IsNullOrWhiteSpace($CommandLine)) {
    $out = [PSCustomObject]@{
        originalCommand = ""
        action = "BLOCK"
        rewrittenCommand = ""
        category = "invalid_arguments"
        problems = @("Comando vuoto o nullo")
        needsApproval = $false
        confidence = 1.0
        motivation = "Non e' possibile eseguire comandi vuoti."
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
$motivation = "Comando verificato e sicuro."

# Anti-ripetizione
if ($CheckAntiRepetition) {
    $normCmd = $trimmed.ToLower()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normCmd)
    $hashBytes = $sha256.ComputeHash($bytes)
    $fingerprint = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })

    $errLog = "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\events\error-events.jsonl"
    if (Test-Path $errLog) {
        $recentErrors = Get-Content -Path $errLog -ErrorAction SilentlyContinue | ForEach-Object { $_ | ConvertFrom-Json }
        $match = $recentErrors | Where-Object { $_.commandFingerprint -eq $fingerprint -and $_.status -eq "observed" }
        if ($match) {
            $out = [PSCustomObject]@{
                originalCommand = (Redact-Secrets -Text $CommandLine)
                action = "BLOCK"
                rewrittenCommand = ""
                category = "repeated_failed_command"
                problems = @("Comando gia' fallito precedentemente con fingerprint: $fingerprint")
                needsApproval = $true
                confidence = 1.0
                motivation = "DIVIETO ASSOLUTO: non e' consentito ripetere identicamente un comando fallito nella stessa sessione senza prima applicare un rimedio."
            }
            Write-Output ($out | ConvertTo-Json -Depth 5)
            return
        }
    }
}

# Controllo comandi distruttivi
if ($trimmed -match "(?i)\b(rmdir\s+/s\s+/q\s+[c-z]:\\|format\s+[c-z]:|drop\s+database|del\s+/s\s+/q\s+[c-z]:\\windows)") {
    $action = "BLOCK"
    $category = "destructive_operation"
    $problems += "Comando potenzialmente distruttivo per il sistema"
    $needsApproval = $true
    $motivation = "Comando bloccato per prevenire perdita catastrofica di dati."
}
# Controllo &&
elseif ($trimmed -match "\s+&&\s+") {
    $action = "REWRITE"
    $category = "syntax_error"
    $problems += "Operatore '&&' non supportato in Windows PowerShell 5.1"
    $steps = $trimmed -split "\s+&&\s+"
    $rewritten = ($steps | ForEach-Object { $_.Trim() }) -join "`r`n# poi eseguire:`r`n"
    $motivation = "Separare i comandi concatenati con '&&' in step individuali separati."
}
# Controllo grep
elseif ($trimmed -match "(?i)^\s*grep(\.exe)?\b") {
    $action = "USE_ALTERNATIVE"
    $category = "missing_tool"
    $problems += "grep non e' installato nel PATH Windows"
    $rewritten = $trimmed -replace "(?i)^\s*grep(\.exe)?\b", "rg"
    $motivation = "Sostituire 'grep' con 'rg' (Ripgrep) o usare 'Select-String'."
}
# Controllo node -e complesso
elseif ($trimmed -match "(?i)^\s*node(\.exe)?\s+-e\s+\S") {
    $action = "REWRITE"
    $category = "quoting_error"
    $problems += "node -e con stringhe inline complesse genera SyntaxError su PowerShell"
    $rewritten = "Creare file temporaneo .cjs, eseguire 'node file.cjs' e rimuovere il file"
    $motivation = "Adottare il pattern obbligatorio file .cjs temporaneo."
}
# Controllo python -c complesso
elseif ($trimmed -match "(?i)^\s*python(\.exe)?\s+-c\s+\S") {
    $action = "REWRITE"
    $category = "quoting_error"
    $problems += "python -c con stringhe inline complesse genera SyntaxError su PowerShell"
    $rewritten = "Creare file temporaneo .py, eseguire 'python file.py' e rimuovere il file"
    $motivation = "Adottare il pattern obbligatorio file .py temporaneo."
}
# Controllo bash/zsh/sh
elseif ($trimmed -match "(?i)^\s*(bash|zsh|sh)(\.exe)?\s+(-c\s+)?") {
    $action = "BLOCK"
    $category = "wrong_shell"
    $problems += "Shell Unix non disponibile nativamente su Windows"
    $motivation = "Riscrivere il comando usando cmdlet PowerShell o script Node/Python."
}
# Controllo operazioni pesanti SMB
elseif ($WorkingDir -match "^[Jj]:" -and $trimmed -match "(?i)\b(npm\s+(run\s+(build|lint|test)|install|ci))\b") {
    $action = "BLOCK"
    $category = "smb_error"
    $problems += "Operazioni di build/lint/test/install non supportate sul drive di rete SMB J:\"
    $motivation = "Eseguire l'operazione in una directory locale temporanea (%TEMP%) e sincronizzare i file."
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



