# CLAUDE.md — GooseJanitor

Godot 4 game jam project. Boss battle entry for Goedware Game Jam - Boss Battle Edition.

## What This Game Is

You play as a goose janitor boss. Bacteria invade your room, spread filth, and get stronger the dirtier the room gets. Beat them, clean the room, repeat. The stain gauge IS the health system — no separate HP.

Inspired by *The Dark Queen of Mortholme* (play as the boss, not the hero).

## Game Loop

1. **Defend Phase** — fight 1 bacteria enemy (always 1v1)
2. Defeat enemy → **Clean Phase** opens (5–10s, random duration)
3. Player button-presses on stains to clean during Clean Phase
4. If room not at 0% stain → stronger bacteria respawns (new enemy scene, not a transformation)
5. Repeat until stain reaches 0%

Stain % scales enemy: more filth = enemy dodges more, gains new movesets, becomes faster.

## Player Movement — Two Phases

**Phase 1 (Janitor Mode):**
- Horizontal movement only, grounded
- Clean action is separate from combat
- ⚠️ [EXPERIMENTAL] — restrictions may change after prototype testing

**Phase 2 (Goose Boss Mode):**
- Full movement: run + double jump + glide
- Can clean and attack simultaneously
- Unlocked through progression (mechanism TBD)

## GDScript Gotchas

- **`sign()` vs `signf()`** — `sign()` returns `int`, which causes a type error when assigned to a `float` variable. Always use `signf()` when working with float values:
  ```gdscript
  # Wrong — type error if _dodge_direction is float
  _dodge_direction = sign(global_position.x - origin.x)

  # Correct
  _dodge_direction = signf(global_position.x - origin.x)
  ```

## Collaboration Model

- **Claude's responsibility** — write GDScript scripts, provide implementation guidance, design system architecture
- **Your responsibility** — create and wire up scenes in the Godot editor, assign scripts to nodes, configure node properties in the Inspector

Claude will tell you exactly which nodes to create, what to name them, and where to attach scripts. You execute that in the editor.

## Architecture Notes

- Each "evolved" bacteria is a **separate enemy scene** in Godot, not a modified instance of the same scene. Stain % determines which scene spawns.
- The stain system is central — almost everything feeds into or reads from it.
- Clean Phase has a random timer (5–10s). Design around this being tight and stressful.
- Enemy AI is a must-have — it needs to scale behavior with stain %. Plan the AI script to accept a stain parameter.

## Project Structure

```
assets/
  character/          # Player + enemy sprites
  Pixel Platformer Set 1 v1.1/   # Purchased tileset
  tilemap/            # Tilemap art
  weapons/            # Weapon art (TBD — mechanics not yet designed)
planning/
  CONTEXT.md          # Game design notes
resources/
  tilemap/            # Godot tilemap resources (.tres)
scenes/
  boss/               # Bacteria boss scenes (one per evolution tier)
  levels/             # Level/room scenes
  player/             # Player scene(s)
```

## What Is Decided vs. Experimental

| Topic | Status |
|---|---|
| Stain gauge = health | Decided |
| 1v1 enemy (no multi-spawn) | Decided |
| Stain % scales enemy strength | Decided |
| Defeat → clean phase → respawn loop | Decided |
| Clean phase is 5–10s random | Decided |
| Phase 1: grounded only | **EXPERIMENTAL** |
| Phase 2 unlock trigger | TBD |
| Weapons / combat moves | TBD |
| Win condition (stain 0% = win?) | TBD |
| Lose condition (stain 100% = lose?) | TBD |
| Number of enemy evolution tiers | TBD |

## Day Milestones

### Day 1 Target
- Player horizontal movement
- Stain spawn + clean system
- Player clean action (button press on stain)
- Enemy spawns stain on movement

### Day 2 Target
- Simple enemy AI (moves, spawns stain, scales with stain %)
- Boss Stage scene
- Full game loop: Defend → Clean Phase → Respawn Enemy
- Playable prototype

## Feature Scope

**Must Have:** Stain system, 2 player movesets, double jump/glide, 1 enemy per phase, enemy death loop, Boss Stage, enemy AI
**Should Have:** Filth UI, sound, hit reaction, screen shake, dialog, VFX, lighting, phase transition sprites, parallax bg
**Could Have:** Reflective floor after clean, phase transition effect, cutscene
**Won't Have:** Parry

## Jam Link

https://itch.io/jam/goedware-game-jam-boss-battle-edition
