# Meow Command

> Cute Missile Command clone: **rats rain from the sky, cats in cannons defend
> Kitty City.** One-tap arcade defense — Godot 4.7.2, 100% procedural art and
> sound out of the box, with a drop-in pipeline for hand-crafted assets.

## What it is

A fast, cozy arcade shooter. Rats streak down from the sky at your cat houses
and turrets; you tap/click to fire star missiles from the nearest cat turret
and pop chains of explosions to clear the sky. Endless waves with rising speed
and swarm size, score + best-score persistence, wave-clear bonuses, and an
instant restart loop.

The whole game is drawn in code (`_draw()`) and the SFX/music are synthesized
at startup — the project ships with no required binary assets, but every
sprite and sound slot is a **drop-in replacement**: put a file at
`assets/sprites/<name>.png` (or `assets/audio/<name>.ogg`) and it takes over
(see `ART_SPECS.md` for the full per-asset contract).

### Features

- **Screens & flow** — title (Play / Daily / How To / Shop / sound toggle),
  pause menu (ESC), how-to panel, rich game-over (stats, NEW BEST celebration,
  copy score), instant restart.
- **Combat depth** — normal / weaving (wave 4+) / armored shells (wave 6+,
  2 HP) / splitting rats (wave 3+, burst into 2 pups) / ground-splitters
  (wave 8+) and a **Rat King boss every 5th wave** (5 HP, spawns 4 pups,
  100 pts). Turrets have 3 HP — landed rats damage the nearest building or
  turret. Game over when all buildings **or** all turrets fall.
- **Juice** — particle bursts, screen shake, hit-flash, slow-mo clutch moment
  on the last rat of a wave, combo milestone banners (×2/×3/×4/×5), confetti
  on new best, easter eggs (tap the sun, tap a turret).
- **Audio** — 6-voice SFX pool, 12 synthesized SFX, 3-tier adaptive music
  (calm → upbeat → intense), audio unlock on first gesture, sound toggle.
- **Economy & meta** — biscuit currency (rat drops + wave bonuses), 4
  power-ups (Double Shot / Wide Boom / Slow-Mo / City Shield) with HUD
  timers, 3 switchable themes (Classic / Sakura / Midnight), 4 cat skins
  (Classic / Mochi / Miso / Peppermint — drop-in art), 10 achievements with a
  trophy shelf, lifetime stats, seeded **daily challenge** with daily best.
- **Mobile hardening** — landscape lock, touch→mouse emulation, auto-pause on
  focus loss, haptics on fire/kill (Android), 1280×720 `canvas_items`+`expand`.
- **Persistence** — `user://meta.save` (plain JSON): best score, biscuit
  wallet, owned skins, theme/skin selection, achievements, lifetime stats,
  daily record.

Core loop:

1. Wave starts — rat swarm spawns (4 + 2×wave, capped).
2. Tap to fire; nearest live turret launches a star missile.
3. Missiles that touch rats detonate; growing explosions chain-pop nearby rats.
4. Chain kills within 2.5 s to stack the Combo multiplier (up to ×5 points).
5. Collect biscuits and power-ups; survive the Rat King every 5th wave.
6. Sky cleared → wave bonus → next wave, faster.
7. All buildings **or** all turrets destroyed → game over → stats → retry.

## Target award(s)

- **Best Game** (primary) — mobile-first arcade game: fun loop, distinct art
  direction, genre-fit monetization (cosmetic packs + optional ads).
- **Design** (stretch) — cohesive cute-cartoon craft, fully procedural
  art/SFX is a novel constraint story.
- **Catvertising** (stretch) — if we ship RevenueCat Ads between runs with a
  "remove ads" IAP.

## Platform & stack

- **Platforms:** Android (Google Play + Galaxy Store), iOS (App Store),
  desktop (Windows/macOS/Linux for local play & development).
- **Engine:** Godot **4.7.2 stable**, GDScript, **GL Compatibility** renderer
  (already the mobile target renderer), 1280×720 base with
  `canvas_items` stretch + `expand` aspect.
