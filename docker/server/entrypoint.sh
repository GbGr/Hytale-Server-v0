#!/usr/bin/env bash
set -euo pipefail

HYTALE_DIR="${HYTALE_DIR:-/srv/hytale}"
cd "$HYTALE_DIR"

JAR="${HYTALE_JAR:-HytaleServer.jar}"
ASSETS="${HYTALE_ASSETS:-$HYTALE_DIR/Assets.zip}"
BIND="${HYTALE_BIND:-0.0.0.0:5520}"

if [[ ! -f "$JAR" ]]; then
  echo "ERROR: $HYTALE_DIR/$JAR not found."
  echo "Place your server files into ./runtime/server so the container sees them at $HYTALE_DIR."
  exit 1
fi

if [[ ! -f "$ASSETS" ]]; then
  echo "ERROR: Assets.zip not found at: $ASSETS"
  echo "Place Assets.zip into ./runtime/server/Assets.zip"
  exit 1
fi

ARGS=(--assets "$ASSETS" --bind "$BIND")

# Disable Sentry during active plugin development (recommended in official manual)
if [[ "${HYTALE_DISABLE_SENTRY:-true}" == "true" ]]; then
  ARGS+=(--disable-sentry)
fi

# Early plugins warning can be auto-accepted if you use them
if [[ "${HYTALE_ACCEPT_EARLY_PLUGINS:-false}" == "true" ]]; then
  ARGS+=(--accept-early-plugins)
fi

# Extra args passthrough
if [[ -n "${HYTALE_EXTRA_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA=( ${HYTALE_EXTRA_ARGS} )
  ARGS+=("${EXTRA[@]}")
fi

echo "Starting HytaleServer..."
echo "  JAR:    $JAR"
echo "  Assets: $ASSETS"
echo "  Bind:   $BIND"
echo "  Java:   ${JAVA_OPTS:-<none>}"
echo "  Args:   ${ARGS[*]}"

# AOT cache is optional; server ships with HytaleServer.aot for faster boots
# We'll use it automatically if present.
if [[ -f "HytaleServer.aot" ]]; then
  exec java ${JAVA_OPTS:-} -XX:AOTCache=HytaleServer.aot -jar "$JAR" "${ARGS[@]}"
else
  exec java ${JAVA_OPTS:-} -jar "$JAR" "${ARGS[@]}"
fi
