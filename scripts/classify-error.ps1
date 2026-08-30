param(
    [string]$Command = "",
    [int]$ExitCode = 1,
    [string]$Stderr = "",
    [string]$Stdout = "",
    [string]$WorkingDir = "j:\Progetti\AG"
)

. "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\scripts\redact-secrets.ps1"

$combinedErr = "$Stderr `n $Stdout"
$category = "unknown_error"
$cause = "Errore non specificato o exit code non zero"
$remedy = ""
$alternative = ""

if ($combinedErr -match "(& era imprevisto|The token '&&' is not a valid statement separator)") {
    $category = "syntax_error"
    $cause = "Operatore '&&' non supportato come connettore logico in Windows PowerShell 5.1"
    $remedy = "Eseguire i comandi separatamente in step sequenziali distinti"
}
elseif ($combinedErr -match "Termine 'grep' non riconosciuto|'grep' is not recognized") {
    $category = "missing_tool"
    $cause = "Il comando 'grep' e' un tool Unix e non e' installato nel PATH Windows"
    $alternative = "rg"
    $remedy = "Utilizzare 'rg' (Ripgrep installato) oppure 'Select-String' o il tool Antigravity grep_search"
}
elseif ($combinedErr -match "Termine 'gh' non riconosciuto|'gh' is not recognized") {
    $category = "missing_tool"
    $cause = "GitHub CLI ('gh') non e' installato nel PATH della macchina"
    $alternative = "mcp_github"
    $remedy = "Utilizzare il server MCP github o comandi git diretti"
}
elseif ($combinedErr -match "Termine '(bash|zsh|sh)' non riconosciuto|execvpe\(/bin/bash\) failed") {
    $category = "wrong_shell"
    $cause = "Shell Unix richiesta ma non disponibile o non configurata su Windows"
    $remedy = "Convertire il comando in sintassi PowerShell o script Node/Python"
}
elseif ($combinedErr -match "SyntaxError: (Invalid or unexpected token|Unexpected identifier)|ParserError:") {
    $category = "quoting_error"
    $cause = "Escaping virgolette o stringa multiriga non compatibile con PowerShell"
    $remedy = "Creare un file script temporaneo (.cjs, .py o .ps1) ed eseguirlo senza virgolette inline"
}
elseif ($combinedErr -match "Accesso negato|UnauthorizedAccessException") {
    if ($WorkingDir -match "^[Jj]:") {
        $category = "smb_error"
        $cause = "Restrizione permessi o limitazione del filesystem sulla share di rete SMB J:\"
        $remedy = "Usare una cartella temporanea locale per build/test o verificare credenziali SMB"
    } else {
        $category = "permission_denied"
        $cause = "Permesso di scrittura o esecuzione negato nel percorso specificato"
        $remedy = "Verificare i permessi utente o richiedere elevazione se autorizzata"
    }
}
elseif ($combinedErr -match "Termine '.*' non riconosciuto|is not recognized as an internal or external command") {
    $category = "missing_tool"
    $cause = "Il comando o eseguibile invocato non e' presente nel PATH"
    $remedy = "Verificare se il tool e' installato fuori dal PATH o utilizzare un'alternativa presente nel registro"
}
elseif ($combinedErr -match "ETIMEDOUT|Connection timed out|TimeoutException") {
    $category = "timeout"
    $cause = "Timeout durante l'operazione di rete o I/O"
    $remedy = "Verificare connettivita o aumentare il timeout del comando"
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