- **RevenueCat integration (planned, not yet built):** `purchases` SDK via
  GDExtension — one-time cosmetic packs + remove-ads entitlement; optional
  RevenueCat Ads interstitial on the game-over screen. See `PLAN.md` Phase 2.

## Monetization plan

Genre-fit for a casual arcade game (no subscription pressure):

| Product | Type | Price (target) | Notes |
|---|---|---|---|
| Free (default) | — | $0 | Full game, all waves, no features locked |
| Kitty Pack | One-time IAP | $2.99 | Cosmetic theme set #1 (e.g. Sakura City) |
| Extra packs | One-time IAP | $1.99–2.99 each | Additional themes |
| Remove Ads | One-time IAP | $0.99 | Disables interstitials |
| Interstitials | RevenueCat Ads | — | Only on game-over screen, frequency-capped; skippable |

Judges: **promo code unlocks all cosmetic packs + remove-ads** (free trial
equivalent per Shipaton rules). The in-game shop already sells themes/skins
with the biscuit currency — the RevenueCat packs map onto the same slots.

## Status

- ✅ Core gameplay complete (waves, firing, chain explosions, scoring,
  game over/restart) — verified by headless tests
- ✅ Depth: splitter/weave/shell/ground-splitter rats, Rat King boss, turret
  HP + landing damage, endless escalation
- ✅ Screens & flow: title / pause / how-to / shop / rich game-over
- ✅ Mobile hardening: landscape lock, touch, focus-pause, haptics
- ✅ Audio: 12 SFX, 3-tier music, unlock-on-gesture, sound toggle
- ✅ Juice: particles, shake, hit-flash, slow-mo clutch, easter eggs
- ✅ Economy: biscuits, 4 power-ups, 3 themes, 4 skins, 10 achievements,
  daily challenge — all persisted
- ✅ Asset pipeline: drop-in loader wired everywhere + 1024 icon +
  1280×720 gameplay frame captured
- ✅ Headless verification gate green (`verify.ps1`)
- ✅ Android export: debug + release APKs (arm64-v8a, `com.vl4dt.meowcommand`)
  — verified on-device on an LG V60 ThinQ (Android 10): launch, rendering,
  touch input, no crashes
- ⬜ Hand-crafted art pass (specs in `ART_SPECS.md` — drop-in ready)
- ⬜ RevenueCat SDK integration (IAP + optional Ads)
- ⬜ Store submission artifacts: AAB + release keystore (Play), iOS (via macOS),
  desktop builds
- ⬜ Store extras: 1179×2556 portrait screenshot, ≤2 min demo video

## Run & verify

```
# Play (Windows)
C:\Apps\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe --path .

# Verification gate (MANDATORY after every edit batch; all steps must exit 0)
pwsh -File verify.ps1

# Store assets
godot --headless --path . -s res://tools/gen_icon.gd        # -> assets/store/icon.png
godot --path . -s res://tools/frame_capture.gd              # -> assets/store/frame_capture.png (windowed)
```

The gate runs: `--import` → per-script `--check-only` → headless smoke test →
headless gameplay simulation (title start, spawn/shoot/kill, shell 2-hit,
turret landing damage, wave break, game over, restart) → 300-frame smoke run.
It is sandbox-tolerant (redirects Godot user data into the project and
captures output via `cmd /c` file redirection) — see the header comment.

## Android export

Requirements (all present on the dev machine):

