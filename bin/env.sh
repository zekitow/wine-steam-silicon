#!/usr/bin/env bash
# Shared Wine + Steam environment for this repo.
# Callers should: export WINE_SILICON_ROOT="$(cd ... && pwd)" before sourcing.

set -euo pipefail

if [[ -z "${WINE_SILICON_ROOT:-}" ]]; then
  _env_src="${BASH_SOURCE[0]-}"
  if [[ -z "$_env_src" || "$_env_src" == "env.sh" ]]; then
    _env_src="$0"
  fi
  _ENV_DIR="$(cd "$(dirname "$_env_src")" && pwd)"
  export WINE_SILICON_ROOT="$(cd "$_ENV_DIR/.." && pwd)"
fi
ROOT="$WINE_SILICON_ROOT"

# Always derive Wine paths from ROOT unless an existing override is valid.
_default_wine_app="$ROOT/vendor/Wine Staging.app"
if [[ -z "${WINE_APP:-}" || ! -x "${WINE_APP}/Contents/Resources/wine/bin/wine" ]]; then
  export WINE_APP="$_default_wine_app"
fi
export WINE_BIN="$WINE_APP/Contents/Resources/wine/bin"
case ":$PATH:" in
  *":$WINE_BIN:"*) ;;
  *) export PATH="$WINE_BIN:$PATH" ;;
esac
export WINE="$WINE_BIN/wine"
export WINESERVER="$WINE_BIN/wineserver"

export WINEPREFIX="${WINEPREFIX:-$ROOT/prefixes/steam}"
export WINEARCH="${WINEARCH:-win64}"

export WINEESYNC="${WINEESYNC:-1}"
export WINEMSYNC="${WINEMSYNC:-1}"
export MTL_HUD_ENABLED="${MTL_HUD_ENABLED:-0}"
export WINEDEBUG="${WINEDEBUG:--all}"

# MoltenVK tweaks (used by Wine's Vulkan path; keep mild)
export MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS="${MVK_CONFIG_SYNCHRONOUS_QUEUE_SUBMITS:-0}"
export MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS="${MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS:-1}"

# Disable Steam overlay only. Do NOT force native d3d9 by default —
# DXVK 3.1 currently crashes here with "No adapters found" on this Wine/MoltenVK.
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-GameOverlayRenderer64.dll=d;GameOverlayRenderer.dll=d}"

export STEAM_EXE="$WINEPREFIX/drive_c/Program Files (x86)/Steam/steam.exe"
export STEAM_SETUP="$ROOT/downloads/SteamSetup.exe"
export TF2_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Steam/steamapps/common/Team Fortress 2"
export LOG_DIR="$ROOT/logs"

mkdir -p "$WINEPREFIX" "$LOG_DIR" "$ROOT/downloads"

require_wine() {
  if [[ ! -x "$WINE_BIN/wine" ]]; then
    echo "Wine not found at: $WINE_BIN/wine" >&2
    echo "ROOT=$ROOT WINE_APP=$WINE_APP" >&2
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
