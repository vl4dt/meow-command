# AGENTS.md — Meow Command

Cute Missile Command clone: dogs rain from the sky, cats in cannons defend
Kitty City. Godot **4.7.2 stable, GDScript** (pinned — do not upgrade casually).

## Run

```
C:\Apps\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe --path .
```

## Verification gate (MANDATORY after every edit batch)

```
pwsh -File verify.ps1
```

Note: invoke with **pwsh (PowerShell 7)** — Windows PowerShell 5.1 misreports
Godot's stderr output as a failed exit code.

Order: `--import` → `--check-only` per script → smoke test → 300-frame smoke run.
All must exit 0. Never trust an edit you haven't validated headlessly.

## Layout

- `scripts/game.gd` — game controller (waves, scoring, input, cleanup)
- `scripts/dog_missile.gd`, `player_missile.gd`, `explosion.gd` — entities
- `scripts/city.gd`, `turret.gd` — defenses
- `scripts/background.gd`, `palette.gd`, `sfx.gd` — presentation
- All art is procedural (`_draw()`) — no texture assets. Retheme via `palette.gd`.

## Conventions

- No Godot 3 API bleed (`onready`, `yield(`, `.instance()`, `export var`).
- Type annotations on params/returns; `@onready`/`const` where appropriate.
- `queue_free()` for entity cleanup; game.gd `_cleanup()` reconciles arrays.
- Never hand-edit `.godot/` — it's a regenerable cache.
