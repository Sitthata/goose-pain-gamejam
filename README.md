# GooseJanitor

A boss battle game jam entry for the **Goedware Game Jam - Boss Battle Edition**.

Inspired by *The Dark Queen of Mortholme* — you play as the boss. You are a goose. You are the janitor. You will not tolerate bacteria in your room.

## Concept

You are a powerful goose janitor defending your room from bacteria. The bacteria spread filth across the floor — the dirtier the room, the stronger they become. Clean the room or be overwhelmed.

## Core Loop

```
Defend Phase (fight bacteria 1v1)
    ↓ defeat enemy
Clean Phase (5–10s random window — press to clean stains)
    ↓ room not at 0% stain
Stronger bacteria respawns
    ↓ repeat
```

The **stain gauge is everything** — it's your health, your threat meter, and your win condition. Reduce stain to 0% to survive. There is no HP bar.

## Player Phases

### Phase 1 — Janitor Mode
- Grounded movement (horizontal only)
- Dedicated clean action during Clean Phase
- Fight and clean are separate activities

> [EXPERIMENTAL] Phase 1 movement restrictions are subject to change based on prototype feedback.

### Phase 2 — Goose Boss Mode
- Full rogue-like movement: run, jump, glide
- Can clean and attack simultaneously
- Unlocked through progression (TBD)

## Stain System

- Bacteria movement spawns stains on the floor
- Stain % directly scales enemy strength: more filth = faster, dodgier, more dangerous bacteria
- Bacteria are not transformed mid-fight — each defeated enemy respawns as a **new, stronger scene**
- Clean Phase is time-limited and random (5–10s) — use it wisely

## Feature Priorities

| Priority | Features |
|---|---|
| **Must Have** | Stain system, 2 player movesets, double jump/glide, 1 enemy per phase, enemy death loop, Boss Stage, enemy AI behavior |
| **Should Have** | Filth UI, sound, hit reactions, screen shake, dialog, VFX, lighting, phase transition sprites, parallax bg |
| **Could Have** | Reflective floor after clean, phase transition effects, cutscene |
| **Won't Have** | Parry |

## Development Milestones

### Day 1
- [ ] Player movement (1 moveset)
- [ ] Stain System — spawn stain, clean stain
- [ ] Player clean action
- [ ] Enemy spawns stain

### Day 2
- [ ] 1 enemy with simple AI
- [ ] Boss Stage scene
- [ ] Game loop system — Defend → Clean → Spawn Enemy
- [ ] Combine into 1 playable prototype

## Project Structure

```
assets/                   # Raw art assets (source files ready for Godot)
  character/              # Player sprites and animations
  enemies/                # Bacteria enemy sprites (one folder per tier)
  tilemap/                # Tilemap art
  weapons/                # Weapon art (TBD)
  ui/                     # UI elements (filth gauge, icons)

scenes/                   # Godot scenes — scene + script live together
  player/
    player.tscn
    player.gd
  boss/                   # One subfolder per bacteria evolution tier
    bacteria_base.tscn
    bacteria_base.gd
    bacteria_tier2.tscn
    bacteria_tier2.gd
  levels/                 # Room/stage scenes
  ui/                     # UI scenes (HUD, filth gauge)

resources/                # Godot .tres / .res resource files
  tilemap/                # TileSet resources
  themes/                 # UI themes

scripts/                  # Standalone scripts with no paired scene
  autoload/               # Singletons (StainSystem, GameLoop, etc.)
  utils/                  # Shared helper scripts

planning/                 # Design docs and context

docs/                     # Technical spike documents
  STAIN_SPIKE.md          # Stain system design + implementation guide
  AI_SPIKE.md             # Enemy AI design + implementation guide
```

### Conventions

- **Scene + script together** — `player.tscn` and `player.gd` live in the same folder under `scenes/`
- **Autoloads for shared systems** — `StainSystem` and `GameLoop` go in `scripts/autoload/` and are registered in Project Settings → Autoload
- **One folder per enemy tier** — each bacteria evolution is its own subfolder under `scenes/boss/`
- **`assets/` is art-in, `resources/` is Godot-out** — raw sprites go in `assets/`, generated `.tres` files go in `resources/`

## Game Jam

[Goedware Game Jam - Boss Battle Edition](https://itch.io/jam/goedware-game-jam-boss-battle-edition)

## Engine

Godot 4
