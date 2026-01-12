#!/usr/bin/env bash
set -euo pipefail

# Copies Server/ and Assets.zip from the Hytale Launcher installation into ./runtime
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="${ROOT_DIR}/runtime"

# The official docs mention ~/Application Support/..., but on macOS it is commonly under ~/Library/Application Support/...
SRC_A="${HOME}/Application Support/Hytale/install/release/package/game/latest"
SRC_B="${HOME}/Library/Application Support/Hytale/install/release/package/game/latest"

SRC=""
if [ -d "${SRC_A}" ]; then SRC="${SRC_A}"; fi
if [ -z "${SRC}" ] && [ -d "${SRC_B}" ]; then SRC="${SRC_B}"; fi

if [ -z "${SRC}" ]; then
  echo "ERROR: Cannot find Hytale Launcher install directory."
  echo "Tried:"
  echo "  ${SRC_A}"
  echo "  ${SRC_B}"
  exit 1
fi

mkdir -p "${RUNTIME_DIR}"
rm -rf "${RUNTIME_DIR}/Server"
cp -R "${SRC}/Server" "${RUNTIME_DIR}/Server"
cp "${SRC}/Assets.zip" "${RUNTIME_DIR}/Assets.zip"

echo "OK: runtime prepared at ${RUNTIME_DIR}"
