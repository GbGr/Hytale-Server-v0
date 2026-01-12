$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
docker compose -f infra/compose.yml --env-file infra/env.dev --profile dev up
