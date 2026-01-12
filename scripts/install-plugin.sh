#!/usr/bin/env bash
set -euo pipefail

# Installs a plugin/mod artifact into runtime/Server/mods/
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_MODS="${ROOT_DIR}/runtime/Server/mods"

PLUGIN_PATH="${1:-}"
if [ -z "${PLUGIN_PATH}" ] || [ ! -f "${PLUGIN_PATH}" ]; then
  echo "Usage: $0 path/to/plugin.jar"
  exit 1
fi

mkdir -p "${RUNTIME_MODS}"
cp -f "${PLUGIN_PATH}" "${RUNTIME_MODS}/"

echo "OK: installed $(basename "${PLUGIN_PATH}") into ${RUNTIME_MODS}"
