param(
    [string]$OutputDir = "C:\Users\jorma\.gemini\config\antigravity-execution-pilot\registry"
)

$ErrorActionPreference = "SilentlyContinue"

# 1. Machine Info
$os = Get-CimInstance Win32_OperatingSystem
$arch = $env:PROCESSOR_ARCHITECTURE
$compName = $env:COMPUTERNAME
$user = $env:USERNAME
$psVersion = $PSVersionTable.PSVersion.ToString()
$tz = (Get-TimeZone).Id

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# 2. Paths
$homePath = $env:USERPROFILE
$tempPath = $env:TEMP
$workspaceRoots = @("j:\Progetti\AG")
$networkRoots = @()

# 3. Filesystems
$fsList = @()
$drives = Get-PSDrive -PSProvider FileSystem
foreach ($d in $drives) {
    $driveType = "Local"
    $uncPath = $null
    if ($d.DisplayRoot) {
        $driveType = "Network/SMB"
        $uncPath = $d.DisplayRoot
        $networkRoots += $d.Root
    }

    $freeGb = if ($d.Free) { [math]::Round($d.Free / 1GB, 2) } else { $null }
    $usedGb = if ($d.Used) { [math]::Round($d.Used / 1GB, 2) } else { $null }

    $fsList += [PSCustomObject]@{
        name = $d.Name
        root = $d.Root
        type = $driveType
        uncPath = $uncPath
        freeGb = $freeGb
        usedGb = $usedGb
    }
}

# 4. PATH Environment
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne "" }

# 5. Permissions Tests
$permTests = [PSCustomObject]@{
    isAdmin = $isAdmin
    canWriteTemp = $false
    canWriteWorkspace = $false
    canDeleteInWorkspace = $false
}

$testTempFile = Join-Path $tempPath "cg_perm_test_$([Guid]::NewGuid().ToString('N')).tmp"
try {
    Set-Content -Path $testTempFile -Value "test" -Encoding UTF8
    if (Test-Path $testTempFile) {
        $permTests.canWriteTemp = $true
        Remove-Item -Path $testTempFile -Force
    }
} catch {}

$testWsFile = Join-Path "j:\Progetti\AG" "cg_perm_test_$([Guid]::NewGuid().ToString('N')).tmp"
try {
    Set-Content -Path $testWsFile -Value "test" -Encoding UTF8
    if (Test-Path $testWsFile) {
        $permTests.canWriteWorkspace = $true
        Remove-Item -Path $testWsFile -Force
        $permTests.canDeleteInWorkspace = $true
    }
} catch {}

# 6. Antigravity configuration summary
$geminiDir = "C:\Users\jorma\.gemini"
$configDir = "C:\Users\jorma\.gemini\config"
$pluginsDir = "C:\Users\jorma\.gemini\config\plugins"
$skillsDir = "C:\Users\jorma\.gemini\config\skills"

$installedPlugins = if (Test-Path $pluginsDir) { (Get-ChildItem -Path $pluginsDir -Directory).Name } else { @() }
$installedSkills = if (Test-Path $skillsDir) { (Get-ChildItem -Path $skillsDir -Directory).Name } else { @() }

$antigravityInfo = [PSCustomObject]@{
    environment = "Antigravity 2.0"
    appDataDirectory = "C:\Users\jorma\.gemini\antigravity"
    configDirectory = $configDir
    globalRules = (Test-Path "$geminiDir\GEMINI.md")
    globalSkillsCount = $installedSkills.Count
    globalPluginsCount = $installedPlugins.Count
    installedPlugins = $installedPlugins
    installedSkills = $installedSkills
}

# 7. Environment Registry Object
$registry = [PSCustomObject]@{
    schemaVersion = 1
    lastScan = (Get-Date -Format "o")
    scanConfidence = 1.0
    machine = [PSCustomObject]@{
        os = $os.Caption
        osVersion = $os.Version
        architecture = $arch
        computerName = $compName
        user = $user
        defaultShell = "powershell.exe"
        shellVersion = $psVersion
        timezone = $tz
        isAdmin = $isAdmin
    }
    paths = [PSCustomObject]@{
        home = $homePath
        temp = $tempPath
        workspaceRoots = $workspaceRoots
        networkRoots = $networkRoots
        pathEntriesCount = $pathEntries.Count
        pathEntries = $pathEntries
    }
    filesystems = $fsList
    permissions = $permTests
    antigravity = $antigravityInfo
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$outputPath = Join-Path $OutputDir "environment-registry.json"
$registry | ConvertTo-Json -Depth 6 | Set-Content -Path $outputPath -Encoding UTF8

Write-Output $outputPath

