param(
  [Parameter(Mandatory = $true)]
  [string]$PluginPath
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mods = Join-Path $root "runtime\Server\mods"

if (-not (Test-Path $PluginPath)) {
  throw "Plugin not found: $PluginPath"
}

New-Item -ItemType Directory -Force -Path $mods | Out-Null
Copy-Item -Force $PluginPath $mods

Write-Host "OK: installed $(Split-Path $PluginPath -Leaf) into $mods"
