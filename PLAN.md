# Meow Command — Build Plan

> **2026-09-04:** full game analysis + improvement roadmap (gaps found in code,
> engagement/entertainment/value opportunities, Wave 1–3 priorities) — see
> `ANALYSIS.md`; hand-crafted art contract in `ART_SPECS.md`.
>
> **2026-09-04:** Batches 1–3 delivered: screens & flow, mobile hardening,
> audio, juice, combat depth (Rat King, shells, weave), rich game-over,
> economy (biscuits, power-ups, themes, skins, shop, 10 achievements, daily
> challenge), asset drop-in pipeline, 1024 icon + 1280×720 frame capture.
> All green through `verify.ps1`.

Target: **Best Game** (primary), Design / Catvertising (stretch).
Ship window: first public release **Aug 1 – Sep 30, 2026**; Devpost deadline
**Sep 30, 2026 11:45 pm PDT**. Store review takes days → target store
submission by **~Sep 15**.

## Platform targets

| Platform | Store | Notes |
|---|---|---|
| Android | Google Play + Galaxy Store | Primary. Godot Android export (AAB), GL Compatibility renderer already set |
| iOS | App Store | Godot iOS export requires macOS + Xcode (run on a Mac / CI runner) |
| Desktop | — (local play, dev, itch.io optional) | Windows / macOS / Linux exports for local testing & dev convenience |

## Phases

### Phase 0 — Core game ✅ (done 2026-08-28)

- [x] Godot 4.7.2 scaffold, main scene, procedural art + SFX
- [x] Gameplay: waves, rat spawning, turret firing, chain explosions,
	  scoring, best-score persistence, game over, restart
- [x] Depth: Splitting Rats (wave 3+, split into 2 fast pups) + rolling
	  Combo multiplier (2.5 s window, ×5 cap) + dog→rat rebrand
- [x] Headless gate: `verify.ps1` (import → parse → smoke → gameplay sim →
	  300-frame run), sandbox-tolerant
- [x] Docs: README.md, PLAN.md, PROJECTS.md entry
- [x] Repo: GitHub `vl4dt/meow-command`

### Phase 1 — Mobile-ready (mostly done 2026-09-04)

- [x] Touch input: tap-to-fire via touch→mouse emulation
	  (`emulate_mouse_from_touch`); verified in `_unhandled_input` path
- [x] Layout: landscape lock + `canvas_items` + `expand`; 1280×720 base
- [ ] Performance: 60 fps on a mid-range Android device; profile explosion
	  count; cap simultaneous rats/explosions if needed (needs a device)
- [x] Pause on app focus loss; audio unlock on first touch (Android)
- [x] Optional: haptics on fire/kill (Android `Input.vibrate` via guarded
	  dynamic call)

### Phase 2 — Monetization (RevenueCat)

- [ ] RevenueCat SDK via GDExtension (`purchases` native SDKs: Android Kotlin /
	  iOS Swift, or Godot Purchases plugin)
- [ ] Products: Kitty Pack (cosmetic themes), extra packs, Remove Ads
- [ ] Paywall screen (in-app, cute) + judge promo code path
- [ ] Optional: RevenueCat Ads interstitial on game-over (Catvertising stretch)
- [x] Theme system: static-var `palette.gd` + Classic/Sakura/Midnight themes,
	  4 cat skins, in-game shop (biscuit currency) — RevenueCat packs map
	  onto the same theme/skin slots

### Phase 3 — Exports & store assets

- [ ] Android: export template install, AAB build, signing key, Play Console
	  + Galaxy Store listings
- [ ] iOS: export on macOS, provisioning, App Store Connect listing
- [ ] Desktop: Windows/macOS/Linux releases (local dev + itch.io)
- [x] Icon 1024×1024 — `tools/gen_icon.gd` → `assets/store/icon.png`
	  (project icon wired)
- [ ] Screenshot 1179×2556 frameless (portrait) — base 1280×720 gameplay
	  frame captured at `assets/store/frame_capture.png`
- [ ] Demo video ≤2 min (script → screen recording → edit)

### Phase 4 — Submit & grow

- [ ] Devpost entry (text + video + store URL + assets)
- [ ] Judge promo code live
- [ ] Growth experiments logged in README growth log (needed for
	  Grand Prize path if we keep shipping)

## Risks & notes

- **iOS export needs macOS** — no Mac in this workspace; plan a Mac session or
  CI (macOS runner) before Phase 3.
- **RevenueCat on Godot** — no official Godot SDK; use native SDKs behind a
  thin GDExtension bridge. Spike early in Phase 2.
- **Procedural art is a strength and a risk** — it keeps the build asset-free,
  but store screenshots need a polished frame; art pass in Phase 1/3.
- **Godot version pinned to 4.7.2** — do not upgrade casually (see AGENTS.md).
