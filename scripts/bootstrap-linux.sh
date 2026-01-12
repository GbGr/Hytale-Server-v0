#!/usr/bin/env bash
set -euo pipefail

# Downloads the latest Hytale package using the official downloader and prepares ./runtime
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${ROOT_DIR}/.tools"
RUNTIME_DIR="${ROOT_DIR}/runtime"
WORK_DIR="${TOOLS_DIR}/work"

mkdir -p "${TOOLS_DIR}" "${WORK_DIR}" "${RUNTIME_DIR}"
cd "${WORK_DIR}"

echo "Downloading official Hytale Downloader..."
curl -L "https://downloader.hytale.com/hytale-downloader.zip" -o "hytale-downloader.zip"
rm -rf "hytale-downloader"
unzip -o "hytale-downloader.zip" -d "hytale-downloader"

ARCH="$(uname -m)"
BIN="hytale-downloader-linux-amd64"
if [[ "${ARCH}" == "aarch64" || "${ARCH}" == "arm64" ]]; then
  BIN="hytale-downloader-linux-arm64"
fi

chmod +x "./hytale-downloader/${BIN}"

echo "Running downloader (first run will require browser auth)..."
./hytale-downloader/${BIN} -download-path "${WORK_DIR}/game.zip"

rm -rf "${WORK_DIR}/game"
mkdir -p "${WORK_DIR}/game"
unzip -o "${WORK_DIR}/game.zip" -d "${WORK_DIR}/game"

rm -rf "${RUNTIME_DIR}/Server"
cp -R "${WORK_DIR}/game/Server" "${RUNTIME_DIR}/Server"
cp "${WORK_DIR}/game/Assets.zip" "${RUNTIME_DIR}/Assets.zip"

echo "OK: runtime prepared at ${RUNTIME_DIR}"
