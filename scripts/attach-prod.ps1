$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
docker compose -f infra/compose.yml --profile prod attach hytale-prod
