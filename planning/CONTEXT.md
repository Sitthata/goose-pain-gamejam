# GooseJanitor — Design Context

Game jam: Goedware Game Jam - Boss Battle Edition
Engine: Godot 4
Inspiration: The Dark Queen of Mortholme (play as the boss)

## Core Concept

You are a goose. You are the janitor. You are the boss.

Bacteria invade your room and spread stains. The dirtier the room, the stronger they become.
Fight them. Clean the room. Don't let the filth win.

## The Stain System

The stain gauge is the single most important system in the game:
- Bacteria movement spawns stains on the floor
- Stain % directly scales enemy power (speed, dodge, moveset unlocks)
- The stain gauge IS the health — no separate HP bar
- Goal: reduce stain to 0%

## Game Loop

```
[Defend Phase]
  Player fights 1 bacteria enemy (always 1v1)
        ↓ defeat enemy
[Clean Phase]
  Time window: 5–10 seconds (random)
  Player presses button on stains to clean
        ↓ if stain not 0%
[Stronger bacteria respawns]
  New enemy scene (higher tier), not same scene modified
        ↓
  repeat
```

## Player Phases

Phase 1 — Janitor Mode
- Horizontal movement, grounded
- Fight and clean are separate actions
- STATUS: EXPERIMENTAL — movement restrictions subject to change

Phase 2 — Goose Boss Mode
- Run, double jump, glide
- Clean and attack simultaneously
- Unlocked via progression (mechanism TBD)

## Enemy Design

- 1v1 always — no multi-enemy spawns planned
- Each evolution tier = separate Godot scene
- AI must read stain % to adjust behavior:
  - Low stain: basic movement + stain spreading
  - Medium stain: adds dodging
  - High stain: unlocks additional attack movesets

## Open Questions

- What triggers Phase 2 unlock?
- How many enemy evolution tiers?
- Explicit win condition (stain 0% triggers victory screen?)
- Explicit lose condition (stain 100%? player gets knocked out?)
- Weapons / combat moveset design

## Feature Priority (from planning board)

MUST HAVE:
- Stain System (spawn stain, clean stain)
- Player with 2 movesets
- Player movement horizontal + vertical
- Double jump / glide
- 1 enemy per phase
- Enemies death loop
- Boss Stage
- 4-5 sprites per enemy tier
- Enemy AI behavior

SHOULD HAVE:
- UI filth gauge
- Sound
- Hit reaction
- Screen shake
- Dialog
- VFX
- Lighting
- Sprite transition between phases
- Parallax background

COULD HAVE:
- Reflective floor after clean
- Phase transition effect
- Cutscene

WON'T HAVE:
- Parry
