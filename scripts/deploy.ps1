# Hytale Plugin Deploy Script for Windows
# Usage: .\scripts\deploy.ps1

$ErrorActionPreference = "Stop"

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Set-Location $ProjectRoot

Write-Host "======================================" -ForegroundColor Blue
Write-Host "  Hytale Plugin Deploy                " -ForegroundColor Blue
Write-Host "======================================" -ForegroundColor Blue
Write-Host ""

# Check if project is initialized
if (-not (Test-Path "$ProjectRoot\build.gradle.kts")) {
    Write-Host "Error: Project not initialized." -ForegroundColor Red
    Write-Host "Run .\scripts\init.ps1 first."
    exit 1
}

# Find compatible Java (Gradle 8.14 has issues with Java 25)
function Find-CompatibleJava {
    $searchPaths = @(
        "$env:ProgramFiles\Eclipse Adoptium",
        "$env:ProgramFiles\Java",
        "$env:ProgramFiles\Temurin",
        "${env:ProgramFiles(x86)}\Eclipse Adoptium",
        "${env:ProgramFiles(x86)}\Java"
    )
    foreach ($version in @(24, 23, 22, 21)) {
        foreach ($basePath in $searchPaths) {
            if (Test-Path $basePath) {
                $javaDir = Get-ChildItem -Path $basePath -Directory -Filter "*$version*" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($javaDir -and (Test-Path "$($javaDir.FullName)\bin\java.exe")) {
                    return $javaDir.FullName
                }
            }
        }
    }
    return $null
}

# Check current Java version
$javaVersion = & java -version 2>&1 | Select-Object -First 1
if ($javaVersion -match '"(\d+)') {
    $majorVersion = [int]$Matches[1]
    if ($majorVersion -ge 25) {
        $compatibleJava = Find-CompatibleJava
        if ($compatibleJava) {
            Write-Host "Note: Using Java 24 for Gradle (Java 25 has compatibility issues)" -ForegroundColor Yellow
            $env:JAVA_HOME = $compatibleJava
        }
    }
}

# Step 1: Build the plugin
Write-Host "[1/3] Building plugin..." -ForegroundColor Green
& .\gradlew.bat build --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed." -ForegroundColor Red
    exit 1
}

# Find the built JAR
$JarFile = Get-ChildItem -Path "$ProjectRoot\build\libs" -Filter "*.jar" | Select-Object -First 1

if (-not $JarFile) {
    Write-Host "Error: No JAR file found in build\libs\" -ForegroundColor Red
    exit 1
}

$JarName = $JarFile.Name
Write-Host "      Built: $JarName" -ForegroundColor Yellow

# Step 2: Copy to mods folder
Write-Host "[2/3] Copying to mods folder..." -ForegroundColor Green
$ModsDir = "$ProjectRoot\runtime\Server\mods"

if (-not (Test-Path $ModsDir)) {
    New-Item -ItemType Directory -Force -Path $ModsDir | Out-Null
}

# Remove old versions of this plugin
$PluginBaseName = $JarName -replace '-\d.*\.jar$', ''
Get-ChildItem -Path $ModsDir -Filter "$PluginBaseName*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force

Copy-Item -Path $JarFile.FullName -Destination $ModsDir -Force
Write-Host "      Copied to: runtime\Server\mods\$JarName" -ForegroundColor Yellow

# Step 3: Reload plugin on server
Write-Host "[3/3] Checking server status..." -ForegroundColor Green

# Read plugin identifier from manifest.json
$ManifestFile = "$ProjectRoot\src\main\resources\manifest.json"
if (Test-Path $ManifestFile) {
    $Manifest = Get-Content $ManifestFile | ConvertFrom-Json
    $PluginId = "$($Manifest.Group):$($Manifest.Name)"
} else {
    $PluginId = "<Group:Name>"
}

$ContainerName = $null
$Profile = $null

# Try to find running container
try {
    $DevContainer = docker compose -f "$ProjectRoot\infra\compose.yml" --profile dev ps --quiet hytale-dev 2>$null
    if ($DevContainer) {
        $ContainerName = "hytale-dev"
        $Profile = "dev"
    }
} catch {}

if (-not $ContainerName) {
    try {
        $ProdContainer = docker compose -f "$ProjectRoot\infra\compose.yml" --profile prod ps --quiet hytale-prod 2>$null
        if ($ProdContainer) {
            $ContainerName = "hytale-prod"
            $Profile = "prod"
        }
    } catch {}
}

if ($ContainerName) {
    Write-Host "      Found running server: $ContainerName" -ForegroundColor Yellow
    Write-Host ""

    $ReloadCmd = "/plugin reload $PluginId"

    Write-Host "Reloading plugin..." -ForegroundColor Green

    # Try to send reload command using PowerShell job with stdin
    try {
        $job = Start-Job -ScriptBlock {
            param($ProjectRoot, $Profile, $ContainerName, $ReloadCmd)
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "docker"
            $psi.Arguments = "compose -f `"$ProjectRoot\infra\compose.yml`" --profile $Profile attach $ContainerName"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true

            $process = [System.Diagnostics.Process]::Start($psi)
            Start-Sleep -Milliseconds 500
            $process.StandardInput.WriteLine($ReloadCmd)
            Start-Sleep -Milliseconds 500
            # Send Ctrl+P Ctrl+Q to detach
            $process.StandardInput.Write([char]16)  # Ctrl+P
            $process.StandardInput.Write([char]17)  # Ctrl+Q
            $process.StandardInput.Close()
            Start-Sleep -Milliseconds 500
            if (-not $process.HasExited) {
                $process.Kill()
            }
        } -ArgumentList $ProjectRoot, $Profile, $ContainerName, $ReloadCmd

        # Wait for job with timeout
        $completed = Wait-Job $job -Timeout 10
        Remove-Job $job -Force -ErrorAction SilentlyContinue

        Write-Host "      Sent: $ReloadCmd" -ForegroundColor Green
        Write-Host ""
        Write-Host "Plugin reload initiated. Check server logs for status." -ForegroundColor Yellow
    } catch {
        # Fallback to manual instructions
        Write-Host "Could not send command automatically." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Run in server console:" -ForegroundColor Blue
        Write-Host "  $ReloadCmd" -ForegroundColor Green
        Write-Host ""
        Write-Host "Attach: docker compose -f infra\compose.yml --profile $Profile attach $ContainerName" -ForegroundColor Blue
    }
} else {
    Write-Host "      Server not running." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Start server:" -ForegroundColor Blue
    Write-Host "  docker compose -f infra\compose.yml --env-file infra\env.dev --profile dev up"
    Write-Host ""
    Write-Host "Then reload plugin with:" -ForegroundColor Blue
    Write-Host "  /plugin reload $PluginId" -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  Deploy complete!                    " -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
