#!/usr/bin/env bash
# Shared Wine + Steam environment for this repo.
# Source from other scripts:  source "$(dirname "$0")/env.sh"

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export WINE_SILICON_ROOT="$ROOT"

export WINE_APP="${WINE_APP:-$ROOT/vendor/Wine Staging.app}"
export WINE_BIN="$WINE_APP/Contents/Resources/wine/bin"
export PATH="$WINE_BIN:$PATH"
# winetricks looks for these explicitly
export WINE="$WINE_BIN/wine"
export WINESERVER="$WINE_BIN/wineserver"

# Dedicated bottle for Steam (64-bit prefix; 32-bit games run via WoW64).
export WINEPREFIX="${WINEPREFIX:-$ROOT/prefixes/steam}"
export WINEARCH="${WINEARCH:-win64}"

# Sensible defaults for Apple Silicon + games
export WINEESYNC="${WINEESYNC:-1}"
export WINEMSYNC="${WINEMSYNC:-1}"
export MTL_HUD_ENABLED="${MTL_HUD_ENABLED:-0}"
# Keep Wine chatty off by default; override with WINEDEBUG=+timestamp,+seh etc.
export WINEDEBUG="${WINEDEBUG:--all}"

export STEAM_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Steam/steam.exe"
export STEAM_SETUP="$ROOT/downloads/SteamSetup.exe"
export LOG_DIR="$ROOT/logs"

mkdir -p "$WINEPREFIX" "$LOG_DIR" "$ROOT/downloads"

require_wine() {
  if [[ ! -x "$WINE_BIN/wine" ]]; then
    echo "Wine not found at: $WINE_BIN/wine" >&2
    echo "Run: ./bin/bootstrap-wine.sh" >&2
    exit 1
  fi
}

require_rosetta() {
  if ! arch -x86_64 /usr/bin/true 2>/dev/null; then
    echo "Rosetta 2 is required (Wine build is x86_64)." >&2
    echo "Install with: softwareupdate --install-rosetta --agree-to-license" >&2
    exit 1
  fi
}
