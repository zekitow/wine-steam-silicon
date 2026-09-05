#!/usr/bin/env bash
# Install Windows Steam into the local Wine prefix (silent if possible).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export WINE_SILICON_ROOT="$ROOT"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

require_rosetta
require_wine

if [[ -f "$STEAM_EXE" ]]; then
  echo "Steam already installed at:"
  echo "  $STEAM_EXE"
  echo "Launch with: ./bin/steam.sh"
  exit 0
fi

STEAM_URLS=(
  "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
  "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
)

if [[ ! -f "$STEAM_SETUP" ]]; then
  echo "Downloading SteamSetup.exe ..."
  ok=0
  for url in "${STEAM_URLS[@]}"; do
    if curl -L --fail --retry 3 -o "$STEAM_SETUP" "$url"; then
      ok=1
      break
    fi
  done
  if [[ "$ok" -ne 1 ]]; then
    echo "Failed to download Steam installer. Place SteamSetup.exe in downloads/" >&2
    exit 1
  fi
fi

echo "Ensuring Wine prefix exists ..."
WINEDEBUG=-all wineboot -u

# Common Steam deps (fonts help UI; vcrun helps some launchers).
if command -v winetricks >/dev/null 2>&1; then
  echo "Installing winetricks packages (corefonts, vcrun2022) ..."
  winetricks -q corefonts vcrun2022 || echo "winetricks step had issues; continuing."
else
  echo "Note: winetricks not installed (optional). brew install winetricks"
fi

LOG="$LOG_DIR/steam-install-$(date +%Y%m%d-%H%M%S).log"
echo "Installing Steam (log: $LOG) ..."
echo "A Wine window may appear briefly."

# /S = NSIS silent install
if wine "$STEAM_SETUP" /S >"$LOG" 2>&1; then
  :
else
  echo "Silent install failed or returned non-zero; trying interactive install..."
  wine "$STEAM_SETUP" 2>&1 | tee -a "$LOG"
fi

# Steam may still be downloading itself after setup.
for _ in $(seq 1 60); do
  if [[ -f "$STEAM_EXE" ]]; then
    break
  fi
  sleep 2
done

if [[ ! -f "$STEAM_EXE" ]]; then
  echo "Steam executable not found yet at:" >&2
  echo "  $STEAM_EXE" >&2
  echo "Open Steam once with ./bin/steam.sh after the installer finishes." >&2
  exit 1
fi

echo "Steam installed."
echo "Next: ./bin/steam.sh  (sign in, then install Team Fortress 2)"