- Godot **4.7.2 stable** export templates
  (`%APPDATA%\Godot\export_templates\4.7.2.stable\` — `android_debug.apk`,
  `android_release.apk`, `android_source.zip`)
- Android SDK (`ANDROID_HOME`) and JDK 17+ (`JAVA_HOME`)
- `export_presets.cfg` — preset **"Android"**: package
  `com.vl4dt.meowcommand`, arm64-v8a only, `VIBRATE` permission (haptics),
  Godot's default debug keystore (`%APPDATA%\Godot\keystores\debug.keystore`,
  alias `androiddebugkey`, password `android`)
- Project setting `textures/vram_compression/import_etc2_astc=true`
  (mandatory — Godot refuses Android export without ETC2/ASTC)

```
# Debug APK (device testing)
godot --headless --path . --export-debug "Android" builds/meow-command-android-debug.apk

# Release APK (re-sign with a real release keystore before Play submission)
godot --headless --path . --export-release "Android" builds/meow-command-android-release.apk

# Install + launch on a connected phone (adb)
adb install -r -t builds/meow-command-android-debug.apk
adb shell monkey -p com.vl4dt.meowcommand 1
adb shell screencap -p /sdcard/_shot.png
adb pull /sdcard/_shot.png
```

**Verified 2026-09-04 on an LG V60 ThinQ** (LM-V600, Android 10, arm64-v8a):
launches cleanly, renders title screen + live gameplay (Wave 1), touch input
works (tap → fire), no crashes in logcat. ~27 MB APK. Note: Play Store
submission needs an AAB + a proper release keystore (see Phase 3 / bi8.5).

## Art pipeline (drop-in)

All art is currently procedural; every slot accepts a hand-crafted file with
no code changes:

- `assets/sprites/<name>.png` — cat skins, rats, buildings, FX, background…
- `assets/audio/<name>.ogg` — any of the 15 SFX/music slots
- `assets/store/` — generated icon (1024×1024) + gameplay frame (1280×720)

Full per-asset contract (sizes, anchors, palettes, do/don't): **`ART_SPECS.md`**.

## Submission checklist

- [ ] Brand-new app, first release inside Aug 1 – Sep 30, 2026
- [ ] RevenueCat SDK powering ≥1 purchase (or RC Ads)
- [ ] Published on App Store / Google Play / Galaxy Store
- [ ] Demo video ≤2 min, public on YouTube/Vimeo
- [ ] App icon 1024×1024 — ✅ `assets/store/icon.png`
- [ ] Screenshot 1179×2556, no device frame (portrait crop from
      `assets/store/frame_capture.png` or a dedicated capture)
- [ ] Devpost text description
- [ ] Free trial or promo code for judges

## Growth log

Dated entries — installs, revenue, experiments, learnings.

| Date | Event | Numbers | Learning |
|------|-------|---------|----------|
| 2026-08-28 | Core gameplay complete; headless gate green | 9 scripts, 2 test harnesses | Pipeline-first (procedural art) keeps asset cost at zero |
| 2026-08-28 | Splitting Rats + rolling Combo multiplier (×5 cap); dog→rat rebrand | +2 depth mechanics | Depth without new assets; rebrand keeps tone (cats = heroes, rats = baddies) |
| 2026-09-04 | Analysis + art-spec docs delivered (`ANALYSIS.md`, `ART_SPECS.md`) | 2 docs | Gap analysis found 13 improvement areas; art contract makes the hand-crafted pass a pure drop-in |
| 2026-09-04 | Batch 1: screens, mobile, audio, juice, combat depth, rich game-over (bi8.7–bi8.11, bi8.13) | +9 scripts, ~2350 lines | Full meta layer (Meta/Assets) first — every later feature hangs off it |
| 2026-09-04 | Batch 2: themes, skins, shop, 10 achievements (bi8.12) | +1 screen, palette→theme system | Static-var palette makes retheming a one-call runtime swap |
| 2026-09-04 | Batch 3: 1024 icon + 1280×720 frame capture (bi8.14) | 2 store assets | Icon generator is pure Image math — reproducible, zero dependencies |
| 2026-09-04 | Android export + on-device verification (bi8.5.1) | 27 MB debug + release APKs | Godot 4.7.2 templates ship `android_source.zip` (no gradle step at export); ETC2/ASTC project setting is mandatory for Android export; debug keystore auto-reuse works |
