#!/usr/bin/env bash
# Launch Windows Steam inside the local Wine bottle.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export WINE_SILICON_ROOT="$ROOT"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

require_rosetta
require_wine

if [[ ! -f "$STEAM_EXE" ]]; then
  echo "Steam not installed. Run: ./bin/install-steam.sh" >&2
  exit 1
fi

# Ensure the CEF black-screen shim is still in place (Steam updates can wipe it).
"$ROOT/bin/patch-steam-cef.sh"

LOG="$LOG_DIR/steam-$(date +%Y%m%d-%H%M%S).log"
echo "Starting Steam ..."
echo "Prefix: $WINEPREFIX"
echo "Log:    $LOG"
echo
echo "If you previously saw a black square: that was Steam's Chromium UI failing."
echo "This launch uses a steamwebhelper shim (--disable-gpu --single-process)."
echo "Sign in, install TF2, then use ./bin/tf2.sh (or Play in Steam)."
echo

# -no-cef-sandbox: CEF under Wine
# -noverifyfiles / -nobootstrapupdate: keep our steamwebhelper shim
# -forcedesktopscaling 1: avoid HiDPI blurriness / odd window sizes
exec wine "$STEAM_EXE" \
  -no-cef-sandbox \
  -noverifyfiles \
  -nobootstrapupdate \
  -norepairfiles \
  -forcedesktopscaling 1 \
  "$@" >"$LOG" 2>&1
