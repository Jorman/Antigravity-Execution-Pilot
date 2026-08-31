param(
    [string]$OutputDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\registry"
)

$capabilities = @(
    [PSCustomObject]@{
        capability = "recursive_text_search"
        description = "Search text or patterns recursively across files and directories"
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
                limitations = @("PowerShell syntax (-Path, -Pattern)")
                confidence = 0.95
            },
            [PSCustomObject]@{
                command = "grep_search"
                type = "antigravity_builtin_tool"
                status = "verified"
                equivalence = "full"
                limitations = @("Available only within agent context")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "grep"
                type = "unix_tool"
                status = "missing_replaced"
                equivalence = "not_available"
                limitations = @("Not installed; replaced by rg or Select-String")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "file_search_by_name"
        description = "Search files by name or glob pattern"
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
        description = "GitHub operations (issues, pull requests, reviews, commits)"
        primary = "mcp_github"
        alternatives = @(
            [PSCustomObject]@{
                command = "mcp_github"
                type = "mcp_server"
                status = "verified"
                equivalence = "full"
                limitations = @("Available via MCP github server")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "git"
                type = "native_executable"
                status = "verified"
                equivalence = "partial"
                limitations = @("Standard local/remote VCS operations only (commit, push, pull)")
                confidence = 0.9
            },
            [PSCustomObject]@{
                command = "gh"
                type = "cli_tool"
                status = "missing_replaced"
                equivalence = "not_available"
                limitations = @("Not installed; replaced by MCP github")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "node_script_execution"
        description = "Execution of complex or multiline Node.js scripts"
        primary = "temp_cjs_script"
        alternatives = @(
            [PSCustomObject]@{
                command = "temp_cjs_script"
                type = "pattern_rule"
                status = "verified"
                equivalence = "full"
                limitations = @("Requires creating temporary .cjs file and deleting post-execution")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "node -e"
                type = "inline_eval"
                status = "disallowed_windows"
                equivalence = "unreliable"
                limitations = @("Prohibited on PowerShell due to fragile quote escaping and SyntaxError")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "python_script_execution"
        description = "Execution of complex or multiline Python scripts"
        primary = "temp_py_script"
        alternatives = @(
            [PSCustomObject]@{
                command = "temp_py_script"
                type = "pattern_rule"
                status = "verified"
                equivalence = "full"
                limitations = @("Requires creating temporary .py file and deleting post-execution")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "python -c"
                type = "inline_eval"
                status = "disallowed_windows"
                equivalence = "unreliable"
                limitations = @("Prohibited on PowerShell due to fragile quote escaping")
                confidence = 0.0
            }
        )
        installationRequired = $false
        lastValidation = (Get-Date -Format "o")
    },
    [PSCustomObject]@{
        capability = "command_chaining"
        description = "Chaining successive commands"
        primary = "separate_execution_steps"
        alternatives = @(
            [PSCustomObject]@{
                command = "separate_execution_steps"
                type = "pattern_rule"
                status = "verified"
                equivalence = "full"
                limitations = @("Execute each command in separate steps verifying exit code")
                confidence = 1.0
            },
            [PSCustomObject]@{
                command = "&&"
                type = "bash_operator"
                status = "disallowed_windows_ps5"
                equivalence = "unsupported"
                limitations = @("Generates ParseError in PowerShell 5.1")
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


