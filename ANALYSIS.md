# Meow Command — Game Analysis & Improvement Opportunities

_Date: 2026-09-04 · Scope: full as-is code review (9 scripts, tests, project config) +
improvement roadmap for engagement, entertainment, and value._

## 1. As-is snapshot

**What exists and works well**

- Core Missile Command loop is complete and verified headlessly: waves, rat
  spawning, turret fire (0.32 s cooldown), chain explosions, scoring, best-score
  persistence, game over, restart (`tools/gameplay_test.gd` passes).
- Two depth mechanics already ship: **Splitting Rats** (wave 3+, 12% chance,
  max 3/wave) and a **rolling Combo multiplier** (2.5 s window, +0.25/kill, ×5 cap).
- The **zero-asset pipeline** is a genuine differentiator: all art is `_draw()`,
  all audio is synthesized at startup (`sfx.gd`). Retheming is a data swap —
  this is the foundation for the planned cosmetic-pack IAP.
- Clean architecture: `game.gd` controller + small entity scripts, `queue_free()`
  hygiene, a real verification gate (`verify.ps1`) with a gameplay simulation.
- Cute, consistent art direction (pastel palette, cat-eared buildings, wagging
  rat tails, sleepy sun with a face).

**What's missing (summary — detail in §2)**

- No menu/title screen, no pause, no settings (ESC **quits the game**).
- No juice: no particles, shake, flash, or celebration moments.
- No meta progression, economy, or cosmetics — the IAP surface doesn't exist yet.
- No RevenueCat at all → **the game as-is fails the Shipaton hard constraint**.
- Mobile readiness is unproven (touch path, orientation, safe areas, audio unlock).
- Difficulty plateaus after ~wave 15 (all caps hit).
- A real design hole: **rats target turrets but turrets are invincible** (§2.1).

## 2. Gaps & defects found in the code

1. **Turret threat is dead.** `_pick_target()` (`game.gd:248`) sends ~35% of rats
   at turrets, but `_rat_landed()` (`game.gd:455`) only damages cities — a rat
   landing on a turret fizzes harmlessly. Turrets have no HP, can't die, and
   `_check_game_over()` (`game.gd:516`) only counts city buildings. The README
   claim "all buildings **or all turrets** destroyed → game over" is not what the
   code does. Consequence: the game's scardest visual (losing your guns) never
   happens, and half the rat targeting is wasted.
2. **No pause.** `ui_cancel` → `get_tree().quit()` (`game.gd:385`). No pause menu,
   no pause on focus loss, `get_tree().paused` is never used. Hostile on desktop
   (one ESC = out of the game) and missing a mobile standard.
3. **No title screen / settings.** Game drops straight into wave 1; music starts in
   `_ready()` (Android may mute it until first touch — audio unlock needed). No
   sound toggle, no how-to-play, no shop entry point.
4. **Single SFX voice.** `sfx.gd:40` reuses one `AudioStreamPlayer` — every
   `play()` cuts the previous sound. Fast chain-pops (the core fun moment) get
   audibly chopped.
5. **Difficulty plateaus.** Rat count caps at 26 (wave 11+), speed caps at 190
   (wave ~15+), splitters cap at 3/wave forever. After ~wave 15–20 the endless
   mode is flat — the game stops getting harder.
6. **No juice.** No particles, screen shake, hit flash, squash & stretch, combo
   milestone feedback, or wave-clear celebration. Everything is a pastel circle.
   This is the single biggest gap between "it works" and "it's fun to watch".
7. **No meta progression.** Only a best score. No currency, unlocks, cosmetics,
   achievements, or stats — so the planned cosmetic-pack IAP has **no surface to
   attach to**, and `Palette` is a `const` class that must be refactored before
   theming is possible.
8. **Input is minimal.** Tap = nearest turret fires at that point. Relies on
   `emulate_mouse_from_touch` (default on) rather than handling
   `InputEventScreenTouch` directly; no multi-touch, no hold-to-fire, no haptics.
   Portrait phone: 1280×720 + `expand` aspect renders the playfield as a thin
   mid-screen band — no landscape lock set.
9. **No onboarding.** Splitter and combo rules are never explained; first launch
   is a cold start into a wave.
10. **Game over is thin.** Final score + PLAY AGAIN. No stats, no "NEW BEST!"
    celebration, no share, no ad slot, no judge promo path.
11. **Minor code notes.**
    - `city.gd:5` `building_destroyed` signal is emitted but never connected (dead).
    - `_pick_target()` turret branch can silently fall through to a random point
      if all 0.5 checks fail (`game.gd:257`).
    - `_update_hud()` calls `get_minimum_size()` every frame (`game.gd:164`) —
      minor cost, fine for now.
    - No "rats remaining" indicator; turret cooldown has no visual feedback.
    - Splitter children get 1.0 s spawn-grace (`game.gd:244`) — generous, but it
      reads as a free hit window in fast chains.
    - Wave break is a fixed 2.6 s with no interlude content — a wasted beat.
    - No `process_mode` tuning; HUD labels are small (26 px @ 1280) — OK, but
      check readability on small phones after the landscape lock.

