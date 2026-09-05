#!/usr/bin/env bash
# Install / refresh the steamwebhelper shim that fixes Steam's black UI on
# Apple Silicon Wine (CEF cross-process GPU present fails → black square).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

CEF_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Steam/bin/cef/cef.win64"
SHIM_SRC="$ROOT/shims/steamwebhelper.exe"
SHIM_C="$ROOT/shims/steamwebhelper_shim.c"
REAL="$CEF_DIR/steamwebhelper_real.exe"
HELPER="$CEF_DIR/steamwebhelper.exe"
CFG="$WINEPREFIX/drive_c/Program Files (x86)/Steam/Steam.cfg"

if [[ ! -d "$CEF_DIR" ]]; then
  echo "Steam CEF not found yet (finish Steam's first update, then re-run)." >&2
  exit 0
fi

if [[ ! -f "$SHIM_SRC" ]]; then
  if [[ ! -f "$SHIM_C" ]]; then
    echo "Missing $SHIM_C" >&2
    exit 1
  fi
  if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    echo "Need mingw-w64 to build shim: brew install mingw-w64" >&2
    exit 1
  fi
  echo "Building steamwebhelper shim ..."
  x86_64-w64-mingw32-gcc -O2 -mwindows -o "$SHIM_SRC" "$SHIM_C"
fi

mkdir -p "$CEF_DIR"
chflags nouchg "$HELPER" 2>/dev/null || true

# If current helper is still Valve's multi-MB binary, back it up as real.
if [[ -f "$HELPER" ]]; then
  size=$(stat -f%z "$HELPER" 2>/dev/null || echo 0)
  if [[ "$size" -gt 1000000 ]]; then
    echo "Backing up Valve steamwebhelper → steamwebhelper_real.exe"
    cp "$HELPER" "$REAL"
  fi
fi

if [[ ! -f "$REAL" ]]; then
  echo "No steamwebhelper_real.exe — run Steam once so CEF downloads, then re-run." >&2
  exit 1
fi

cp "$SHIM_SRC" "$HELPER"
chflags uchg "$HELPER"

# Discourage Steam from replacing CEF / bootstrap files.
printf '%s\n' 'BootStrapperInhibitAll=Enable' 'BootStrapperForceSelfUpdate=Disable' > "$CFG"

echo "CEF shim installed at:"
echo "  $HELPER"
echo "Real helper:"
echo "  $REAL"
echo "Override flags (optional): export AETHER_CEF_FLAGS='--disable-gpu --single-process'"
