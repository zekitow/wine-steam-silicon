# Wine on Apple Silicon (M5) — Steam + Team Fortress 2

Local notes for running the **Windows** Steam client under Wine on an Apple Silicon Mac (tested on **MacBook / M5 Pro**, macOS 26.6), with the goal of installing and playing **Team Fortress 2**.

This is **not** CrossOver. Same idea (Wine compatibility layer), but DIY: free, more tinkering, no commercial support.

## Why Wine (not native Mac Steam / CrossOver)

| Approach | Notes |
|---|---|
| **Native Mac Steam + TF2** | Valve’s Mac client/game support has been uneven for years; many players use the Windows build via Wine/CrossOver instead. |
| **This repo (Wine)** | Free. Uses [Gcenx macOS Wine builds](https://github.com/Gcenx/macOS_Wine_builds) (Homebrew `wine-*` casks were Gatekeeper-disabled as of 2026-09). |
| **CrossOver** | Paid Wine product from CodeWeavers; easier installers and game recipes. Prefer if you want less DIY. |

On Apple Silicon, Wine is an **x86_64** binary translated by **Rosetta 2**. Windows games are then translated again by Wine. Expect overhead vs native.

## Hardware / OS notes (this machine)

- Chip: Apple Silicon (M5 family)
- Rosetta 2: **required** (already installed here)
- Wine build in use: **Wine Staging 11.16** (Gcenx `.app` bundle under `vendor/`)
- Prefix (bottle): `prefixes/steam` — **win64** (32-bit Windows games/components run via Wine’s WoW64)

TF2 is an older Source engine title (primarily **DirectX 9**). Start with Wine’s built-in **WineD3D**; you usually do **not** need Apple’s Game Porting Toolkit / D3DMetal for TF2 (those target DX10/11/12).

## Quick start

```bash
# 1) Wine into vendor/ + create prefixes/steam
./bin/bootstrap-wine.sh

# 2) Optional but recommended UI/runtime deps
brew install winetricks
# (install-steam.sh will use winetricks if present)

# 3) Install Windows Steam into the bottle
./bin/install-steam.sh

# 4) Sign in to Steam (GUI)
./bin/steam.sh

# 5) In Steam: Library → Team Fortress 2 → Install (Windows build)

# 6) Play from Steam, or:
./bin/tf2.sh

# Stop Wine/Steam cleanly
./bin/stop.sh
```

Logs land in `logs/`.

## Layout

```
wine-silicon/
  bin/
    env.sh              # shared WINEPREFIX / PATH
    bootstrap-wine.sh   # download Gcenx Wine Staging
    install-steam.sh    # SteamSetup.exe → bottle
    steam.sh            # launch Steam
    tf2.sh              # steam -applaunch 440
    stop.sh             # wineserver -k
  vendor/               # Wine Staging.app (gitignored)
  prefixes/steam/       # WINEPREFIX bottle (gitignored)
  downloads/            # SteamSetup.exe, Wine archives (gitignored)
  logs/                 # launch/install logs (gitignored)
  README.md             # this file
```

## Environment knobs

Defaults live in `bin/env.sh`:

| Variable | Default | Purpose |
|---|---|---|
| `WINEPREFIX` | `prefixes/steam` | Isolated Windows “drive” |
| `WINEESYNC` | `1` | Eventfd sync (perf) |
| `WINEMSYNC` | `1` | macOS sync helper when available |
| `MTL_HUD_ENABLED` | `0` | Metal HUD off |
| `WINEDEBUG` | `-all` | Quiet logs; set e.g. `+seh` when debugging |
| `TF2_OPTS` | `-novid` | Extra TF2 launch options for `tf2.sh` |

Examples:

```bash
# Force older DX path if rendering breaks
TF2_OPTS="-novid -dxlevel 90" ./bin/tf2.sh

# Windowed first run (easier if the game locks input)
TF2_OPTS="-novid -windowed -w 1280 -h 720" ./bin/tf2.sh

# Verbose Wine log for one session
WINEDEBUG=+timestamp,+seh ./bin/steam.sh
```

## TF2-specific tips

1. **Install size** — TF2 is large; leave tens of GB free under `prefixes/steam/drive_c/`.
2. **First launch** — Steam may update itself for a long time before the library appears. Watch `logs/steam-*.log` if the window is blank.
3. **Graphics** — If the menu is black or the game crashes on load, try `-dxlevel 90` or `-dxlevel 81`, then windowed mode (above).
4. **VAC / multiplayer** — Wine + Steam often works for TF2, but Valve can change anti-cheat behavior anytime. Offline/bots are the safer test first.
5. **Controllers** — Prefer Steam Input; macOS ↔ Wine controller mapping can be flaky.
6. **32-bit bottles** — Do **not** create a pure win32 prefix for new setups. Use the win64 bottle here; Steam and most 32-bit game bits run through WoW64.

## Troubleshooting

### Black square / blank Steam splash (not TF2 yet)

**Symptom:** centered black rectangle; no login UI. Often mistaken for a game crash.

**Cause:** Steam’s Chromium UI (`steamwebhelper`) draws in a separate GPU process. On Apple Silicon Wine, that cross-process present path fails (GLES 3.0 / DXGI errors in `cef_log.txt`) → black window. Login never finishes, and TF2 never starts.

**Fix (already applied in this repo):** `./bin/patch-steam-cef.sh` replaces `steamwebhelper.exe` with a small shim that relaunches the real helper with `--disable-gpu --single-process`. Launch only via `./bin/steam.sh` (or `./bin/tf2.sh`), which re-applies the patch and passes `-noverifyfiles`.

```bash
./bin/stop.sh
./bin/steam.sh
```

You should get a usable login window (software-rendered UI is a bit sluggish; games are separate processes and unaffected).

Also: **TF2 is not installed in this bottle until you sign in and install it.** `tf2.sh` only starts Steam with `-applaunch 440`; without a library install it will just reopen Steam.

### `wine: Bad CPU type in executable`
Rosetta missing:

```bash
softwareupdate --install-rosetta --agree-to-license
```

### Steam window blank / stuck updating
- Wait through the first self-update (can take many minutes).
- Relaunch: `./bin/stop.sh && ./bin/steam.sh`
- Optional Steam flags already passed: `-no-cef-sandbox` (Chromium UI under Wine).

### `wine-stable` / `wine@staging` Homebrew casks disabled
As of Sep 2026 Homebrew disabled them for Gatekeeper. This repo vendors Gcenx builds instead (`bootstrap-wine.sh`).

### Reset the bottle (destructive)
```bash
./bin/stop.sh
rm -rf prefixes/steam
./bin/bootstrap-wine.sh
./bin/install-steam.sh
```

### Upgrade Wine later
```bash
WINE_VERSION=11.16 ./bin/bootstrap-wine.sh   # or newer tag from Gcenx releases
```
Keep the same `WINEPREFIX` when possible; back up `prefixes/steam` before major Wine jumps.

## What we configured on this Mac (session notes)

- [x] Confirmed arch `arm64`, macOS 26.6.x, GPU reported as **Apple M5 Pro**
- [x] Installed Rosetta 2
- [x] Downloaded **Wine Staging 11.16** (Gcenx) → `vendor/Wine Staging.app`
- [x] Cleared quarantine (`xattr -cr`) so Gatekeeper doesn’t block Wine
- [x] Created win64 prefix `prefixes/steam` (`wineboot`)
- [x] Wine reports Metal / MoltenVK against the M5 Pro
- [x] Installed `winetricks` via Homebrew (optional deps; first run may warn — `WINE`/`WINESERVER` are set in `bin/env.sh`)
- [x] Downloaded `SteamSetup.exe` and installed Steam into `prefixes/steam`
- [x] Verified `steam.exe` starts and begins its first client update (~240 MB)
- [x] Diagnosed black splash: CEF GPU/GLES failure (not TF2); login never completed; TF2 not installed yet
- [x] Installed `steamwebhelper` shim (`shims/`, `bin/patch-steam-cef.sh`) with `--disable-gpu --single-process`
- [ ] Sign in via `./bin/steam.sh`, install TF2 (AppID 440), then play with `./bin/tf2.sh`

**First Steam launch:** the Windows client self-updates before the library UI is useful. Watch `logs/steam-*.log`. If you only see a **black square**, that is the CEF UI bug — use `./bin/steam.sh` after the shim patch, and do not chase TF2 launch options until login works.

## Alternatives if this path fights you

- **CrossOver** — least friction for Steam gaming on Mac.
- **Silo / Highball / Sikarugir** — GUI wrappers around Wine + DXMT/GPTK (better for newer DX11/12 titles than for TF2).
- **Parallels / VMware** — full Windows VM; higher overhead, better compatibility for some anti-cheat titles.

## References

- [Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds)
- [Wine HQ — macOS](https://wiki.winehq.org/MacOS)
- [AppleGamingWiki — Game Porting Toolkit](https://www.applegamingwiki.com/wiki/Game_Porting_Toolkit) (mostly DX11/12; optional later)
- Steam AppID for TF2: **440**
