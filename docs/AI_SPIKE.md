# Spike: Enemy AI System

> ⚠️ Feasibility + implementation guide only. Not a final spec.
> Core combat system is TBD — this doc captures approach and structure.

---

## Overview

All bacteria enemies share one AI script (`bacteria_ai.gd`) with `@export` variables tuned per scene in the Godot Inspector. Difficulty scales via two axes:

1. **Stain %** — live filth gauge drives dodge probability
2. **Tier** — separate scene per evolution with higher base stats + new moves

---

## Architecture: Enum-Based FSM

```gdscript
enum State { IDLE, CHASE, ATTACK, DODGE, LUNGE }
var current_state: State = State.IDLE
```

Each state has `_enter_state()`, `_update_state()`, `_exit_state()`. Filth % modifies transition thresholds, not the states themselves.

### State Flow

```
IDLE
  ↓ player detected
CHASE ──────────────────────────────────────────┐
  ↓ player in attack range                      │
ATTACK                                          │
  ↓ projectile fired (spawns stain on landing)  │
  ↓ back to CHASE                               │
                                                │
  ↓ player telegraphs attack                    │
DODGE (dash backward)                           │
  ↓ dodge complete → back to CHASE ─────────────┘

  ↓ lunge cooldown expires + raycast clear (tier 2 only)
LUNGE (dash to player, leave 1–2 stain trail)
  ↓ lunge complete → back to CHASE
```

---

## Exported Stats (Tunable in Inspector)

```gdscript
# bacteria_ai.gd
@export var move_speed: float = 80.0
@export var projectile_rate: float = 3.0       # seconds between shots
@export var dodge_chance_base: float = 0.0     # 0.0 = never, 1.0 = always
@export var lunge_cooldown: float = 0.0        # 0 = lunge disabled (tier 1)
@export var lunge_stain_count: int = 0
```

### Placeholder Values (tune after playtesting)

| Stat | Tier 1 | Tier 2 |
|---|---|---|
| `move_speed` | 80 | 120 |
| `projectile_rate` | 3s | 2s |
| `dodge_chance_base` | 0% | 40% |
| `lunge_cooldown` | 0 (disabled) | 8s |
| `lunge_stain_count` | 0 | 1–2 |

Set these in the Godot Inspector per scene — no hardcoded values in script.

---

## Stain % Dodge Scaling

Dodge chance scales live with room filth:

```gdscript
func _get_dodge_chance() -> float:
    var filth = StainSystem.get_filth_percent() / 100.0
    return dodge_chance_base + (filth * (1.0 - dodge_chance_base))
```

- Tier 1 at any filth: always 0% (dodge_chance_base = 0)
- Tier 2 at 0% filth: 40% dodge
- Tier 2 at 100% filth: 100% dodge

---

## Dodge — Signal-Based Reaction

Player broadcasts a telegraph signal when winding up an attack. AI listens and rolls against dodge chance.

```gdscript
# player.gd
signal attack_telegraphed(attack_type: String, origin: Vector2)

func _start_charge():
    attack_telegraphed.emit("charge", global_position)
```

```gdscript
# bacteria_ai.gd
func _ready():
    var player = get_tree().get_first_node_in_group("player")
    player.attack_telegraphed.connect(_on_attack_telegraphed)

func _on_attack_telegraphed(attack_type: String, origin: Vector2):
    if current_state in [DODGE, LUNGE]:
        return  # already reacting
    if randf() < _get_dodge_chance():
        _dodge_direction = signf(global_position.x - origin.x)  # away from attack
        _enter_state(State.DODGE)
```

Dodge is a velocity burst away from attack origin:

```gdscript
func _update_dodge(delta):
    velocity.x = _dodge_direction * move_speed * 2.5
    _dodge_timer -= delta
    if _dodge_timer <= 0:
        _enter_state(State.CHASE)
```

---

## Lunge (Tier 2 Only) — ⚠️ TBD, NOT FINAL

> This moveset is a placeholder. Final move TBD after prototype feedback.

### Trigger
```gdscript
# in _process or _update_chase
_lunge_timer -= delta
if _lunge_timer <= 0 and _raycast_clear():
    _enter_state(State.LUNGE)
    _lunge_timer = lunge_cooldown
```

### Raycast Check
```gdscript
func _raycast_clear() -> bool:
    var space = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(
        global_position,
        player.global_position
    )
    query.exclude = [self]
    var result = space.intersect_ray(query)
    return result.is_empty() or result.collider == player
```

### Lunge Behavior
- High-speed dash toward player position at lunge start
- Stops on contact with player or wall
- Drops 1–2 stains along the path via `StainSystem.try_spawn_stain()`
- Returns to `CHASE` after contact or wall hit

---

## Projectile — Stain on Landing

```gdscript
# bacteria_projectile.gd
func _on_body_entered(body):
    if body.is_in_group("stainable"):
        StainSystem.try_spawn_stain(global_position)
    queue_free()
```

Projectile is a separate scene. Bacteria instantiates it in `ATTACK` state.

---

## Scene Setup Guide (Editor)

> Claude writes scripts. You wire up scenes in the editor.

### Bacteria Base Scene
1. Root: `CharacterBody2D` named `BacteriaBase`
2. Children: `Sprite2D`, `CollisionShape2D`, `AnimationPlayer`
3. Add `RayCast2D` node (for lunge path check) — point toward player direction
4. Add `Timer` node named `ProjectileTimer`
5. Attach `bacteria_ai.gd` to root
6. In Inspector — set exported stats for tier 1 values
7. Save as `scenes/boss/bacteria_base.tscn`

### Bacteria Tier 2 Scene
1. Duplicate `bacteria_base.tscn` → save as `bacteria_tier2.tscn`
2. In Inspector — update exported stats to tier 2 values
3. Assign tier 2 sprite
4. No script changes needed — same `bacteria_ai.gd`

---

## What Stain % Changes Per Tier

| Filth % | Tier 1 | Tier 2 |
|---|---|---|
| 0–33% | Chases + shoots | Chases + shoots |
| 34–66% | Slightly faster dodge roll | Dodges ~60%, lunge active |
| 67–100% | Dodge still 0% (base) | Near-guaranteed dodge, aggressive lunge |

---

## Post-Jam / Could Have

| Idea | Notes |
|---|---|
| Attack memory (weighted lookup) | Track which player attacks killed bacteria, increase dodge priority for those. Requires defined attack types first. |
| Tier 3+ scenes | Add new `@export` move flag per tier |
| Jump dodge | Replace dash with jump when aerial movement added |
| Flying bacteria tier | Entirely new movement system — separate spike needed |
