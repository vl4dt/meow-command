# Meow Command — Hand-Crafted Art & Asset Spec

_Date: 2026-09-04 · For: the human artist (you). Everything here is a **drop-in
replacement** for the current procedural art — the game auto-detects each file
and falls back to code-drawn art if it's missing, so the game is always
playable while you work through this list._

## 1. Where hand-crafted art adds the most value (analysis)

The game is 100% procedural today: charming, but "flat" — every character is a
cluster of circles. Hand-crafted art is the single biggest quality lever left,
ranked by impact:

| Rank | Asset | Why it matters |
|------|-------|----------------|
| 1 | **App icon (1024)** + **store screenshot** | First impression in the store; decides tap-through. A crafted icon with depth/shadow reads "real game" vs "prototype". |
| 2 | **Hero cat (turret)** | The face of the game. A crafted cat with ears/stripes/tail/expressions turns "blob in cannon" into a mascot players screenshot. |
| 3 | **Rat family (6 kinds)** | Type readability is *gameplay*: today weave/shell/king differ mostly by color. Distinct silhouettes (ribbon, shell, crown) make threats readable at a glance. |
| 4 | **Background (1280×720)** | A painted sky/sun/hills/meadow gives atmosphere + makes every screenshot and the demo video look finished. |
| 5 | **Explosion + missile sprites** | The chain-pop moment is the core fun; a starburst sprite reads far better than a circle, especially mid-combo. |
| 6 | **UI kit** (panel, button, icons) | Panels + icons sell "store-quality product" on title/shop/game-over screens. |
| 7 | **Logo / wordmark** | Brand for title screen, store listing, demo video. |
| 8 | **Cat skins + theme backgrounds** | Perceived value for the cosmetic shop (free unlocks + future IAP packs). |
| 9 | **FX particles** (puff, star, confetti, spark) | Polish layer; the procedural fallbacks are decent, so this is last. |
| 10 | **Audio** (optional) | Hand-made SFX/music replace the synthesized ones (spec in §6). |

**Effort budget (estimate):** P0 ≈ 2–4 h · P1 ≈ 6–10 h · P2 ≈ 4–6 h → a full
store-ready art pass is roughly **12–20 h** of hand-crafting.

## 2. Style guide (keep every asset cohesive)

- **Mood:** cozy, sleepy, pastel. Rats are *cute villains*, never scary.
- **Shapes:** rounded, soft, slightly squishy. No sharp corners anywhere.
- **Outlines:** characters/sprites get a **2–4 px outline in deep plum `#5b4a5e`**.
  Soft FX (explosion, puff, spark) get **no outline** — just soft alpha edges.
- **Shading:** flat base + **one shadow tone** (≈15–20 % darker) + optional one
  highlight. No gradients on characters; gradients OK for sky/background.
- **Light:** soft, from top-left.
- **Color source of truth:** the palette below (from `palette.gd` — the game
  renders with exactly these). Stay inside it for cohesion; new accents must be
  pastel-matched.
- **Format:** PNG-24 with alpha, sRGB. No spaces in filenames. Lowercase.
- **Anchors:** every sprite is centered on the **action point** (where the code
  draws it) unless stated otherwise.

### Palette (hex)

| Role | Colors |
|---|---|
| Sky / world | `#ffd9e8` top · `#cfe4ff` mid · `#fff3d6` bottom · sun `#ffdf8a` (face `#e8a94e`) · hills `#cdeecb` / `#b2e3ae` · ground `#9fd99a` (edge `#7cc477`) |
| Cat city | buildings `#f7a8c4` `#9fc3f7` `#c3a8f7` `#f7cf9f` `#9fe8cf` · roof/door `#5b4a5e`/`#8a6f84` · window `#fff8e1` (frame `#8a6f84`) · heart `#ff6f91` · rubble `#b9a8a0` |
| Turret cat | body `#f7c873` · belly `#ffe3b3` · barrel `#7a6a5f` · eye `#3a2e2a` · cheek `#ff9eb5` · dead `#b8b0ad` |
| Rats | body `#d9a066` · splitter `#c96a4a` · ear `#a9744f` · muzzle `#f3d3b3` · nose `#4a3728` · tongue `#ff8fa3` · trail `#ffc98a` |
| FX / UI | missile `#6fd3ff` · explosion `#ffb3c7` / `#fff1f5` · UI text `#5b4a5e` · accent `#ff7aa2` |

## 3. Integration contract (how the game consumes your art)

- Drop files into **`assets/sprites/`** (audio: `assets/audio/`) with the
  **exact names** below.
- The game's asset loader (`scripts/assets.gd`) checks each filename at
  runtime: **present → your art is used; missing → the procedural fallback
  draws instead.** No code edits, no renaming, no config.
- Sprites are drawn at the in-game sizes in §4 (the loader scales your canvas
  to the in-game footprint), so you can paint at any comfortable resolution —
  the listed sizes are the recommended 2× targets for crispness.
- To test: just run the game — every asset swaps in live.

## 4. Asset list (P0 → P2)

### P0 — store-required (do these first)

