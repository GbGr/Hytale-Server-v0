# Hytale Plugin Watch Mode for Windows
# Usage: .\scripts\watch.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Set-Location $ProjectRoot

Write-Host "======================================" -ForegroundColor Blue
Write-Host "  Hytale Plugin Watch Mode            " -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Watching for changes in src\..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

# Find compatible Java
$javaVersion = & java -version 2>&1 | Select-Object -First 1
if ($javaVersion -match '"(\d+)') {
    $majorVersion = [int]$Matches[1]
    if ($majorVersion -ge 25) {
        $searchPaths = @("$env:ProgramFiles\Eclipse Adoptium", "$env:ProgramFiles\Java")
        foreach ($version in @(24, 23, 22, 21)) {
            foreach ($basePath in $searchPaths) {
                if (Test-Path $basePath) {
                    $javaDir = Get-ChildItem -Path $basePath -Directory -Filter "*$version*" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($javaDir -and (Test-Path "$($javaDir.FullName)\bin\java.exe")) {
                        $env:JAVA_HOME = $javaDir.FullName
                        break
                    }
                }
            }
            if ($env:JAVA_HOME) { break }
        }
    }
}

function Invoke-Deploy {
    Write-Host ""
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Change detected, deploying..." -ForegroundColor Green
    & .\gradlew.bat deploy --quiet 2>&1 | Where-Object { $_ -notmatch "^WARNING:" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Done" -ForegroundColor Green
}

# Use FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "$ProjectRoot\src"
$watcher.IncludeSubdirectories = $true
$watcher.Filter = "*.*"
$watcher.EnableRaisingEvents = $true

# Debounce timer
$script:lastChange = [DateTime]::MinValue
$script:debounceMs = 1000

$action = {
    $now = [DateTime]::Now
    if (($now - $script:lastChange).TotalMilliseconds -gt $script:debounceMs) {
        $script:lastChange = $now
        Invoke-Deploy
    }
}

Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
Register-ObjectEvent $watcher "Created" -Action $action | Out-Null
Register-ObjectEvent $watcher "Deleted" -Action $action | Out-Null
Register-ObjectEvent $watcher "Renamed" -Action $action | Out-Null

Write-Host "Watching... (Press Ctrl+C to stop)" -ForegroundColor Yellow

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    $watcher.Dispose()
    Get-EventSubscriber | Unregister-Event
}
