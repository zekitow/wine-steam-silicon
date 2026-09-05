#!/usr/bin/env bash
# Kill wineserver / Steam processes for this prefix.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

require_wine
echo "Stopping wineserver for $WINEPREFIX ..."
wineserver -k || true
echo "Done."
