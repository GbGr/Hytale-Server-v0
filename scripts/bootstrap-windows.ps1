param(
  [ValidateSet("Launcher","Downloader")]
  [string]$Mode = "Launcher"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$runtime = Join-Path $root "runtime"
New-Item -ItemType Directory -Force -Path $runtime | Out-Null

if ($Mode -eq "Launcher") {
  $src = Join-Path $env:APPDATA "Hytale\install\release\package\game\latest"
  if (-not (Test-Path $src)) {
    throw "Cannot find Launcher install dir: $src"
  }

  $serverDst = Join-Path $runtime "Server"
  if (Test-Path $serverDst) { Remove-Item -Recurse -Force $serverDst }
  Copy-Item -Recurse -Force (Join-Path $src "Server") $serverDst
  Copy-Item -Force (Join-Path $src "Assets.zip") (Join-Path $runtime "Assets.zip")

  Write-Host "OK: runtime prepared at $runtime"
  exit 0
}

# Downloader mode (Windows)
$tools = Join-Path $root ".tools"
$work  = Join-Path $tools "work"
New-Item -ItemType Directory -Force -Path $work | Out-Null

$zipPath = Join-Path $work "hytale-downloader.zip"
Invoke-WebRequest "https://downloader.hytale.com/hytale-downloader.zip" -OutFile $zipPath

$dlDir = Join-Path $work "hytale-downloader"
if (Test-Path $dlDir) { Remove-Item -Recurse -Force $dlDir }
Expand-Archive $zipPath -DestinationPath $dlDir -Force

$exe = Join-Path $dlDir "hytale-downloader-windows-amd64.exe"
if (-not (Test-Path $exe)) {
  throw "Downloader exe not found: $exe"
}

$gameZip = Join-Path $work "game.zip"
& $exe -download-path $gameZip

$gameDir = Join-Path $work "game"
if (Test-Path $gameDir) { Remove-Item -Recurse -Force $gameDir }
Expand-Archive $gameZip -DestinationPath $gameDir -Force

$serverSrc = Join-Path $gameDir "Server"
$assetsSrc = Join-Path $gameDir "Assets.zip"
if (-not (Test-Path $serverSrc)) { throw "Server folder not found in package." }
if (-not (Test-Path $assetsSrc)) { throw "Assets.zip not found in package." }

$serverDst = Join-Path $runtime "Server"
if (Test-Path $serverDst) { Remove-Item -Recurse -Force $serverDst }
Copy-Item -Recurse -Force $serverSrc $serverDst
Copy-Item -Force $assetsSrc (Join-Path $runtime "Assets.zip")

Write-Host "OK: runtime prepared at $runtime"
