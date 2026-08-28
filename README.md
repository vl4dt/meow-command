# Meow Command

> Cute Missile Command clone: **dogs rain from the sky, cats in cannons defend
> Kitty City.** One-tap arcade defense — Godot 4.7.2, 100% procedural art and
> sound (zero image/audio assets).

## What it is

A fast, cozy arcade shooter. Dog missiles streak down at your cat houses and
turrets; you tap/click to fire star missiles from the nearest cat turret and
pop chains of explosions to clear the sky. Endless waves with rising speed and
swarm size, score + best-score persistence, wave-clear bonuses, and an instant
restart loop. The whole game is drawn in code (`_draw()`) and the SFX/music
are synthesized at startup — the project ships with no binary assets at all.

Core loop:

1. Wave starts — dog swarm spawns (4 + 2×wave, capped at 26).
2. Tap to fire; nearest live turret launches a star missile (0.32 s cooldown).
3. Missiles that touch dogs detonate; growing explosions chain-pop nearby dogs.
4. Sky cleared → wave bonus (100×wave + 25×alive buildings) → next wave, faster.
5. All buildings **or** all turrets destroyed → game over → tap to retry.

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
equivalent per Shipaton rules).

## Status

- ✅ Core gameplay complete (waves, firing, chain explosions, scoring,
  game over/restart) — verified by headless tests
- ✅ Headless verification gate green (`verify.ps1`)
- ⬜ Touch input tuning, mobile-safe portrait/landscape layout
- ⬜ RevenueCat SDK integration (IAP + optional Ads)
- ⬜ Exports: Android (AAB), iOS (via macOS), desktop builds
- ⬜ Store assets: 1024×1024 icon, 1179×2556 screenshot, ≤2 min demo video

## Run & verify

```
# Play (Windows)
C:\Apps\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe --path .

# Verification gate (MANDATORY after every edit batch; all steps must exit 0)
pwsh -File verify.ps1
```

The gate runs: `--import` → per-script `--check-only` → headless smoke test →
headless gameplay simulation (spawn/shoot/kill/wave/game-over/restart) → 300-frame
smoke run. It is sandbox-tolerant (redirects Godot user data into the project
and captures output via `cmd /c` file redirection) — see the header comment.

## Submission checklist

- [ ] Brand-new app, first release inside Aug 1 – Sep 30, 2026
- [ ] RevenueCat SDK powering ≥1 purchase (or RC Ads)
- [ ] Published on App Store / Google Play / Galaxy Store
- [ ] Demo video ≤2 min, public on YouTube/Vimeo
- [ ] App icon 1024×1024
- [ ] Screenshot 1179×2556, no device frame
- [ ] Devpost text description
- [ ] Free trial or promo code for judges

## Growth log

Dated entries — installs, revenue, experiments, learnings.

| Date | Event | Numbers | Learning |
|------|-------|---------|----------|
| 2026-08-28 | Core gameplay complete; headless gate green | 9 scripts, 2 test harnesses | Pipeline-first (procedural art) keeps asset cost at zero |
