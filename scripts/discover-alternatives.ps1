param(
    [string]$OutputDir = "C:\Users\jorma\.gemini\config\plugins\antigravity-execution-pilot\registry"
)

$capabilities = @(
    [PSCustomObject]@{
        capability = "recursive_text_search"
        description = "Ricerca di testo o pattern all'interno di file e directory ricorsivamente"
        primary = "rg"
        alternatives = @(
            [PSCustomObject]@{
                command = "rg"
                type = "native_executable"
                status = "verified"
                equivalence = "full"
                limitations = @()
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "Select-String"
                type = "powershell_cmdlet"
                status = "verified"
                equivalence = "full"
                limitations = @("Sintassi PowerShell (-Path, -Pattern)")
                confidence = 0.95
            },
            [PSCustomObject]@{
                command = "grep_search"
                type = "antigravity_builtin_tool"
                status = "verified"
                equivalence = "full"
                limitations = @("Disponibile solo all'interno dell'agente")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "grep"
                type = "unix_tool"
                status = "missing_replaced"
                equivalence = "not_available"
                limitations = @("Non installato; sostituito da rg o Select-String")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "file_search_by_name"
        description = "Ricerca di file per nome o glob pattern"
        primary = "find_by_name"
        alternatives = @(
            [PSCustomObject]@{
                command = "find_by_name"
                type = "antigravity_builtin_tool"
                status = "verified"
                equivalence = "full"
                limitations = @()
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "Get-ChildItem -Recurse -Filter"
                type = "powershell_cmdlet"
                status = "verified"
                equivalence = "full"
                limitations = @()
                confidence = 0.95
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "github_operations"
        description = "Operazioni GitHub (issue, pull request, reviews, commits)"
        primary = "mcp_github"
        alternatives = @(
            [PSCustomObject]@{
                command = "mcp_github"
                type = "mcp_server"
                status = "verified"
                equivalence = "full"
                limitations = @("Disponibile tramite MCP server github")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "git"
                type = "native_executable"
                status = "verified"
                equivalence = "partial"
                limitations = @("Solo operazioni VCS locali/remote standard (commit, push, pull)")
                confidence = 0.9
            },
            [PSCustomObject]@{
                command = "gh"
                type = "cli_tool"
                status = "missing_replaced"
                equivalence = "not_available"
                limitations = @("Non installato; sostituito da MCP github")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "node_script_execution"
        description = "Esecuzione di script Node.js complessi o multiriga"
        primary = "temp_cjs_script"
        alternatives = @(
            [PSCustomObject]@{
                command = "temp_cjs_script"
                type = "pattern_rule"
                status = "verified"
                equivalence = "full"
                limitations = @("Richiede creazione file .cjs temporaneo ed eliminazione post-esecuzione")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "node -e"
                type = "inline_eval"
                status = "disallowed_windows"
                equivalence = "unreliable"
                limitations = @("Vietato su PowerShell per quote escaping fragile e SyntaxError")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "python_script_execution"
        description = "Esecuzione di script Python complessi o multiriga"
        primary = "temp_py_script"
        alternatives = @(
            [PSCustomObject]@{
                command = "temp_py_script"
                type = "pattern_rule"
                status = "verified"
                equivalence = "full"
                limitations = @("Richiede creazione file .py temporaneo ed eliminazione post-esecuzione")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "python -c"
                type = "inline_eval"
                status = "disallowed_windows"
                equivalence = "unreliable"
                limitations = @("Vietato per quote escaping fragile")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "command_chaining"
        description = "Concatenazione di comandi successivi"
        primary = "separate_execution_steps"
        alternatives = @(
            [PSCustomObject]@{
                command = "separate_execution_steps"
                type = "pattern_rule"
                status = "verified"
                equivalence = "full"
                limitations = @("Eseguire ogni comando in step separati verificando l'exit code")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "&&"
                type = "bash_operator"
                status = "disallowed_windows_ps5"
                equivalence = "unsupported"
                limitations = @("Genera ParseError in PowerShell 5.1")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    }
)

$registry = [PSCustomObject]@{
    schemaVersion = 1
    lastScan = (Get-Date -Format "o")
    capabilities = $capabilities
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$outPath = Join-Path $OutputDir "alternative-registry.json"
$registry | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8
Write-Output $outPath