| File | Canvas | What to draw | Notes |
|---|---|---|---|
| `assets/store/icon_1024.png` | **1024×1024** | The game's icon: the hero cat in its cannon, a star missile mid-flight, soft pastel sky background, rounded-square composition (stores crop corners). A crisp 1024 procedural base is generated for you in `assets/store/` — refine or replace it. | Must read at 48 px (phone icon size). High contrast between cat and background. No text. |
| `assets/store/screenshot_1179x2556.png` | **1179×2556** | Final store screenshot (frameless, no device bezel). Suggested composition: top third = logo + tagline ("Defend Kitty City from the rat swarm!"); middle = the 1280×720 gameplay frame (I generate one at `assets/store/frame_1280x720.png` to build from); bottom third = 3 feature bullets + cat faces. | Required size per Shipaton. Safe margin ≥ 60 px on all sides. |
| `assets/sprites/logo.png` | **1024×512** | "Meow Command" wordmark + the hero cat (paw-print or star accents). Playful, rounded lettering. | Title screen + store listing + demo video. Transparent background. |

### P1 — core characters & world (the big quality jump)

| File | Canvas | What to draw | Notes |
|---|---|---|---|
| `assets/sprites/cat_turret.png` | **128×128** | The hero cat: sitting, front view, big eyes, blush, little "w" mouth, ears, a tail curling out, sitting *in* a cannon dish (dish/base included, **barrel excluded** — it's a separate rotating sprite). Anchor: **bottom-center** (the cat's seat is the origin). | The mascot. Add 2–3 expression details (blush, shine in eyes). |
| `assets/sprites/turret_barrel.png` | **96×32** | A cute cannon barrel pointing **+X (right)**, rounded muzzle, plum outline. Anchor: **left-center** (pivot at x=0, y=16) — the game rotates this sprite to aim. | Keep it short & stubby (reads at 30 px in-game). |
| `assets/sprites/rat_normal.png` | **96×96** | The standard rat: front view, round body, big ears, pink nose, happy tongue, wagging tail. Anchor: center. | The workhorse enemy — make it endearing. |
| `assets/sprites/rat_splitter.png` | **128×128** | Bigger, stockier rat, slightly angry eyes, two little "cracks" or twin-tails hinting it splits. Anchor: center. | Must read as "bigger + meaner" than normal at 44 px. |
| `assets/sprites/rat_child.png` | **64×64** | Tiny, skittish pup: wide eyes, big head, small body. Anchor: center. | Reads as "fast + fragile". |
| `assets/sprites/rat_weave.png` | **96×96** | A rat with a **ribbon/bow** (or a scarf) — its tell is that it weaves. Anchor: center. | Silhouette must differ from normal (the ribbon). |
| `assets/sprites/rat_shell.png` | **96×96** | A rat wearing a **little helmet/shell** (its armor — takes 2 hits). Anchor: center. | The helmet is the readability hook. |
| `assets/sprites/rat_king.png` | **256×256** | **The Rat King**: large, regal — a golden crown, droopy jowls, tiny scepter or monocle, smug expression. Anchor: center. | Boss every 5 waves. Must look 3× more impressive than the splitter. |
| `assets/sprites/biscuit.png` | **64×64** | A paw-print biscuit (or a bone-shaped cookie), golden, with a shine. Anchor: center. | The collectible — should look *delicious*. |
| `assets/sprites/explosion.png` | **256×256** | Soft radial starburst: white core → `#ffb3c7` petals → transparent edge. 8–12 rounded petals, no outline. Anchor: center. | Scaled from 8 px to 110 px in-game; keep detail in the core. |
| `assets/sprites/missile.png` | **64×64** | A little 5-point star with a soft `#6fd3ff` glow halo. Anchor: center. | The player's star missile. |
| `assets/sprites/building.png` | **128×256** | One cat house: cat-ear roof, round window with frame, door with paw knob, a cat silhouette in the window (optional). Neutral pink `#f7a8c4` body. Anchor: **bottom-center**. | Optional: `building_2.png` / `building_3.png` variants (blue `#9fc3f7`, lilac `#c3a8f7`) for per-city variety. |
| `assets/sprites/rubble.png` | **128×64** | A soft pile of pastel rubble with a tiny heart on top. Anchor: bottom-center. | Replaces the destroyed-building look. |
| `assets/sprites/background.png` | **1280×720** | The full painted backdrop: pastel sky gradient (top `#ffd9e8` → mid `#cfe4ff` → bottom `#fff3d6`), sleepy smiling sun top-right, two soft hills, green meadow band along the bottom ~56 px. **Do NOT include** clouds, buildings, turrets, or HUD — those are drawn on top in code. | The atmosphere piece. Keep the bottom 56 px as flat meadow (`#9fd99a`) so the city sits on it. |

### P2 — UI kit, FX, cosmetics (polish)

