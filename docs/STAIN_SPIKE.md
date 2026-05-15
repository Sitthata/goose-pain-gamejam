# Spike: Stain System

## Overview

The stain system is the core feedback loop of GooseJanitor. It connects enemy behavior, player cleaning, and the filth gauge into one unified system.

**Architecture:** Autoload singleton — `StainSystem.gd`
Any node calls `StainSystem.add_stain()`, `StainSystem.remove_stain()`, or `StainSystem.get_filth_percent()` directly.

---

## Filth Gauge Formula

```
filth_percent = active_stains / MAX_STAINS * 100
```

- `MAX_STAINS` is a constant (start at 10, tune after playtesting)
- Filth % feeds directly into enemy AI difficulty scaling
- Filth % is the health system — no separate HP bar

---

## Stain Spawning

### Triggers
Bacteria spawn stains via explicit actions — not passive movement:
- Projectile lands on floor → stain spawns at impact point
- Vomit attack hits a surface → stain spawns at contact point
- Bacteria body contacts floor or wall → stain spawns at contact point

### Surface Filtering
Stains only spawn on valid surfaces. Use **Godot collision layers** to mark stainable surfaces (e.g. floor = layer 2, wall = layer 3, ceiling = not stainable).

The spawning code checks the surface's collision layer before placing a stain.

### Overlap Prevention
- Stains have a fixed size
- A new stain cannot spawn if an existing stain occupies that position
- If `active_stains >= MAX_STAINS`, spawning is blocked entirely

---

## Stain Node Structure

Each stain is a scene instance with:

```
Stain (Area2D)
├── Sprite2D          # Static green puddle texture
├── CollisionShape2D  # Matches puddle size (CircleShape or RectangleShape)
└── CleaningProgress  # float 0.0–1.0, internal value only
```

The `Stain` scene registers itself with `StainSystem` on `_ready()` and deregisters on cleanup.

---

## Cleaning Mechanic

### Input Flow
1. Player walks onto a stain (`Area2D` overlap detected)
2. Player **holds E** → enters cleaning stance
   - Movement locked (cannot move left or right)
   - Cleaning gauge appears above stain
3. Player **alternates A and D** rapidly → gauge fills
4. Gauge reaches 1.0 → stain is removed, `StainSystem` updates count

### Rules
- Progress is **per stain** — each stain tracks its own gauge
- If the **Clean Phase timer expires** mid-clean → gauge resets to 0, stain remains at full size
- Player can cancel by releasing E (gauge resets)

### Input Detection (GDScript pattern)
Track last key pressed to detect alternation:
```gdscript
var _last_mop_key: String = ""

func _input(event):
    if not _cleaning_stance:
        return
    if event.is_action_pressed("move_left") and _last_mop_key != "left":
        _last_mop_key = "left"
        _advance_clean_gauge()
    elif event.is_action_pressed("move_right") and _last_mop_key != "right":
        _last_mop_key = "right"
        _advance_clean_gauge()
```
This prevents spamming one key — player must genuinely alternate.

---

## StainSystem Autoload — Responsibilities

```gdscript
# scripts/autoload/StainSystem.gd

const MAX_STAINS = 10

var active_stains: Array = []

func get_filth_percent() -> float:
    return float(active_stains.size()) / MAX_STAINS * 100.0

func can_spawn_stain(position: Vector2) -> bool:
    # Returns false if at cap or position is occupied
    pass

func register_stain(stain: Node) -> void:
    active_stains.append(stain)

func unregister_stain(stain: Node) -> void:
    active_stains.erase(stain)
```

---

## Scene Setup Guide (Editor)

> Claude writes scripts. You wire up scenes in the editor.

### StainSystem (Autoload)
1. Create `scripts/autoload/StainSystem.gd`
2. Project Settings → Autoload → add `StainSystem.gd` with name `StainSystem`

### Stain Scene
1. Create new scene: root node = `Area2D`, name it `Stain`
2. Add child: `Sprite2D` — assign green puddle texture
3. Add child: `CollisionShape2D` — match to sprite size
4. Save as `scenes/ui/stain.tscn` *(or a dedicated `scenes/systems/` folder)*
5. Attach `stain.gd` script to root `Area2D`

### Stainable Surfaces
1. Select floor `TileMap` (or `StaticBody2D`) in editor
2. In Inspector → Collision → Layer → enable layer 2 (name it "stainable" in Project Settings)
3. Stain spawner checks this layer before placing a stain

---

## Open Questions / Future Changes

| Topic | Status |
|---|---|
| `MAX_STAINS` value | Start at 10 — tune after playtesting |
| Stain size | TBD — decide after first sprite is in engine |
| Stain visual (puddle texture) | TBD — placeholder circle acceptable for prototype |
| Stains grow over time | Could Have (post-jam) |
| Stains merge when adjacent | Could Have (post-jam) |
| Partial clean progress saved across phases | Could Have (post-jam) |
| Stain spawn on walls | Decided: yes, via collision layer |
| Stain spawn on ceiling | Decided: no |
