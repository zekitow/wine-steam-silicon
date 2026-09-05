#!/usr/bin/env bash
# Download Gcenx Wine Staging into vendor/ (Homebrew wine casks are Gatekeeper-disabled).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export WINE_SILICON_ROOT="$ROOT"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

WINE_VERSION="${WINE_VERSION:-11.16}"
ASSET="wine-staging-${WINE_VERSION}-osx64.tar.xz"
URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/${WINE_VERSION}/${ASSET}"
ARCHIVE="$ROOT/downloads/$ASSET"

require_rosetta

if [[ -x "$WINE_BIN/wine" ]]; then
  echo "Wine already present: $($WINE_BIN/wine --version)"
  exit 0
fi

mkdir -p "$ROOT/downloads" "$ROOT/vendor"
echo "Downloading $URL ..."
curl -L --fail --retry 3 -o "$ARCHIVE" "$URL"

echo "Extracting into vendor/ ..."
rm -rf "$ROOT/vendor/Wine Staging.app"
tar -xJf "$ARCHIVE" -C "$ROOT/vendor"
xattr -cr "$ROOT/vendor/Wine Staging.app" || true

echo "Installed: $($WINE_BIN/wine --version)"
echo "Initializing prefix at $WINEPREFIX ..."
WINEDEBUG=-all wineboot -u
echo "Done."
