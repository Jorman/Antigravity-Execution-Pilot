param(
    [string]$OutputDir = "$env:USERPROFILE\.gemini\config\plugins\antigravity-execution-pilot\registry"
)

$toolsToScan = @(
    @{ name = "git"; testCmd = "git --version"; versionCmd = "git --version"; caps = @("version_control"); shells = @("powershell", "cmd") },
    @{ name = "node"; testCmd = "node --version"; versionCmd = "node --version"; caps = @("javascript_runtime"); shells = @("powershell", "cmd") },
    @{ name = "npm"; testCmd = "npm --version"; versionCmd = "npm --version"; caps = @("package_manager_js"); shells = @("powershell", "cmd") },
    @{ name = "python"; testCmd = "python --version"; versionCmd = "python --version"; caps = @("python_runtime"); shells = @("powershell", "cmd") },
    @{ name = "rg"; testCmd = "rg --version"; versionCmd = "rg --version"; caps = @("recursive_text_search"); shells = @("powershell", "cmd") },
    @{ name = "ffmpeg"; testCmd = "ffmpeg -version"; versionCmd = "ffmpeg -version"; caps = @("media_processing"); shells = @("powershell", "cmd") },
    @{ name = "docker"; testCmd = "docker --version"; versionCmd = "docker --version"; caps = @("containerization"); shells = @("powershell", "cmd") },
    @{ name = "winget"; testCmd = "winget --version"; versionCmd = "winget --version"; caps = @("package_manager_windows"); shells = @("powershell", "cmd") },
    @{ name = "choco"; testCmd = "choco --version"; versionCmd = "choco --version"; caps = @("package_manager_chocolatey"); shells = @("powershell", "cmd") },
    @{ name = "curl"; testCmd = "curl.exe --version"; versionCmd = "curl.exe --version"; caps = @("http_request"); shells = @("powershell", "cmd") },
    @{ name = "tar"; testCmd = "tar.exe --version"; versionCmd = "tar.exe --version"; caps = @("file_archive"); shells = @("powershell", "cmd") },
    @{ name = "grep"; testCmd = "grep --version"; versionCmd = "grep --version"; caps = @("recursive_text_search"); shells = @("bash", "sh") },
    @{ name = "bash"; testCmd = "bash --version"; versionCmd = "bash --version"; caps = @("unix_shell"); shells = @("bash") },
    @{ name = "zsh"; testCmd = "zsh --version"; versionCmd = "zsh --version"; caps = @("unix_shell"); shells = @("zsh") },
    @{ name = "sh"; testCmd = "sh --version"; versionCmd = "sh --version"; caps = @("unix_shell"); shells = @("sh") },
    @{ name = "gh"; testCmd = "gh --version"; versionCmd = "gh --version"; caps = @("github_cli"); shells = @("powershell", "cmd") }
)

$toolResults = @()

foreach ($t in $toolsToScan) {
    $cmdName = $t.name
    $cmdInfo = Get-Command $cmdName -ErrorAction SilentlyContinue
    $resolvedPath = if ($cmdInfo) { $cmdInfo.Source } else { "" }
    $status = "unknown"
    $versionOutput = ""
    $confidence = 0.0

    if ($cmdInfo) {
        try {
            $procOut = Invoke-Expression $t.testCmd 2>$null
            if ($LASTEXITCODE -eq 0 -or $procOut) {
                $status = "available_verified"
                $versionOutput = ($procOut | Out-String).Trim().Split("`n")[0].Trim()
                $confidence = 1.0
            } else {
                $status = "broken"
                $confidence = 0.5
            }
        } catch {
            $status = "broken"
            $confidence = 0.4
        }
    } else {
        # Check if installed in common non-PATH locations
        $nonPathLocations = @(
            "C:\Program Files\$cmdName\$cmdName.exe",
            "C:\Program Files (x86)\$cmdName\$cmdName.exe",
            "$env:LOCALAPPDATA\Programs\$cmdName\$cmdName.exe"
        )
        $foundNonPath = $null
        foreach ($np in $nonPathLocations) {
            if (Test-Path $np) { $foundNonPath = $np; break }
        }

        if ($foundNonPath) {
            $status = "installed_not_in_path"
            $resolvedPath = $foundNonPath
            $confidence = 0.8
        } else {
            $status = "missing"
            $confidence = 1.0
        }
    }

    $toolResults += [PSCustomObject]@{
        name = $t.name
        aliases = @()
        status = $status
        detectedCommand = if ($status -eq "available_verified") { $t.name } else { "" }
        resolvedPath = $resolvedPath
        version = $versionOutput
        versionCommand = $t.versionCmd
        shells = $t.shells
        platforms = @("windows")
        capabilities = $t.caps
        limitations = @()
        requiresPrivilege = ($status -eq "requires_privilege")
        requiresNetwork = ($t.name -in @("npm", "docker", "winget", "choco", "gh"))
        installable = ($status -eq "missing")
        autoInstallAllowed = $false
        packageManagers = @("winget", "choco")
        lastChecked = (Get-Date -Format "o")
        lastSuccessfulTest = if ($status -eq "available_verified") { (Get-Date -Format "o") } else { "" }
        confidence = $confidence
    }
}

$registry = [PSCustomObject]@{
    schemaVersion = 1
    lastScan = (Get-Date -Format "o")
    tools = $toolResults
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$outPath = Join-Path $OutputDir "tool-registry.json"
$registry | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8
Write-Output $outPath


