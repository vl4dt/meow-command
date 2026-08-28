# Meow Command — Build Plan

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
- [x] Gameplay: waves, dog spawning, turret firing, chain explosions,
      scoring, best-score persistence, game over, restart
- [x] Headless gate: `verify.ps1` (import → parse → smoke → gameplay sim →
      300-frame run), sandbox-tolerant
- [x] Docs: README.md, PLAN.md, PROJECTS.md entry
- [x] Repo: GitHub `vl4dt/meow-command`

### Phase 1 — Mobile-ready (next)

- [ ] Touch input: tap-to-fire works with `InputEventScreenTouch`; verify
      `_unhandled_input` path; consider hold-to-aim
- [ ] Layout: confirm `canvas_items` + `expand` stretch looks right in
      portrait (19.5:9) and landscape; HUD safe-area insets (notches)
- [ ] Performance: 60 fps on a mid-range Android device; profile explosion
      count; cap simultaneous dogs/explosions if needed
- [ ] Pause on app focus loss; audio unlock on first touch (Android)
- [ ] Optional: haptics on hits (Android `Input.vibrate`, iOS via plugin)

### Phase 2 — Monetization (RevenueCat)

- [ ] RevenueCat SDK via GDExtension (`purchases` native SDKs: Android Kotlin /
      iOS Swift, or Godot Purchases plugin)
- [ ] Products: Kitty Pack (cosmetic themes), extra packs, Remove Ads
- [ ] Paywall screen (in-app, cute) + judge promo code path
- [ ] Optional: RevenueCat Ads interstitial on game-over (Catvertising stretch)
- [ ] Theme system: swap `palette.gd` + building/turret colors per pack

### Phase 3 — Exports & store assets

- [ ] Android: export template install, AAB build, signing key, Play Console
      + Galaxy Store listings
- [ ] iOS: export on macOS, provisioning, App Store Connect listing
- [ ] Desktop: Windows/macOS/Linux releases (local dev + itch.io)
- [ ] Icon 1024×1024 (from `icon.svg`), screenshot 1179×2556 frameless
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
