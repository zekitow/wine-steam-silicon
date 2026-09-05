#!/usr/bin/env bash
# Launch Team Fortress 2 (Steam AppID 440) via the Wine Steam client.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

require_rosetta
require_wine

if [[ ! -f "$STEAM_EXE" ]]; then
  echo "Steam not installed. Run: ./bin/install-steam.sh" >&2
  exit 1
fi

"$ROOT/bin/patch-steam-cef.sh"

# TF2 launch options that often help under Wine on Apple Silicon:
#   -dxlevel 90 / -dxlevel 81  force older DX paths if DX9 fails
#   -novid                    skip intro videos
#   -windowed -w 1920 -h 1080 for easier alt-tab / first-run debugging
TF2_OPTS="${TF2_OPTS:--novid}"

LOG="$LOG_DIR/tf2-$(date +%Y%m%d-%H%M%S).log"
echo "Launching Team Fortress 2 (AppID 440) ..."
echo "Extra opts: $TF2_OPTS $*"
echo "Log: $LOG"
echo
echo "Note: TF2 must already be installed in this Steam bottle."
echo "If you only see a black Steam splash, sign in first with ./bin/steam.sh"

exec wine "$STEAM_EXE" \
  -no-cef-sandbox \
  -noverifyfiles \
  -nobootstrapupdate \
  -norepairfiles \
  -forcedesktopscaling 1 \
  -applaunch 440 $TF2_OPTS "$@" >"$LOG" 2>&1