| File | Canvas | What to draw |
|---|---|---|
| `assets/sprites/ui_panel.png` | 512×320 | Rounded pastel panel (fill `#fff3d6`-ish, plum border 6 px, soft inner highlight). Drawn with ≥16 px uniform border so the game can stretch it. |
| `assets/sprites/ui_button.png` | 320×96 | Rounded button: accent `#ff7aa2` fill, white text area, 8 px bottom shadow (plum). |
| `assets/sprites/ui_heart.png` | 64×64 | The HP heart (`#ff6f91`, plum outline, white shine). |
| `assets/sprites/ui_biscuit.png` | 64×64 | The biscuit as a currency icon (slightly more saturated than the in-game one). |
| `assets/sprites/ui_powerup_double.png` | 96×96 | Icon: two star missiles side by side (in a soft badge circle). |
| `assets/sprites/ui_powerup_wide.png` | 96×96 | Icon: one big starburst (badge circle). |
| `assets/sprites/ui_powerup_slow.png` | 96×96 | Icon: a star with a clock/hourglass (badge circle). |
| `assets/sprites/ui_powerup_shield.png` | 96×96 | Icon: a dome over a cat house (badge circle). |
| `assets/sprites/ui_combo_badge.png` | 128×128 | A badge with "×5" space in the middle (starburst ring, accent colors). |
| `assets/sprites/fx_puff.png` | 128×128 | Soft fur puff (3–5 rounded blobs, `#d9a066`→transparent). No outline. |
| `assets/sprites/fx_star.png` | 64×64 | A tiny 4-point sparkle star, white→`#ffdf8a`. No outline. |
| `assets/sprites/fx_confetti.png` | 32×64 | A single confetti strip (rounded rectangle, any pastel — the game tints it). |
| `assets/sprites/fx_spark.png` | 64×64 | A soft radial spark (white core → transparent). |
| `assets/sprites/cat_mochi.png` | 128×128 | **Skin: Mochi** — the hero cat, white/cream, same pose/anchor as `cat_turret.png`. |
| `assets/sprites/cat_miso.png` | 128×128 | **Skin: Miso** — the hero cat, dark charcoal-gray with a cream muzzle. |
| `assets/sprites/cat_peppermint.png` | 128×128 | **Skin: Peppermint** — the hero cat, white with soft pink stripes. |
| `assets/sprites/bg_sakura.png` | 1280×720 | **Theme background: Sakura City** — pink sky, pale sun, cherry-blossom hills, drifting petals in the paint (same composition rules as `background.png`). |
| `assets/sprites/bg_midnight.png` | 1280×720 | **Theme background: Midnight Purr** — deep indigo sky, crescent moon with sleepy face, starry, dark-teal hills, dark meadow band. |

## 5. Store assets (from P0)

- **Icon:** `icon_1024.png` is the master. Stores derive: Play 512×512,
  Galaxy, App Store 1024 — just resize (no re-crop; composition is square-safe).
- **Screenshot:** exactly **1179×2556**, frameless. One is required; a second
  (shop screen or boss moment) is a nice-to-have.
- **Demo video:** ≤2 min. Suggested beats: title → wave 1 pops → combo ×5
  moment → Rat King wave → game over with NEW BEST → shop. (I can script the
  gameplay beats; you cut.)

## 6. Optional: hand-made audio (drop-in, replaces synthesized)

Files in `assets/audio/` (OGG Vorbis, 44.1 kHz, ≤512 KB each, music loops
20–30 s seamless):

`launch.ogg` `pop.ogg` `explosion.ogg` `city_hit.ogg` `wave.ogg`
`game_over.ogg` `combo_up.ogg` `powerup.ogg` `biscuit.ogg` `boss.ogg`
`unlock.ogg` `meow.ogg` `music_calm.ogg` `music_upbeat.ogg` `music_intense.ogg`

Mood: cozy chiptune-ish, sleepy major pentatonic; the "intense" tier is the
same family faster, not scary.

## 7. Delivery checklist

**P0 (store-ready):**
- [ ] `icon_1024.png` · [ ] `screenshot_1179x2556.png` · [ ] `logo.png`

**P1 (core art pass):**
- [ ] `cat_turret.png` · [ ] `turret_barrel.png` · [ ] `rat_normal.png` ·
  [ ] `rat_splitter.png` · [ ] `rat_child.png` · [ ] `rat_weave.png` ·
  [ ] `rat_shell.png` · [ ] `rat_king.png` · [ ] `biscuit.png` ·
  [ ] `explosion.png` · [ ] `missile.png` · [ ] `building.png` (+ optional
  `_2`/`_3`) · [ ] `rubble.png` · [ ] `background.png`

**P2 (polish & cosmetics):**
- [ ] ui_panel · ui_button · ui_heart · ui_biscuit · 4× ui_powerup_* ·
  ui_combo_badge
- [ ] fx_puff · fx_star · fx_confetti · fx_spark
- [ ] cat_mochi · cat_miso · cat_peppermint
- [ ] bg_sakura · bg_midnight

**Optional audio:** [ ] 15 OGG files per §6

> **Tip:** work P0 → P1 → P2 in order; after each drop, run the game
> (`Godot --path .`) and the art swaps in live — no rebuild needed.
