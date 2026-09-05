#!/usr/bin/env bash
# Install mastercomfig (very_low) + safe Wine tweaks for TF2.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export WINE_SILICON_ROOT="$ROOT"
# shellcheck source=env.sh
source "$ROOT/bin/env.sh"

require_wine

TF2="${TF2_DIR}"
VER="${MASTERCOMFIG_VER:-9.100.1}"
BASE_URL="https://github.com/mastercomfig/mastercomfig/releases/download/${VER}"

if [[ ! -d "$TF2" ]]; then
  echo "TF2 not found at: $TF2" >&2
  exit 1
fi

echo "==> RetinaMode=n"
wine reg add 'HKCU\Software\Wine\Mac Driver' /v RetinaMode /t REG_SZ /d n /f >/dev/null
wine reg add 'HKCU\Software\Wine' /v Version /t REG_SZ /d win10 /f >/dev/null

# Keep DXVK drop-in disabled (crashes on this Wine build)
if [[ -f "$TF2/d3d9.dll" ]]; then
  mkdir -p "$ROOT/backups"
  mv -f "$TF2/d3d9.dll" "$ROOT/backups/d3d9.dll.bak"
  echo "==> Removed game-dir d3d9.dll (known crash)"
fi
rm -f "$TF2/dxvk.conf"

echo "==> mastercomfig ${VER} (base + lowmem + very_low modules)"
mkdir -p "$ROOT/downloads" "$TF2/tf/custom" "$TF2/tf/cfg/overrides"
for f in mastercomfig-base.vpk mastercomfig-addon-lowmem.vpk autoexec.cfg; do
  out="$ROOT/downloads/$f"
  [[ "$f" == autoexec.cfg ]] && out="$ROOT/downloads/mastercomfig-autoexec.cfg"
  url="$BASE_URL/$f"
  if [[ ! -f "$out" ]]; then
    curl -L --fail --retry 3 -o "$out" "$url"
  fi
done
cp -f "$ROOT/downloads/mastercomfig-base.vpk" "$TF2/tf/custom/"
cp -f "$ROOT/downloads/mastercomfig-addon-lowmem.vpk" "$TF2/tf/custom/"
cp -f "$ROOT/downloads/mastercomfig-autoexec.cfg" "$TF2/tf/cfg/autoexec.cfg"

cat >"$TF2/tf/cfg/overrides/modules.cfg" <<'EOF'
preset=very_low
texture_quality=very_low
shadows=off
effects=very_low
water=low
models=low
particles=very_low
ragdolls=off
gibs=off
props=low
ropes=off
ao=off
pyrovision=off
motion_blur=off
anti_aliasing=off
texture_filtering=bilinear
characters=low
misc=very_low
sound=low
hud_player_model=off
EOF

cat >"$TF2/tf/cfg/wine_silicon.cfg" <<'EOF'
fps_max 60
mat_vsync 0
mat_queue_mode 2
cl_showfps 1
echo "[wine-silicon] very_low + fps_max 60"
EOF
grep -q 'wine_silicon' "$TF2/tf/cfg/autoexec.cfg" || printf '\nexec wine_silicon\n' >>"$TF2/tf/cfg/autoexec.cfg"

cat >"$ROOT/config/tf2-launch-options.txt" <<'EOF'
# Put these in Steam → TF2 → Properties → Launch Options
# (./bin/tf2.sh does not append launch options.)
-novid -nojoy -nosteamcontroller -nohltv -particles 1 -noforcemaccel -noforcemspd
# Do not use -threads. Set resolution/fullscreen in-game Video options.
EOF

echo
echo "Done."
echo "Launch:  ./bin/tf2.sh"
echo "Set Steam Launch Options from: $ROOT/config/tf2-launch-options.txt"
echo
echo "Honest note: AppleGamingWiki 'perfect' TF2 reports used Whisky/CrossOver Wine + DXVK Async."
echo "Stock Gcenx Wine + WineD3D often stays barely playable. If still bad after this,"
echo "CrossOver trial or Silo is the realistic next step — not more cfg tweaks."
