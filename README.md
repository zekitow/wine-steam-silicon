# Wine on Apple Silicon — Steam + Team Fortress 2

Run the **Windows** Steam client and **Team Fortress 2** on an Apple Silicon Mac using Wine (not CrossOver).

Tested on **M5 Pro**, macOS **26.6**, with [Gcenx Wine Staging](https://github.com/Gcenx/macOS_Wine_builds).

This guide assumes a **fresh machine**: no Wine, no Steam, no prior bottle. Follow the steps in order.

---

## What you need

| Requirement | Details |
|---|---|
| **Mac** | Apple Silicon only (M1 / M2 / M3 / M4 / M5 …). Intel Macs are out of scope. |
| **macOS** | Recent enough for current Gcenx Wine builds (Sonoma+ recommended; tested on 26.x). |
| **Disk space** | ~2 GB for Wine + Steam client, plus **~20–40 GB** for TF2. Prefer SSD free space. |
| **Network** | Needed to download Wine, Steam, TF2, and mastercomfig. |
| **Steam account** | TF2 is free; you still need to sign in. |
| **Patience** | First Steam update and TF2 download take a while. Expect playable-but-not-native FPS. |

You will install:

1. **Rosetta 2** (runs x86_64 Wine)
2. **Homebrew** (optional helpers: `winetricks`, and `mingw-w64` only if you rebuild the CEF shim)
3. **This repo’s scripts** (download Wine, create a bottle, install Steam, patch UI, optimize TF2)

---

## 0. One-time host setup (fresh Mac)

### 0.1 Command Line Tools (needed by Homebrew)

```bash
xcode-select --install
```

### 0.2 Homebrew

If `brew` is missing:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the “Next steps” it prints (add Homebrew to your `PATH` on Apple Silicon, usually `/opt/homebrew/bin`).

Confirm:

```bash
brew --version
```

### 0.3 Rosetta 2 (required)

```bash
softwareupdate --install-rosetta --agree-to-license
arch -x86_64 /usr/bin/true   # should succeed silently
```

### 0.4 Optional Homebrew packages

```bash
# Optional: fonts / VC++ helpers during Steam install
brew install winetricks

# Only if shims/steamwebhelper.exe is missing and you need to rebuild the CEF shim:
brew install mingw-w64
```

---

## 1. Get this repository

```bash
git clone <THIS_REPO_URL> wine-silicon
cd wine-silicon
chmod +x bin/*.sh
```

If you already have the folder, just `cd` into it.

Layout after setup (large dirs are gitignored and created by scripts):

```text
wine-silicon/
  bin/                  # all setup & launch scripts
  config/               # launch-option notes, optional cfg templates
  shims/                # prebuilt steamwebhelper CEF shim (+ source)
  vendor/               # Wine Staging.app (downloaded)
  prefixes/steam/       # Wine bottle / “Windows drive”
  downloads/            # Wine archives, SteamSetup, mastercomfig
  logs/                 # script logs
  README.md
```

---

## 2. Install Wine into `vendor/`

Homebrew’s `wine-stable` / `wine@staging` casks may be Gatekeeper-disabled. This project downloads a Gcenx `.app` instead:

```bash
cd /path/to/wine-silicon
./bin/bootstrap-wine.sh
```

This will:

- Download **Wine Staging** (default tag `11.16`; override with `WINE_VERSION=…`)
- Extract to `vendor/Wine Staging.app`
- Clear quarantine attributes
- Create an empty win64 prefix at `prefixes/steam`

Check:

```bash
./bin/bootstrap-wine.sh    # idempotent if already installed
# or:
"vendor/Wine Staging.app/Contents/Resources/wine/bin/wine" --version
```

---

## 3. Install Windows Steam into the bottle

```bash
./bin/install-steam.sh
```

This downloads `SteamSetup.exe` (if needed) and installs Steam under:

`prefixes/steam/drive_c/Program Files (x86)/Steam/`

---

## 4. First Steam launch (sign in)

```bash
./bin/steam.sh
```

What happens:

1. Script re-applies the **CEF black-screen shim** (`bin/patch-steam-cef.sh`) so Steam’s Chromium UI is usable on Apple Silicon.
2. Steam may **self-update for several minutes** (blank or busy UI is normal at first).
3. Sign in when the login window appears.

If you only see a **black square**, stop and relaunch:

```bash
./bin/stop.sh
./bin/steam.sh
```

Logs: `logs/steam-*.log` and  
`prefixes/steam/drive_c/Program Files (x86)/Steam/logs/`.

Leave Steam running once you are signed in.

---

## 5. Install Team Fortress 2

In the Wine Steam window:

1. **Library → Team Fortress 2** (AppID **440**) → **Install**
2. Wait for the download to finish (large)
3. Do **not** rely on the Mac/native Steam app — this is the **Windows** client inside Wine

---

## 6. Performance pack (run once after TF2 is installed)

```bash
./bin/stop.sh
./bin/optimize-tf2.sh
```

This configures:

- Wine **RetinaMode=n** (avoid 2× pixel load)
- Windows version hint **win10**
- [mastercomfig](https://mastercomfig.com/) **base** + **lowmem** + **flat-mouse**, modules preset **very_low**
- `tf/cfg/wine_silicon.cfg` (raw/flat mouse, uncapped FPS, vsync off)
- Ensures the broken **DXVK 3.1 game-folder drop-in is not** left enabled (it crashed here with “No adapters found”)

---

## 7. Set TF2 launch options in Steam (required)

`./bin/tf2.sh` only runs Steam with `-applaunch 440`. It does **not** append game launch options.

In Steam:

**Library → Team Fortress 2 → Properties → Launch Options**

Paste:

```text
-novid -nojoy -nosteamcontroller -nohltv -particles 1 -noforcemaccel -noforcemspd
```

Notes:

- Do **not** add `-threads` (Source auto-caps ~3; higher values don’t help and can break Wine).
- Fullscreen / resolution: set in **Options → Video** inside the game.
- Same text is saved in `config/tf2-launch-options.txt` for copy/paste.

Optional experiment later: add `-vulkan` (Valve’s built-in DXVK). If the game crashes, remove it.

---

## 8. Play

```bash
./bin/tf2.sh
```

Or press **Play** in Steam if Steam is already open via `./bin/steam.sh`.

Stop everything cleanly:

```bash
./bin/stop.sh
```

If the Mac feels sluggish after crashes, run `./bin/stop.sh` and reboot once to clear swap.

---

## Day-to-day cheat sheet

```bash
cd /path/to/wine-silicon

./bin/steam.sh          # Steam only (browse, update, set launch opts)
./bin/tf2.sh            # Start Steam + launch TF2 (AppID 440)
./bin/stop.sh           # Kill Wine/Steam for this bottle
./bin/optimize-tf2.sh   # Re-apply mastercomfig / Retina / mouse cfg
./bin/patch-steam-cef.sh # Re-apply black-UI shim if Steam updated CEF
```

---

## Scripts reference

| Script | Purpose |
|---|---|
| `bin/bootstrap-wine.sh` | Download Gcenx Wine Staging → `vendor/`, init prefix |
| `bin/install-steam.sh` | Download/install Windows Steam into `prefixes/steam` |
| `bin/steam.sh` | Launch Steam (applies CEF shim) |
| `bin/tf2.sh` | `-applaunch 440` (no TF2 launch opts appended) |
| `bin/optimize-tf2.sh` | mastercomfig very_low + Retina off + mouse cfg |
| `bin/patch-steam-cef.sh` | Install `steamwebhelper` shim (`--disable-gpu --single-process`) |
| `bin/stop.sh` | `wineserver -k` + kill leftover Steam/TF2 processes |
| `bin/env.sh` | Shared `WINEPREFIX` / PATH (sourced by other scripts) |

---

## Environment knobs (`bin/env.sh`)

| Variable | Default | Purpose |
|---|---|---|
| `WINEPREFIX` | `prefixes/steam` | Bottle path |
| `WINEESYNC` | `1` | Sync performance |
| `WINEMSYNC` | `1` | macOS sync helper when available |
| `WINEDEBUG` | `-all` | Quiet Wine logs |
| `WINEDLLOVERRIDES` | overlay DLLs disabled | Avoid Steam overlay hooks |
| `WINE_VERSION` | `11.16` | Gcenx tag for `bootstrap-wine.sh` |
| `TF2_OPTS` | empty | Rare one-off extras for `tf2.sh` only |

Example one-offs:

```bash
TF2_OPTS="-vulkan" ./bin/tf2.sh
WINEDEBUG=+seh ./bin/steam.sh
WINE_VERSION=11.16 ./bin/bootstrap-wine.sh
```

---

## Expectations (performance)

- This stack is **Gcenx Wine + WineD3D** (plus MoltenVK for some paths). It is **free** and DIY.
- Reports of “great” TF2 FPS on Mac usually used **Whisky / CrossOver Wine + DXVK Async**, not stock Gcenx WineD3D.
- Here, TF2 is often **playable but soft**, especially when looking around on **macOS 26** (hidden-cursor / frame sync quirk).
- Do **not** drop upstream DXVK `d3d9.dll` into the TF2 folder on this setup unless you know Vulkan adapters work — it previously crashed with `DXVK: No adapters found`.

If you need smoother gameplay: **CrossOver** trial, or **Silo / Highball** (GPTK / DXMT).

---

## Troubleshooting

### Black square instead of Steam login

CEF UI bug. Ensure you launch via `./bin/steam.sh` or `./bin/tf2.sh` (they call `patch-steam-cef.sh`).

```bash
./bin/stop.sh
./bin/patch-steam-cef.sh
./bin/steam.sh
```

Needs `shims/steamwebhelper.exe` (shipped) or `mingw-w64` to rebuild from `shims/steamwebhelper_shim.c`.

### `wine: Bad CPU type in executable`

Rosetta missing → section **0.3**.

### Steam stuck updating / blank window

Wait 5–15+ minutes on first run. Check `logs/steam-*.log`. Then:

```bash
./bin/stop.sh && ./bin/steam.sh
```

### TF2 won’t start / Mac very slow

Leftover processes or swap pressure:

```bash
./bin/stop.sh
# reboot if still slow
./bin/tf2.sh
```

### Look-around lag

Already mitigated in `wine_silicon.cfg` (raw mouse, `m_filter 0`, `fps_max 0`). Also turn off macOS mouse acceleration (**System Settings → Mouse**). Remaining hitching on macOS 26 may need a newer Wine build.

### Reset the bottle (destructive)

```bash
./bin/stop.sh
rm -rf prefixes/steam
./bin/bootstrap-wine.sh
./bin/install-steam.sh
./bin/steam.sh
# reinstall TF2, then:
./bin/optimize-tf2.sh
```

---

## Why not native Mac Steam / CrossOver?

| Approach | Notes |
|---|---|
| **This repo** | Free Gcenx Wine; more setup; TF2 often “OK / soft” |
| **CrossOver** | Paid; less DIY; often better game stacks |
| **Silo / Highball** | Free-ish launchers around Wine + GPTK/DXMT |
| **Native Mac TF2** | Unreliable / outdated client story for many players |

---

## References

- [Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds)
- [Wine HQ — macOS](https://wiki.winehq.org/MacOS)
- [mastercomfig](https://mastercomfig.com/) / [docs](https://docs.comfig.app/)
- [AppleGamingWiki — TF2](https://www.applegamingwiki.com/wiki/Team_Fortress_2)
- Steam AppID: **440**