## 3. Improvement opportunities

### A. ENGAGING — depth, mastery, progression

| # | Opportunity | Why it works | Effort |
|---|-------------|--------------|--------|
| A1 | **Fix the turret threat**: rats landing on a turret destroy it (1 hit); game over also when all turrets are dead; optional classic-MC rule: player explosions can damage turrets (toggle) | Turns the scardest visual into a real decision: defend the guns or the city. Fixes §2.1 + README mismatch | S |
| A2 | **New rat types** (all procedural, zero assets): Weave Rat (sine path, w4+), Shell Rat (2 hits or chain-kill only, w6+), **Rat King boss every 5 waves** (huge, 5 HP, splits into 4 on death), late-wave ground-splits (classic MC submunitions) | Variety is the #1 retention lever in arcade shooters; boss waves create memorable moments for the demo video | M |
| A3 | **Biscuit drops**: some rats drop a spinning biscuit; tap to collect (+points, +currency) | Adds a *second input verb* (defend **and** collect) and forces a fun risk tradeoff; feeds the economy (C1) | S |
| A4 | **Power-ups** (5–8 s, one active, HUD timer): Double Shot, Wide Boom, Slow-Mo, City Shield | Instant power fantasy, standard arcade vocabulary, cheap to build on the existing firing/explosion code | M |
| A5 | **Wave-break "pick your buff"** (roguelite-lite): between waves, choose 1 of 3 small upgrades | A 2-second decision every wave keeps runs feeling authored; differentiates from plain MC | M |
| A6 | **Endless escalation past the caps**: after w15 keep raising speed/spawn/splitter share; unlock new types on a fixed wave schedule | Kills the flat endgame (§2.5); gives high-wave players a real wall to climb | S |
| A7 | **Daily Challenge**: seeded RNG (seed = date), one featured run/day, seed shown on game over | Cheapest real retention hook (no backend); social comparison without a leaderboard | S |
| A8 | **Meta progression**: biscuit currency → unlockable cat skins / city themes / trails; achievements; lifetime stats (kills, best wave, best combo) | Turns a 3-minute loop into a 3-month game; free unlocks = perceived value, paid packs = expansion (C2) | L |

### B. ENTERTAINING — juice, feel, charm

| # | Opportunity | Why it works | Effort |
|---|-------------|--------------|--------|
| B1 | **Juice pass** (biggest single lever): particle puffs on rat death (fur + stars), screen shake on city hit & boss death, 1-frame white hit-flash, explosion ring pulse, turret barrel recoil, cat blink/worry faces, wave-clear confetti + fanfare, **"NEW BEST!" stamp** | The difference between "it works" and "I want to play again". All doable in `_draw()`/GPUParticles2D with zero assets | M |
| B2 | **Slow-mo clutch**: 0.3 s timescale drop on the *last rat of a wave* | One line (`Engine.time_scale`) for a huge "wow" beat; perfect for the demo video | S |
| B3 | **Combo milestones**: ×2/×3/×5 → chime + banner + flash + haptic tick | Makes the existing combo system *felt* instead of just a number | S |
| B4 | **SFX pool (6 voices) + new sounds**: combo-up, power-up, biscuit, boss roar, shield, unlock | Fixes the chopped chain-pops (§2.4); layered pops are the genre's signature | S |
| B5 | **Music tiers**: calm (w1–3) → upbeat (w4–9) → intense (w10+/boss), all synthesized | Music that follows the tension curve; 3 short loops in the existing `sfx.gd` machinery | M |
| B6 | **Title screen**: cat logo, PLAY / HOW TO / SHOP / sound toggle; cat blinks; **animated 3-panel how-to** (procedural) | First impression for store screenshots and judges; fixes §2.3/§2.9 | M |
| B7 | **Flavor & easter eggs**: rotating wave banners ("A Rat King approaches!"), tap the sun → it blinks, tap your cat → hearts + meow | Charm is the Design-award play; costs minutes | S |
| B8 | **Haptics** (Android `Input.vibrate`): tick on fire, thump on kill, pattern on wave clear/boss | Free juice on mobile; PLAN.md already lists it | S |
| B9 | **Rich game-over screen**: stats (wave, kills, best combo, biscuits), NEW BEST celebration, share card, ad slot | Closes the loop, feeds growth + Catvertising | M |

### C. VALUABLE — monetization, retention, hackathon fit

