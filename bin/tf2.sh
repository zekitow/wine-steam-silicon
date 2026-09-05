#!/usr/bin/env bash
# Launch Team Fortress 2 (Steam AppID 440) via the Wine Steam client.
# TF2 launch options are NOT appended here — set them in Steam:
#   Library → Team Fortress 2 → Properties → Launch Options
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

"$ROOT/bin/patch-steam-cef.sh"

# Optional extras only if you explicitly set them (normally leave unset).
# Example: TF2_OPTS="-vulkan" ./bin/tf2.sh
TF2_OPTS="${TF2_OPTS:-}"

LOG="$LOG_DIR/tf2-$(date +%Y%m%d-%H%M%S).log"
echo "Launching Team Fortress 2 (AppID 440) ..."
echo "Steam launch options: set in Steam Properties (this script does not append them)."
if [[ -n "$TF2_OPTS" ]]; then
  echo "Extra TF2_OPTS: $TF2_OPTS"
fi
echo "Log: $LOG"

exec wine "$STEAM_EXE" \
  -no-cef-sandbox \
  -noverifyfiles \
  -nobootstrapupdate \
  -norepairfiles \
  -forcedesktopscaling 1 \
  -applaunch 440 $TF2_OPTS "$@" >"$LOG" 2>&1
