#!/usr/bin/env bash
# Stop Wine/Steam hard enough that ports and locks are freed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export WINE_SILICON_ROOT="$ROOT"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

echo "Stopping wineserver for $WINEPREFIX ..."
if [[ -x "$WINE_BIN/wineserver" ]]; then
  wineserver -k || true
  sleep 1
  wineserver -k9 || true
fi

# Belt-and-suspenders: kill by name (macOS)
pkill -f 'steamwebhelper|Steam.exe|steam\.exe|tf_win64|hl2\.exe' 2>/dev/null || true
pkill -f "$WINEPREFIX" 2>/dev/null || true

rm -f "$WINEPREFIX/.update-lock" 2>/dev/null || true

echo "Done. If the Mac still feels sluggish, close other apps or reboot once to clear swap."