| # | Opportunity | Why it works | Effort |
|---|-------------|--------------|--------|
| C1 | **RevenueCat SDK via GDExtension** (native `purchases` SDKs behind a thin bridge): Kitty Pack $2.99, extra packs $1.99–2.99, Remove Ads $0.99, **judge promo code** | **Hard constraint of the hackathon — the game as-is cannot be submitted without it.** Also the #1 schedule risk (no official Godot SDK) → spike first | L (risk) |
| C2 | **Theme system**: refactor `Palette` consts → swappable `Theme` data; ship default + 2 paid themes (e.g. Sakura City, Midnight Purr) | This *is* the IAP surface. Zero-asset theming is the story that makes $2.99 cosmetic packs credible and novel | M |
| C3 | **RevenueCat Ads**: interstitial on game-over, frequency-capped (1 per 2 runs), skippable, behind Remove Ads | Catvertising stretch award; the game-over screen is the only sane slot | S (after C1) |
| C4 | **Retention loop**: daily challenge (A7) + daily biscuit bonus + in-app streak + achievements (A8) | "Keep Them Coming Back" story; daily return reason for a 3-minute game | S–M (reuses A7/A8) |
| C5 | **Mobile hardening**: landscape lock, `InputEventScreenTouch` handling, safe-area HUD insets, pause on focus loss, audio unlock on first touch, 60 fps budget on mid-range Android | Store-quality baseline; several are currently unproven (§2.8) | M |
| C6 | **Store assets**: 1024×1024 icon (rasterize `icon.svg`), 1179×2556 frameless screenshot (can be rendered headless from the game itself), ≤2 min demo video (script the B2 slow-mo + boss moments) | Submission requirement; the procedural pipeline makes a headless screenshot capture a cheap win | M |
| C7 | **Growth kit**: share card, itch.io desktop release, #BuildInPublic cadence, growth log discipline | Grand Prize path + Best Game judges look for momentum, not just polish | S |

## 4. Prioritized roadmap (target: store submission ~Sep 15)

**Wave 1 — de-risk & feel (now → ~Sep 11)**
1. C1 RevenueCat GDExtension spike (start immediately — longest lead time, biggest risk)
2. C2 Theme refactor + 2 paid themes (unblocks all cosmetics)
3. C5 Mobile hardening (landscape lock, touch, pause, safe area, audio unlock)
4. B6 Title screen + settings + how-to + B4 SFX pool (fixes the chop)
5. B1 juice pass + B2 slow-mo + B3 combo milestones
6. A1 turret-kill fix (+ game-over rule) — small change, big design win

**Wave 2 — depth & value (~Sep 11 → Sep 15)**
7. A2 rat types (Weave, Shell) + Rat King boss (w5, w10…)
8. A3 biscuit drops + A4 two power-ups (Double Shot, Wide Boom)
9. A6 escalation past the caps
10. B5 music tiers + B7 flavor + B8 haptics
11. B9 rich game-over (stats, NEW BEST, share) + C3 ads + judge promo live
12. C6 store assets (icon, screenshot, demo video)
13. **Submit to store by Sep 15** → Devpost by Sep 30

**Wave 3 — retention (post-submission, if time allows)**
14. A5 wave-break buff pick · A7 daily challenge · A8 full economy + achievements
15. A2 remainder (ground-splits), B5 remainder, C7 growth cadence

**Cut line (if time runs short):** A5, A8, C7 are pure stretch.
Non-negotiables: C1, C2, C3/promo, C5, C6, B1, A1.

## 5. Risks

| Risk | Mitigation |
|------|------------|
| **RevenueCat on Godot** — no official SDK; GDExtension bridge to native `purchases` SDKs is unproven in this workspace | Spike in Wave 1 (first task). Fallback: minimal bridge exposing only `configure`/`purchase`/`restore`/`entitlements` + promo redeem. If the bridge fails, the submission is in trouble — hence first |
| **iOS export needs macOS** (none in this workspace) | Ship Android first (Play + Galaxy); iOS via a Mac session or CI runner in Wave 2/3 |
| **Scope creep** — the list above is ~25 items | The cut line in §4; juice (B1) is the only "nice-to-have" that's actually mandatory for Best Game |
| **Time** — ~3.5 weeks to Sep 15, store review takes days | Submit by Sep 15, not Sep 30; daily check-ins against §4 |
| **Juice regressions in headless gate** | Extend `gameplay_test.gd` for turret-kill, power-ups, boss; keep `verify.ps1` green after every batch (AGENTS.md mandate) |

## 6. Suggested next steps

1. Review this doc; confirm the Wave 1 list and the A1 design choice
   (rat-landing kills turret vs. classic-MC friendly fire).
2. File the Wave 1 items as beads issues under the open epic
   `ship-a-ton-2026-bi8` (only the epic + one closed scaffold issue exist today).
3. Start the RevenueCat GDExtension spike in parallel with the theme refactor.
